//
//  SessionsSearchWireframeImpl.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 04/07/16.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import UIKit
import GoogleCast

class WWDCastAssemblyImpl: WWDCastAssembly {
    
    lazy var router: WWDCastRouterImpl = {
        return WWDCastRouterImpl(moduleFactory: self)
    }()
    
    func sessionsSearchController() -> UIViewController {
        let serviceProvider = ServiceProviderImpl.defaultServiceProvider
        let view = SessionsSearchViewController()
        let presenter = SessionsSearchPresenterImpl(router: router)
        let interactor = SessionsSearchInteractorImpl(presenter: presenter, serviceProvider: serviceProvider)
        view.viewModel = presenter
        presenter.interactor = interactor
        let navigationController = UINavigationController(rootViewController: view)
        navigationController.navigationBar.tintColor = UIColor.blackColor()
        self.router.navigationController = navigationController

        let castContext = GCKCastContext.sharedInstance()
        let castContainerVC = castContext.createCastContainerControllerForViewController(navigationController)
        castContext.useDefaultExpandedMediaControls = true
        castContainerVC.miniMediaControlsItemEnabled = true

        return castContainerVC
    }
    
    func filterController(filter: Filter, completion: FilterViewModel.Completion) -> UIViewController {
        let view = FilterViewController()
        view.viewModel = FilterViewModel(filter: filter, completion: completion)
        let navigationController = UINavigationController(rootViewController: view)
        navigationController.navigationBar.tintColor = UIColor.blackColor()
        return navigationController
    }

    func sessionDetailsController(withId Id: String) -> UIViewController {
        let serviceProvider = ServiceProviderImpl.defaultServiceProvider
        let view = SessionDetailsViewController()
        let presenter = SessionDetailsPresenterImpl(view: view, router: self.router)
        let interactor = SessionDetailsInteractorImpl(presenter: presenter, serviceProvider: serviceProvider, sessionId: Id)
        view.presenter = presenter
        presenter.interactor = interactor
        return view
    }

}
