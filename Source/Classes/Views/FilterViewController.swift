//
//  FilterViewController.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 13/08/2016.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class FilterViewController: TableViewController<FilterSectionViewModel, FilterTableViewCell> {
    let viewModel: FilterViewModel
    
    init(viewModel: FilterViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUI()
        self.setupBindings()
    }
    
    // MARK - Private
    
    private func setupBindings() {
        // ViewModel's input
        self.navigationItem.leftBarButtonItem!.rx_tap.map({ true }).subscribeNext(self.viewModel.dismissObserver).addDisposableTo(self.disposeBag)
        self.navigationItem.rightBarButtonItem!.rx_tap.map({ false }).subscribeNext(self.viewModel.dismissObserver).addDisposableTo(self.disposeBag)
        self.tableView.rx_itemSelected.subscribeNext({ indexPath in
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }).addDisposableTo(self.disposeBag)
        
        // ViewModel's output
        self.viewModel.filterSections.drive(self.tableView.rx_itemsWithDataSource(self.source)).addDisposableTo(self.disposeBag)
        self.viewModel.title.drive(self.rx_title).addDisposableTo(self.disposeBag)
    }

    private func configureUI() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.castBarButtonItem()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: nil, action: nil)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: nil, action: nil)
        
        self.clearsSelectionOnViewWillAppear = true
        self.tableView.rowHeight = 44
        self.tableView.delegate = nil
        self.tableView.dataSource = nil
        self.tableView.layoutMargins = UIEdgeInsetsZero
        self.tableView.tableFooterView = UIView()
    }
    
}
