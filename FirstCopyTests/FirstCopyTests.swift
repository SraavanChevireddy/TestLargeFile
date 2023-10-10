//
//  FirstCopyTests.swift
//  FirstCopyTests
//
//  Created by Sraavan Chevireddy on 11/10/23.
//

import XCTest
import CoreData

class DataManagerTests: XCTestCase {
    var dataManager: DataManager!
    var managedObjectContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create an in-memory Core Data stack for testing
        let container = NSPersistentContainer(name: "TestModel")
        container.loadPersistentStores { description, error in
            XCTAssertNil(error)
        }
        managedObjectContext = container.viewContext

        // Initialize DataManager with the test Core Data context
        dataManager = DataManager(context: managedObjectContext)
    }

    override func tearDownWithError() throws {
        dataManager = nil
        managedObjectContext = nil

        try super.tearDownWithError()
    }

    // Test the initialization of the DataManager
    func testDataManagerInitialization() {
        XCTAssertNotNil(dataManager)
    }

    // Test the prepare method
    func testPrepareMethod() {
        let batchData = ["1,A,10.0,5.0,Red,Large", "2,B,15.0,7.5,Blue,Medium"]
        let expectation = XCTestExpectation(description: "prepare method expectation")

        dataManager.prepare(with: batchData) { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.dataManager.batches.count, 2)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // Test inserting a batch of products
    func testInsertBatch() {
        let batchData = ["1,A,10.0,5.0,Red,Large", "2,B,15.0,7.5,Blue,Medium"]
        let expectation = XCTestExpectation(description: "insert batch expectation")

        dataManager.prepare(with: batchData) { _ in
            let batchRequest = self.dataManager.insertChunked(products: self.dataManager.batches[0])
            XCTAssertNoThrow(try self.dataManager.insert(batch: batchRequest))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        // Fetch and verify the inserted objects
        let fetchRequest: NSFetchRequest<ProductInfo> = ProductInfo.fetchRequest()
        let products = try? managedObjectContext.fetch(fetchRequest)
        XCTAssertEqual(products?.count, 2)
    }

    // Test inserting a batch with invalid data
    func testInsertBatchWithInvalidData() {
        let batchData = ["1,A,10.0,5.0,Red,Large", "invalid data"]
        let expectation = XCTestExpectation(description: "insert batch with invalid data expectation")

        dataManager.prepare(with: batchData) { _ in
            let batchRequest = self.dataManager.insertChunked(products: self.dataManager.batches[0])
            XCTAssertThrowsError(try self.dataManager.insert(batch: batchRequest))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        // Verify that no objects were inserted due to invalid data
        let fetchRequest: NSFetchRequest<ProductInfo> = ProductInfo.fetchRequest()
        let products = try? managedObjectContext.fetch(fetchRequest)
        XCTAssertEqual(products?.count, 0)
    }

    // Test inserting a batch with missing context
    func testInsertBatchWithMissingContext() {
        let batchData = ["1,A,10.0,5.0,Red,Large"]
        let expectation = XCTestExpectation(description: "insert batch with missing context expectation")

        // Set the context to nil to simulate a missing context
        dataManager = DataManager(context: nil)

        dataManager.prepare(with: batchData) { _ in
            let batchRequest = self.dataManager.insertChunked(products: self.dataManager.batches[0])
            XCTAssertThrowsError(try self.dataManager.insert(batch: batchRequest))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        // Verify that no objects were inserted due to missing context
        let fetchRequest: NSFetchRequest<ProductInfo> = ProductInfo.fetchRequest()
        let products = try? managedObjectContext.fetch(fetchRequest)
        XCTAssertEqual(products?.count, 0)
    }
}


