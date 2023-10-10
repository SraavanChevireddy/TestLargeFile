//
//  ViewController.swift
//  FirstCopy
//
//  Created by Sraavan Chevireddy on 06/10/23.
//

import UIKit
import CoreData
import Combine

class ViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    enum Section {
        case main
    }
    
    let batchSize = 100
    var fetchedResultsController: NSFetchedResultsController<ProductInfo>!
    var diffableDataSource: UITableViewDiffableDataSource<Section, ProductInfo>!
    private var disposables: Set<AnyCancellable> = Set()
    
    var predictSpringViewModel: PredictFileManager = .init()
    private let delegate = UIApplication.shared.delegate as? AppDelegate
    
    var activityIndicator: UIActivityIndicatorView!
    var progressIndicator: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator = {
            let modalIndicator = UIActivityIndicatorView(style: .medium)
            modalIndicator.hidesWhenStopped = true
            modalIndicator.isHidden = true
            modalIndicator.largeContentTitle = "Fetching Records"
            modalIndicator.center = view.center
            return modalIndicator
        }()
        
        progressIndicator = {
            let indicator = UIProgressView(progressViewStyle: .bar)
            indicator.largeContentTitle = "Downloading file"
            indicator.progressTintColor = .systemOrange
            indicator.center = view.center
            return indicator
        }()
        
        [activityIndicator, progressIndicator].forEach({view.addSubview($0)})
        
        tableView.register(CustomTableViewCell.self, forCellReuseIdentifier: "cell")
        addSubscriptions()
        configureDiffableDataSource()
                
        view.addSubview(activityIndicator)
    }
    
    private func addSubscriptions() {
        predictSpringViewModel.onReceiveProgress.sink { value in
            print("\(value)")
            DispatchQueue.main.async {
                self.progressIndicator.setProgress(value, animated: true)
            }
        }.store(in: &disposables)
        
        predictSpringViewModel.onDownLoadFinished.sink { [weak self] filePath in
            guard let self = self else {
                return
            }
            DispatchQueue.main.async {
                self.activityIndicator.startAnimating()
                self.activityIndicator.isHidden = false
                self.progressIndicator.isHidden = true
            }
            self.predictSpringViewModel.filePath = filePath
            self.configureFetchedResultsController()
            self.fetchData()
        }.store(in: &disposables)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        predictSpringViewModel.input.send("16jxfVYEM04175AMneRlT0EKtaDhhdrrv")
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
            cacheName: "predict_spring"
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
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? CustomTableViewCell
                cell?.model = productInfo
                return cell
            }
        )
    }
    
    private func fetchData() {
        debugPrint("Starting Fetch")
        try? fetchedResultsController.performFetch()
        var snapshot = NSDiffableDataSourceSnapshot<Section, ProductInfo>()
        snapshot.appendSections([.main])
        snapshot.appendItems(fetchedResultsController.fetchedObjects ?? [])
        diffableDataSource.apply(snapshot, animatingDifferences: false)
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
        debugPrint("Ending Fetch")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return diffableDataSource.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return diffableDataSource.tableView(tableView, cellForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}

