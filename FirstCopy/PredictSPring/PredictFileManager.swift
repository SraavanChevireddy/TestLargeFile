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
import SwiftUI

class PredictFileManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    
    var input = PassthroughSubject<String, Never>()
    var onReceiveProgress =  PassthroughSubject<Float, Never>()
    var onDownLoadFinished = PassthroughSubject<URL, Never>()

    @Published var filePath: URL?
    
    @Published private(set) var fileContents: [String] = []
    @Published private(set) var downloadProgress: Double = 0.0
    
    private var fileManager: URL?
        
    private let delegate = UIApplication.shared.delegate as? AppDelegate
    private var manager: DataManager?
    private var disposables: Set<AnyCancellable> = .init()
    
    var progress: (() -> ())?
    
    override init() {
        super.init()

        addSubscriptions()
    }
    
    private func addSubscriptions() {
        let context = delegate?.persistentContainer.viewContext
        manager = DataManager(context: context)
        
        fileManager = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: .documentsDirectory, create: true)
           
        input
            .subscribe(on: DispatchQueue(label: "ParseQueue", qos: .background))
            .map({$0})
            .sink { [weak self] in
                guard let self = self, let fileManager = fileManager else {
                    debugPrint("Unable to locate the File Manager")
                    return
                }
                let file = fileManager.appending(path: "predict_spring.csv")
                self.downloadFile(fileID: $0, destinationURL: file)
            }.store(in: &disposables)
        
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
    
    func downloadFile(fileID: String, destinationURL: URL)  {
        let url = URL(string: "https://drive.google.com/uc?export=download&id=\(fileID)")!
        let downloadQueue = OperationQueue()
        downloadQueue.qualityOfService = .utility
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.urlCache = nil
        
        let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: downloadQueue)
        let task = session.downloadTask(with: url)
        task.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let filePath = filePath, FileManager.default.fileExists(atPath: filePath.absoluteString) {
            try? FileManager.default.removeItem(at: filePath)
        }
        onDownLoadFinished.send(location)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let downloadPr = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        onReceiveProgress.send(downloadPr)
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


