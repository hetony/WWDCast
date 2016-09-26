//
//  SessionsSearchViewModelImpl.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 04/07/16.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class SessionsSearchViewModelImpl: SessionsSearchViewModel {
    private let api: WWDCastAPI
    private let router: SessionsSearchRouter
    private var filter: Variable<Filter>
    private let _sessions: Variable<[Session]>
    private let disposeBag = DisposeBag()
    
    /// Underlying variable that we'll listen to for changes
    private var _active = Variable(false)
    
    /// Public «active» variable
    var active: Bool {
        get { return _active.value }
        set {
            // Skip KVO notifications when the property hasn't actually changed.
            if newValue == _active.value { return }
            
            _active.value = newValue
        }
    }
    
    /**
    Rx `Observable` for the `active` flag. (when it becomes `true`).

    Will send messages only to *new* & *different* values.
    */
    lazy var didBecomeActive: Observable<SessionsSearchViewModelImpl> = { [unowned self] in
        return self._active.asObservable()
            .filter { $0 == true }
            .map { _ in return self }
    }()

    /**
    Rx `Observable` for the `active` flag. (when it becomes `false`).

    Will send messages only to *new* & *different* values.
    */
    lazy var didBecomeInactive: Observable<SessionsSearchViewModelImpl> = { [unowned self] in
        return self._active.asObservable()
            .filter { $0 == false }
            .map { _ in return self }
    }()

    init(api: WWDCastAPI, router: SessionsSearchRouter) {
        self.api = api
        self.router = router
        self.filter = Variable(Filter())
        self.title = Driver.just(NSLocalizedString("WWDCast", comment: "Session search view title"))
        self._sessions = Variable([])

        let isLoading = ActivityIndicator()
        self.isLoading = isLoading.asDriver()
        
        self.didBecomeActive.subscribeNext({ viewModel in
            let sessionsObservable = self.api.sessions().trackActivity(isLoading)
            Observable.combineLatest(sessionsObservable, viewModel.filter.asObservable(), resultSelector: self.applyFilter)
                .asDriver(onErrorJustReturn: [])
                .drive(viewModel._sessions)
                .addDisposableTo(viewModel.disposeBag)
        }).addDisposableTo(self.disposeBag)
    }
    
    private func applyFilter(sessions: [Session], filter: Filter) -> [Session] {
        return sessions.apply(filter)
    }
    
    // MARK: SessionsSearchViewModel
    
    var sessions: Driver<[SessionViewModels]> {
        return self._sessions.asDriver().map(SessionViewModelBuilder.build)
    }
    let isLoading: Driver<Bool>
    let title: Driver<String>

    func itemSelectionObserver(viewModel: SessionViewModel) {
        guard let session = self._sessions.value.filter({ session in
            session.uniqueId == viewModel.uniqueID
        }).first else {
            return
        }
        self.router.showSessionDetails(session)
    }
    
    func filterObserver() {
        self.router.showFilterController(withFilter: self.filter.value) {[unowned self] filter in
            self.filter.value = filter
        }
    }
    
    func searchStringObserver(query: String) {
        var filter = self.filter.value
        filter.query = query
        self.filter.value = filter
    }
    
}
