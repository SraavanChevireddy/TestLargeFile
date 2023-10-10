//
//  Dateformatter+Ext.swift
//  FirstCopy
//
//  Created by Sraavan Chevireddy on 08/10/23.
//

import Foundation
import CoreData

extension Date {
    var convert: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: self)
    }
}

actor DataManager {
    private var context: NSManagedObjectContext? = nil
    private(set) var batchSize: Int = 1000
    private(set) var batches: [String] = []
    private(set) var isLoading: Bool = false
    
    init?(context: NSManagedObjectContext?) {
        self.context = context
    }
    
    func prepare(with: [String]) async {
        defer {
            isLoading.toggle()
        }
        batches = with
        for eachBatch in batches.chunked(into: batchSize) {
            let filteredBatch = await insertChunked(products: eachBatch)
            try? await insert(batch: filteredBatch)
        }
    }
    
    func insertChunked(products: [String]) async -> NSBatchInsertRequest {
        var index = 0
        let batchInsert = NSBatchInsertRequest(entity: ProductInfo.entity()) { (managedContext: NSManagedObject) -> Bool in
            guard index < products.count else {
                return true
            }
            if let product = managedContext as? ProductInfo {
                let data = products[safe: index]?.components(separatedBy: ",") ?? []
                product.productId = data[safe: 0]
                product.title = data[safe: 1]
                product.listPrice = Double(data[safe: 2] ?? "") ?? 0.0
                product.salePrice = Double(data[safe: 3] ?? "") ?? 0.0
                product.color = data[safe: 4]
                product.size = data[safe: 5]
            }
            index += 1
            return false
        }
        return batchInsert
    }
    
    func insert(batch: NSBatchInsertRequest) async throws {
        guard context != nil else {
            throw NSError(domain: "Unable to find context", code: 22)
        }
        let result = try? context?.execute(batch)
        debugPrint("PREDICTSPRING: \(String(describing: result))")
        try? context?.save()
    }
}
