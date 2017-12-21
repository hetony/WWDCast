//
//  UITableViewController+Utils.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 05/07/16.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources

/// Implement the methods of this protocol to respond, with a preview view controller
/// to the user pressing a view object on the screen of a device that supports 3D Touch.
protocol TableViewControllerPreviewProvider: class {

    /// Creates and returns preview controller for specified item
    ///
    /// - parameter item: the pressed item
    /// - returns: newly created preview controller
    func previewController<Item>(forItem item: Item) -> UIViewController?
}

class TableViewController<SectionViewModel: SectionModelType & CustomStringConvertible, Cell: UITableViewCell>:
    UIViewController where
    Cell: BindableView & NibProvidable & ReusableView, Cell.ViewModel == SectionViewModel.Item {

    var tableView: UITableView!
    let disposeBag = DisposeBag()

    lazy var source: RxTableViewSectionedReloadDataSource<SectionViewModel> = {
        let dataSource = RxTableViewSectionedReloadDataSource<SectionViewModel>()
        dataSource.configureCell = { (dataSource, tableView, indexPath, element) in
            let cell = tableView.dequeueReusableCell(withClass: Cell.self, forIndexPath: indexPath)
            cell.bind(to: element)
            return cell
        }
        dataSource.titleForHeaderInSection = { (dataSource: TableViewSectionedDataSource<SectionViewModel>, sectionIndex: Int) -> String? in
            return dataSource[sectionIndex].description
        }
        return dataSource
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView = UITableView(frame: self.view.bounds, style: .plain)
        self.view.addSubview(self.tableView, constraints: [
            equal(\.leadingAnchor),
            equal(\.trailingAnchor),
            equal(\.topAnchor),
            equal(\.bottomAnchor)
        ])
        self.tableView.registerNib(cellClass: Cell.self)

        // Get rid of back button's title
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    func setClearsSelectionOnViewWillAppear() {
        self.tableView.rx.itemSelected.asDriver().drive(onNext: {[unowned self] indexPath in
            self.tableView.deselectRow(at: indexPath, animated: true)
        }).addDisposableTo(self.disposeBag)
    }

//    func registerForPreviewing() {
//        // Check for force touch feature, and add force touch/previewing capability.
//        if self.traitCollection.forceTouchCapability != .available {
//            return
//        }
//        // Register for `UIViewControllerPreviewingDelegate` to enable "Peek" and "Pop".
//        self.registerForPreviewing(with: self, sourceView: self.tableView)
//
////        var previewItem: SectionViewModel.Item?
////        let viewControllerForLocation = self.rx.sentMessage(#selector(UIViewControllerPreviewingDelegate.previewingContext(_:viewControllerForLocation:))).asDriverOnErrorJustComplete()
////        let viewControllerToCommit = self.rx.sentMessage(#selector(UIViewControllerPreviewingDelegate.previewingContext(_:commit:))).asDriverOnErrorJustComplete()
////
////        viewControllerForLocation.drive(previewingControllerBinding).addDisposableTo(self.disposeBag)
////    }
////
////    var previewingControllerBinding: UIBindingObserver<UIViewController, SessionItemViewModel> {
////        return UIBindingObserver(UIElement: self, binding: { (vc, viewModel) in
////
////        })
//    }

    // MARK: UIViewControllerPreviewingDelegate

//    weak var previewProvider: TableViewControllerPreviewProvider?
//    var commitPreview: Observable<SectionViewModel.Item> {
//        return _commitPreview.asObservable()
//    }
//    private var previewItem: SectionViewModel.Item?
//    private let _commitPreview = PublishSubject<SectionViewModel.Item>()
//
//    /// Create a previewing view controller to be shown at "Peek".
//    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
//        // Obtain the index path and the cell that was pressed.
//        guard let indexPath = self.tableView.indexPathForRow(at: location),
//            let cell = self.tableView.cellForRow(at: indexPath),
//            let viewModel = try? self.source.model(at: indexPath),
//            let previewItem = viewModel as? SectionViewModel.Item else {
//                return nil
//        }
//        // Set the source rect to the cell frame, so surrounding elements are blurred.
//        previewingContext.sourceRect = cell.frame
//
//        self.previewItem = previewItem
//        // Create a detail view controller and set its properties.
//        return self.previewProvider?.previewController(forItem: previewItem)
//    }
//
//    /// Present the view controller for the "Pop" action.
//    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
//        guard let previewItem = self.previewItem else {
//            return
//        }
//        self._commitPreview.onNext(previewItem)
//    }

}

class SessionDetailsPreview: NSObject {
    var commitPreview: Observable<IndexPath> {
        return _commitPreview.asObservable()
    }
    typealias DataSource = (IndexPath) -> UIViewController?
    fileprivate let source: DataSource
    fileprivate let _commitPreview = PublishSubject<IndexPath>()
    fileprivate var previewItem: IndexPath?

    init(source: @escaping DataSource) {
        self.source = source
    }
}

extension SessionDetailsPreview: UIViewControllerPreviewingDelegate {

    /// Create a previewing view controller to be shown at "Peek".
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // Obtain the index path and the cell that was pressed.
        guard let tableView = previewingContext.sourceView as? UITableView,
            let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath),
            let previewController = self.source(indexPath) else {
                return nil
        }
        // Set the source rect to the cell frame, so surrounding elements are blurred.
        previewingContext.sourceRect = cell.frame

        self.previewItem = indexPath
        // Create a detail view controller and set its properties.
        return previewController
    }

    /// Present the view controller for the "Pop" action.
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let previewItem = self.previewItem else {
            return
        }
        self._commitPreview.onNext(previewItem)
    }
}
