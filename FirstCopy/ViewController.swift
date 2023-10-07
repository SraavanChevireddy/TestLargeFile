//
//  ViewController.swift
//  FirstCopy
//
//  Created by Sraavan Chevireddy on 06/10/23.
//

import UIKit
import CoreData

class ViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    enum Section {
        case main
    }
    
    let batchSize = 100
    var fetchedResultsController: NSFetchedResultsController<ProductInfo>!
    var diffableDataSource: UITableViewDiffableDataSource<Section, ProductInfo>!
    
    var predictSpringViewModel: PredictFileManager = .init()
    private let delegate = UIApplication.shared.delegate as? AppDelegate
    
    var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = view.center
                
        configureFetchedResultsController()
        configureDiffableDataSource()
        fetchData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
//        predictSpringViewModel.input.send("prod1M")
    }
    
    private func configureFetchedResultsController() {
        guard let context = delegate?.persistentContainer.viewContext else {
            return
        }
        let fetchRequest: NSFetchRequest<ProductInfo> = ProductInfo.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.fetchBatchSize = batchSize
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error performing fetch: \(error)")
        }
    }
    
    private func configureDiffableDataSource() {
        diffableDataSource = UITableViewDiffableDataSource<Section, ProductInfo>(
            tableView: tableView,
            cellProvider: { tableView, indexPath, productInfo in
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                cell.textLabel?.text = productInfo.title ?? ""
                cell.detailTextLabel?.text = "SALE Price: \(productInfo.salePrice)"
                return cell
            }
        )
    }
    
    private func fetchData() {
        try? fetchedResultsController.performFetch()
        var snapshot = NSDiffableDataSourceSnapshot<Section, ProductInfo>()
        snapshot.appendSections([.main])
        snapshot.appendItems(fetchedResultsController.fetchedObjects ?? [])
        diffableDataSource.apply(snapshot, animatingDifferences: false)
        activityIndicator.stopAnimating()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return diffableDataSource.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return diffableDataSource.tableView(tableView, cellForRowAt: indexPath)
    }
}

