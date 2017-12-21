//
//  SessionsSearchWireframeImpl.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 04/07/16.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import UIKit

final class ApplicationComponentsFactory {

    fileprivate let googleCastService = GoogleCastService(applicationID: Environment.googleCastAppID)

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

extension ApplicationComponentsFactory: ApplicationFlowCoordinatorDependencyProvider {

    func tabBarController() -> UITabBarController {
        return TabBarController()
    }

}

extension ApplicationComponentsFactory: SearchFlowCoordinatorDependencyProvider {

    func sessionsSearchController(delegate: SessionsSearchViewModelDelegate, previewProvider: TableViewControllerPreviewProvider) -> UIViewController {
        let useCase = self.useCaseProvider.sessionsSearchUseCase
        let viewModel = SessionsSearchViewModel(useCase: useCase, delegate: delegate)
        let view = SessionsSearchViewController(viewModel: viewModel)
//        view.previewProvider = previewProvider
        return view
    }

    func sessionDetailsController(_ sessionId: String) -> UIViewController {
        let useCase = self.useCaseProvider.sessionDetailsUseCase(sessionId: sessionId)
        let viewModel = SessionDetailsViewModel(useCase: useCase)
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

extension ApplicationComponentsFactory: FavoritesFlowCoordinatorDependencyProvider {

    func favoriteSessionsController(navigator: FavoriteSessionsNavigator, previewProvider: TableViewControllerPreviewProvider) -> UIViewController {
        let useCase = self.useCaseProvider.favoriteSessionsUseCase
        let viewModel = FavoriteSessionsViewModel(useCase: useCase, navigator: navigator)
        let view =  FavoriteSessionsViewController(viewModel: viewModel)
        view.previewProvider = previewProvider
        return view
    }

}
