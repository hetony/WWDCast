//
//  SessionsSearchWireframeImpl.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 04/07/16.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import UIKit

final class ViewControllerFactory {

    fileprivate let googleCastService = GoogleCastService(applicationID: WWDCastEnvironment.googleCastAppID)

    fileprivate lazy var sessionsDataSource: AnyDataSource<Session> = {

        guard let reachability = ReachabilityService() else {
            fatalError("Failed to create reachability service!")
        }
        let network = NetworkService()

        let coreDataController = CoreDataController(name: "WWDCast")
        let cacheDataSource: AnyDataSource<Session> = AnyDataSource(dataSource: CoreDataSource<SessionManagedObject>(coreDataController: coreDataController))
        let networkDataSource: AnyDataSource<Session> = AnyDataSource(dataSource: NetworkDataSource(network: network, reachability: reachability))
        return AnyDataSource(dataSource: CompositeDataSource(networkDataSource: networkDataSource, coreDataSource: cacheDataSource))
    }()

    fileprivate lazy var useCaseProvider: UseCaseProvider = {
        return UseCaseProvider(googleCastService: self.googleCastService, sessionsDataSource: self.sessionsDataSource)
    }()

}

extension ViewControllerFactory: ApplicationFlowCoordinatorDependencyProvider {

    func tabBarController() -> UITabBarController {
        let tabbarController = TabBarController()
        tabbarController.tabBar.tintColor = UIColor.black
        return tabbarController
    }

}

extension ViewControllerFactory: SearchFlowCoordinatorDependencyProvider {

    func sessionsSearchController(delegate: SessionsSearchViewModelDelegate, previewProvider: TableViewControllerPreviewProvider) -> UIViewController {
        let useCase = self.useCaseProvider.sessionsSearchUseCase
        let viewModel = SessionsSearchViewModel(useCase: useCase, delegate: delegate)
        let view = SessionsSearchViewController(viewModel: viewModel)
        view.previewProvider = previewProvider
        return view
    }

    func sessionDetailsController(_ sessionId: String) -> UIViewController {
        let useCase = self.useCaseProvider.sessionDetailsUseCase
        let viewModel = SessionDetailsViewModel(sessionId: sessionId, useCase: useCase)
        return SessionDetailsViewController(viewModel: viewModel)
    }

    func filterController(_ filter: Filter, completion: @escaping FilterViewModelCompletion) -> UIViewController {
        let viewModel = FilterViewModel(filter: filter, completion: completion)
        let view = FilterViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: view)
        navigationController.navigationBar.tintColor = UIColor.black
        return navigationController
    }

}

extension ViewControllerFactory: FavoritesFlowCoordinatorDependencyProvider {

    func favoriteSessionsController(delegate: FavoriteSessionsViewModelDelegate, previewProvider: TableViewControllerPreviewProvider) -> UIViewController {
        let useCase = self.useCaseProvider.favoriteSessionsUseCase
        let viewModel = FavoriteSessionsViewModel(useCase: useCase, delegate: delegate)
        let view =  FavoriteSessionsViewController(viewModel: viewModel)
        view.previewProvider = previewProvider
        return view
    }

}
