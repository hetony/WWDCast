//
//  GoogleCastService.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 09/07/16.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import Foundation
import GoogleCast
import RxSwift
import RxCocoa

final class GoogleCastService: NSObject, GoogleCastServiceType {
    private let disposeBag = DisposeBag()
    private var context: GCKCastContext {
        return GCKCastContext.sharedInstance()
    }
    private var sessionManager: GCKSessionManager {
        return self.context.sessionManager
    }
    private var currentSession: GCKCastSession? {
        return self.sessionManager.currentCastSession
    }

    init(applicationID: String) {
        super.init()
        let options = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: applicationID))
        GCKCastContext.setSharedInstanceWith(options)
        self.context.useDefaultExpandedMediaControls = true
        self.enableLogging()
    }

    // MARK: GoogleCastServiceProtocol

    var devices: Observable<[GoogleCastDevice]> {
        let devices: Observable<[GCKDevice]> = Observable.deferred {
            let discoveryManager = self.context.discoveryManager
            guard discoveryManager.hasDiscoveredDevices else {
                return .error(GoogleCastServiceError.noDevicesFound)
            }
            let devices = (0..<discoveryManager.deviceCount).map({ idx in
                return discoveryManager.device(at: idx)
            })
            return .just(devices)
        }
        return Observable.concat(devices, self.context.discoveryManager.rx.didUpdateDeviceList)
            .map(self.devices)
            .distinctUntilChanged(==)
            .share(replay: 1)
    }

    func play(media: GoogleCastMedia, onDevice device: GoogleCastDevice) -> Observable<Void> {
        return Observable.just(device)
            .flatMap(self.startSession)
            .flatMap(self.loadMedia(media.gckMedia))
    }

    func pausePlayback() {
        guard let remoteMediaClient = self.currentSession?.remoteMediaClient else {
            return
        }
        remoteMediaClient.pause()
    }

    func resumePlayback() {
        guard let remoteMediaClient = self.currentSession?.remoteMediaClient else {
            return
        }
        remoteMediaClient.play()
    }

    func stopPlayback() {
        guard let remoteMediaClient = self.currentSession?.remoteMediaClient else {
            return
        }
        remoteMediaClient.stop()
    }

    // MARK: Private

    private func devices(from gckDevices: [GCKDevice]) -> [GoogleCastDevice] {
        return gckDevices.map { device in
            return GoogleCastDevice(name: device.friendlyName ?? "Unknown", id: device.deviceID)
        }
    }

    private func device(withId id: String) -> GCKDevice? {
        return (0..<self.context.discoveryManager.deviceCount).map({ idx in
            return self.context.discoveryManager.device(at: idx)
        }).filter({ gckDevice in
            return gckDevice.deviceID == id
        }).first
    }

    private func startSession(_ device: GoogleCastDevice) -> Observable<GCKCastSession> {
        return Observable.create({[weak self] observer in
            guard let `self` = self else {
                assertionFailure("The \(GoogleCastService.self) object is deallocated!")
                return Disposables.create()
            }
            guard let gckDevice = self.device(withId: device.id) else {
                observer.onError(GoogleCastServiceError.connectionError)
                observer.onCompleted()
                return Disposables.create()
            }

            let didStartSubscription = self.sessionManager.rx.didStart.subscribe(onNext: { sessionManager in
                if let currentCastSession = sessionManager.currentCastSession {
                    observer.onNext(currentCastSession)
                } else {
                    observer.onError(GoogleCastServiceError.connectionError)
                }
                observer.onCompleted()
            })
            let didFailToStartSubscription = self.sessionManager.rx.didFailToStart.subscribe(onNext: { _ in
                observer.onError(GoogleCastServiceError.connectionError)
                observer.onCompleted()
            })

            if let castSession = self.sessionManager.currentCastSession {
                observer.onNext(castSession)
                observer.onCompleted()
            } else if !self.sessionManager.startSession(with: gckDevice) {
                observer.onError(GoogleCastServiceError.connectionError)
                observer.onCompleted()
            }
            return Disposables.create {
                didStartSubscription.dispose()
                didFailToStartSubscription.dispose()
            }
        })
    }

    private func loadMedia(_ mediaInfo: GCKMediaInformation) -> (GCKCastSession) -> Observable<Void> {
        return { castSession in
            return Observable.create({ observer in
                guard let remoteMediaClient = castSession.remoteMediaClient else {
                    observer.onError(GoogleCastServiceError.connectionError)
                    observer.onCompleted()
                    return Disposables.create()
                }
                let options = GCKMediaLoadOptions()
                options.autoplay = true
                Log.debug("Load media: \(mediaInfo) options: \(options)")
                let request = remoteMediaClient.loadMedia(mediaInfo, with: options)

                let didCompleteSubscription = request.rx.didComplete.subscribe(onNext: { _ in
                    observer.onNext(())
                    observer.onCompleted()
                })
                let didFailWithErrorSubscription = request.rx.didFailWithError.subscribe(onNext: { error in
                    Log.debug("Error: \(error.localizedDescription)")
                    observer.onError(GoogleCastServiceError.connectionError)
                    observer.onCompleted()
                })

                return Disposables.create {
                    didCompleteSubscription.dispose()
                    didFailWithErrorSubscription.dispose()
                }
            })
        }
    }

}

extension GoogleCastService: GCKLoggerDelegate {

    func enableLogging() {
        let logFilter = GCKLoggerFilter()
        logFilter.setLoggingLevel(.warning, forClasses: [
//            "GCKEventLogger",
            "\(GCKCastContext.self)",
            "\(GCKDeviceProvider.self)",
            "\(GCKDiscoveryManager.self)",
            "\(GCKSessionManager.self)",
            "\(GCKUICastButton.self)",
            "\(GCKUIMediaController.self)",
            "\(GCKUIMiniMediaControlsViewController.self)",
            "\(GCKCastChannel.self)"
        ])
        GCKLogger.sharedInstance().filter = logFilter
        GCKLogger.sharedInstance().delegate = self
    }

    func log(fromFunction function: UnsafePointer<Int8>, message: String) {
        Log.debug("\(function) \(message)")
    }

}
