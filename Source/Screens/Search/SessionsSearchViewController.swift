//
//  ViewController.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 04/07/16.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class SessionsSearchViewController: TableViewController<SessionSectionViewModel, SessionTableViewCell> {

    private var loadingIndicator: UIActivityIndicatorView!
    private var filterButton: UIBarButtonItem!
    private let viewModel: SessionsSearchViewModelType
    private let sessions = Variable([SessionSectionViewModel]())

    init(viewModel: SessionsSearchViewModelType) {
        self.viewModel = viewModel
        super.init()
        self.rx.viewDidLoad.bind(onNext: self.configureUI).addDisposableTo(self.disposeBag)
        self.rx.viewDidLoad.flatMap(Observable.just(self.viewModel)).bind(onNext: self.bind).addDisposableTo(self.disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func commitPreview(for item: SessionItemViewModel) {
//        self.viewModel.didSelect(item: item)
    }

    // MARK: Private

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.tintColor = UIColor.black
        return searchController
    }()

    private var searchBar: UISearchBar {
        return self.searchController.searchBar
    }

    private func bind(to viewModel: SessionsSearchViewModelType) {
        // View intents
        let filterIntent = self.filterButton.rx.tap.asObservable().map({ SessionsSearchAction.filter })
        let searchIntent = self.searchQueryIntent.map({ SessionsSearchAction.search($0) })
        let itemSelectedIntent = self.tableView.rx.modelSelected(SessionItemViewModel.self).map({ SessionsSearchAction.select($0) })

        self.sessions.asDriver().drive(self.tableView.rx.items(dataSource: self.source)).addDisposableTo(self.disposeBag)
        Observable.of(filterIntent, searchIntent, itemSelectedIntent).merge().asDriver(onErrorJustReturn: SessionsSearchAction.filter)
            .flatMap(self.viewModel.transform) // update the state
            .drive(onNext: self.render) // visually represent state
            .addDisposableTo(self.disposeBag)

//        self.filterButton.rx.tap.bind(onNext: viewModel.didTapFilter).addDisposableTo(self.disposeBag)
//        self.searchQuery.drive(onNext: viewModel.didStartSearch).addDisposableTo(self.disposeBag)
//        self.tableView.rx.modelSelected(SessionItemViewModel.self)
//            .bind(onNext: viewModel.didSelect)
//            .addDisposableTo(self.disposeBag)

        // ViewModel's output

//        viewModel.sessionSections.drive(self.tableView.rx.items(dataSource: self.source)).addDisposableTo(self.disposeBag)
//        viewModel.isLoading.drive(self.tableView.rx.isHidden).addDisposableTo(self.disposeBag)
//        viewModel.isLoading.drive(self.loadingIndicator.rx.isAnimating).addDisposableTo(self.disposeBag)
    }

    private func render(_ state: SessionsSearchState) {
        switch state {
        case .loading:
            self.tableView.isHidden = true
            self.loadingIndicator.startAnimating()
        case .loaded(let sessions):
            self.tableView.isHidden = false
            self.loadingIndicator.stopAnimating()
            self.sessions.value = sessions
        case .error: break
            // nop
        }
    }

    private func configureUI() {
        self.definesPresentationContext = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.castBarButtonItem()
        self.filterButton = UIBarButtonItem(title: NSLocalizedString("Filter", comment: "Filter"), style: .plain, target: nil, action: nil)
        self.navigationItem.leftBarButtonItem = self.filterButton
        self.title = NSLocalizedString("WWDCast", comment: "Session search view title")

        self.setClearsSelectionOnViewWillAppear()
        self.registerForPreviewing()

        self.view.backgroundColor = UIColor.white

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 100
        if #available(iOS 11.0, *) {
            self.navigationItem.searchController = self.searchController
            self.searchController.isActive = true
        } else {
            self.tableView.tableHeaderView = self.searchBar
            // dismiss keyboard on scroll
            self.tableView.rx.contentOffset.asDriver().filter({[unowned self] _ -> Bool in
                return !self.searchController.isBeingPresented && self.searchBar.isFirstResponder
            }).drive(onNext: {[unowned self] _ in
                self.searchBar.resignFirstResponder()
            }).addDisposableTo(self.disposeBag)
        }

        self.tableView.tableFooterView = UIView()

        self.loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        self.view.addSubview(self.loadingIndicator)
        self.loadingIndicator.hidesWhenStopped = true
        self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.loadingIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        self.loadingIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
    }

    private var searchQueryIntent: Observable<String> {
        let cancel: Observable<String> = self.searchBar.rx.delegate.methodInvoked(#selector(UISearchBarDelegate.searchBarCancelButtonClicked(_:))).map({ _ in return "" })

        let searchBarTextObservable = self.searchBar.rx.text.rejectNil().unwrap()
        return Observable.of(searchBarTextObservable, cancel)
            .merge()
            .throttle(0.1, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
    }

}
