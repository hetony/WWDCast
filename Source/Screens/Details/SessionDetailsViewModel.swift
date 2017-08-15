//
//  SessionsDetailsPresenterImpl.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 06/07/16.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SessionDetailsViewModel: SessionDetailsViewModelProtocol {
    private let disposeBag = DisposeBag()
    private let api: WWDCastAPIProtocol
    private let sessionObservable: Observable<Session>
    private let favoriteTrigger = PublishSubject<Void>()
    private let errorTrigger = PublishSubject<(String?, String)>()

    init(sessionId: String, api: WWDCastAPIProtocol) {
        self.api = api
        let sessionObservable = self.api.session(withId: sessionId)
        let favoriteObservable = self.favoriteTrigger.withLatestFrom(sessionObservable).flatMap(self.api.toggle)
        self.sessionObservable = Observable.of(sessionObservable, favoriteObservable).merge()
    }

    // MARK: SessionDetailsViewModel

    let title = Driver.just(NSLocalizedString("Session Details", comment: "Session details view title"))

    lazy var session: Driver<SessionItemViewModel?> = {
        return self.sessionObservable.map(SessionItemViewModelBuilder.build).asDriver(onErrorJustReturn: nil)
    }()

    var devices: Driver<[String]> {
        return self.api.devices.map({ device -> [String] in
            return device.map({ $0.description })
        }).asDriver(onErrorJustReturn: [String]())
    }

    var error: Driver<(String?, String)> {
        return self.errorTrigger.asDriver(onErrorJustReturn: (title: nil, message: ""))
    }

    func startPlaybackOnDevice(at index: Int) {
        let deviceObservable = self.api.devices.map({ devices in
            return devices[index]
        })
        Observable.combineLatest(self.sessionObservable, deviceObservable, resultSelector: { ($0, $1) })
            .take(1)
            .flatMap(self.api.play)
            .subscribe(onError: self.didFailToPlaySession)
            .addDisposableTo(self.disposeBag)
    }

    func toggleFavorite() {
        self.favoriteTrigger.onNext()
    }

    // MARK: Private

    private func didFailToPlaySession(with error: Error) {
        errorTrigger.onNext((NSLocalizedString("Ooops...", comment: ""), NSLocalizedString("Failed to play WWDC session.", comment: "")))
    }

}