//
//  FirstCopyTests.swift
//  FirstCopyTests
//
//  Created by Sraavan Chevireddy on 11/10/23.
//

import XCTest
import CoreData
import SwiftUI
import Combine

@testable import FirstCopy

class PredictFileManagerTests: XCTestCase {
    
    var predictFileManager: PredictFileManager!
    var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
        super.setUp()
        predictFileManager = PredictFileManager()
    }
    
    override func tearDown() {
        predictFileManager = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    func testFileContentsUpdate() {
            let filePathSubject = CurrentValueSubject<URL?, Never>(URL(fileURLWithPath: "mockedFilePath"))
            
            predictFileManager.$filePath
                .subscribe(on: DispatchQueue(label: "ParseQueue", qos: .background))
                .compactMap({ $0 })
                .tryMap { try String(contentsOf: $0) }
                .map({ $0.components(separatedBy: .newlines) })
                .map({$0})
                .replaceError(with: [])
                .sink { lines in
                    self.predictFileManager?.fileContents = lines
                }
                .store(in: &cancellables)
        
        filePathSubject.send(URL(fileURLWithPath: "mockedFilePathWithData"))
            let expectation = XCTestExpectation(description: "FileContentsUpdated")
            DispatchQueue.global().async {
                XCTAssertEqual(self.predictFileManager.fileContents, [])
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
        }
    
}


