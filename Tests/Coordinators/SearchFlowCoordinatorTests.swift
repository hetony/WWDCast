//
//  WWDCastTests.swift
//  WWDCastTests
//
//  Created by Maksym Shcheglov on 04/07/16.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import XCTest
@testable import WWDCast

class SearchFlowCoordinatorTests: XCTestCase {

    private let sessionId = "mock_session_id"
    private var flowCoordinator: SearchFlowCoordinator!
    private var rootViewController: UINavigationController!
    private var dependencyProvider: MockViewControllerFactory!

    override func setUp() {
        super.setUp()
        self.rootViewController = UINavigationController()
        self.dependencyProvider = MockViewControllerFactory()
        self.flowCoordinator = SearchFlowCoordinator(rootController: self.rootViewController, dependencyProvider: self.dependencyProvider)
        UIApplication.shared.delegate!.window??.rootViewController = self.rootViewController
    }

    /// Tests the flow from search to session details screen
    func testSearchDetailsFlow() {
        // GIVEN
        self.dependencyProvider.searchHandler = { _ in
            return UIViewController()
        }
        self.dependencyProvider.detailsHandler = { sessionId in
            XCTAssertEqual(self.sessionId, sessionId)
            return UIViewController()
        }

        // WHEN
        self.flowCoordinator.start()
        self.flowCoordinator.sessionsSearchViewModel(MockSessionsSearchViewModel(), wantsToShowSessionDetailsWith: self.sessionId)

        // THEN
        let predicate = NSPredicate(format: "viewControllers.@count == 2")
        expectation(for: predicate, evaluatedWith: self.rootViewController, handler: nil)
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    /// Tests the flow from search to session filter screen
    func testFilterFlow() {
        // GIVEN
        self.dependencyProvider.searchHandler = { _ in
            return UIViewController()
        }
        self.dependencyProvider.filterHandler = { _ in
            return UIViewController()
        }

        // WHEN
        self.flowCoordinator.start()
        self.flowCoordinator.sessionsSearchViewModel(MockSessionsSearchViewModel(), wantsToShow: Filter(), completion: { _ in })

        // THEN
        let predicate = NSPredicate(format: "viewControllers.@count == 1 && presentedViewController != nil")
        expectation(for: predicate, evaluatedWith: self.rootViewController, handler: nil)
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    /// Tests the flow from search to session filter screen and back (new filter object)
    func testFilterFlowFinished() {
        // GIVEN
        var filterCompletion: FilterViewModelCompletion!
        self.dependencyProvider.searchHandler = { _ in
            return UIViewController()
        }
        self.dependencyProvider.filterHandler = { _, completion in
            filterCompletion = completion
            return UIViewController()
        }

        // WHEN
        self.flowCoordinator.start()
        self.flowCoordinator.sessionsSearchViewModel(MockSessionsSearchViewModel(), wantsToShow: Filter(), completion: { _ in })
        filterCompletion(.finished(Filter()))

        // THEN

        let showPredicate = NSPredicate(format: "viewControllers.@count == 1 && presentedViewController != nil")
        expectation(for: showPredicate, evaluatedWith: self.rootViewController, handler: nil)
        let hidePredicate = NSPredicate(format: "viewControllers.@count == 1 && presentedViewController == nil")
        expectation(for: hidePredicate, evaluatedWith: self.rootViewController, handler: nil)
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    /// Tests the flow from search to session filter screen and back (cancel)
    func testFilterFlowCancelled() {
        // GIVEN
        var filterCompletion: FilterViewModelCompletion!
        self.dependencyProvider.searchHandler = { _ in
            return UIViewController()
        }
        self.dependencyProvider.filterHandler = { _, completion in
            filterCompletion = completion
            return UIViewController()
        }

        // WHEN
        self.flowCoordinator.start()
        self.flowCoordinator.sessionsSearchViewModel(MockSessionsSearchViewModel(), wantsToShow: Filter(), completion: { _ in })
        filterCompletion(.cancelled)

        // THEN
        let showPredicate = NSPredicate(format: "viewControllers.@count == 1 && presentedViewController != nil")
        expectation(for: showPredicate, evaluatedWith: self.rootViewController, handler: nil)
        let hidePredicate = NSPredicate(format: "viewControllers.@count == 1 && presentedViewController == nil")
        expectation(for: hidePredicate, evaluatedWith: self.rootViewController, handler: nil)
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    private func wait(for timeInterval: TimeInterval) {
        let expectFinish = expectation(description: "finish")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval, execute: {
            expectFinish.fulfill()
        })
        waitForExpectations(timeout: timeInterval, handler: nil)
    }

}
