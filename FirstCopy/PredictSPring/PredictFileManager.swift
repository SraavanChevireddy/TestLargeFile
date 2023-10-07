//
//  PredictFileManager.swift
//  FirstCopy
//
//  Created by Sraavan Chevireddy on 06/10/23.
//

import Combine
import Foundation
import CoreData
import UIKit

class PredictFileManager: ObservableObject {
    
    var input = PassthroughSubject<String, Never>()
    
    @Published private(set) var filePath: URL?
    @Published private(set) var fileContents: [String] = []
        
    private let delegate = UIApplication.shared.delegate as? AppDelegate
    private var manager: DataManager?
    private var disposables: Set<AnyCancellable> = .init()
    
    init() {
        let context = delegate?.persistentContainer.viewContext
        manager = DataManager(context: context)
        
        input
            .subscribe(on: DispatchQueue(label: "ParseQueue", qos: .background))
            .map({$0})
            .map { Bundle.main.url(forResource: $0, withExtension: "csv") }
            .replaceError(with: nil)
            .assign(to: \.filePath, on: self)
            .store(in: &disposables)
        
        $filePath
            .subscribe(on: DispatchQueue(label: "ParseQueue", qos: .background))
            .compactMap({$0})
            .tryMap { try String(contentsOf: $0) }
            .map({$0.components(separatedBy: .newlines)})
            .map({Array($0.dropFirst())})
            .replaceError(with: [])
            .assign(to: \.fileContents, on: self)
            .store(in: &disposables)

        $fileContents
            .subscribe(on: DispatchQueue(label: "ReadContentsQueue", qos: .background))
            .map({$0})
            .sink { lines in
                Task {
                    await self.manager?.prepare(with: lines)
                }
            }.store(in: &disposables)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

actor DataManager {
    private var context: NSManagedObjectContext? = nil
    private(set) var batchSize: Int = 1000
    private(set) var batches: [String] = []
    
    init?(context: NSManagedObjectContext?) {
        self.context = context
    }
    
    func prepare(with: [String]) async {
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

