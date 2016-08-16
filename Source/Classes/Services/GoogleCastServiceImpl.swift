//
//  GoogleCastServiceImpl.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 09/07/16.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import Foundation
import GoogleCast
import RxSwift
import RxCocoa

struct GoogleCastDeviceImpl: GoogleCastDevice {
    var name: String
    var id: String
    
    var description: String {
        return name
    }
}

extension GCKMediaInformation {
    convenience init(session: Session) {
        let metadata = GCKMediaMetadata(metadataType: .Generic)
        metadata.setString(session.title, forKey: kGCKMetadataKeyTitle)
        metadata.setString(session.subtitle, forKey: kGCKMetadataKeySubtitle)
        metadata.addImage(GCKImage(URL: session.shelfImageURL, width: 734, height: 413))
        let mediaTrack = GCKMediaTrack(identifier: session.id, contentIdentifier: session.subtitles.absoluteString, contentType: "text/vtt", type: .Text, textSubtype: .Captions, name: "English Captions", languageCode: "en", customData: nil)

        self.init(contentID: session.sdVideoURL.absoluteString, streamType: .None, contentType: "video/mp4", metadata: metadata, streamDuration: 0, mediaTracks: [mediaTrack], textTrackStyle: GCKMediaTextTrackStyle.createDefault(), customData: nil)
    }
}

enum GoogleCastServiceError : ErrorType {
    case ConnectionError, PlaybackError
}

final class GoogleCastServiceImpl: NSObject, GoogleCastService {
    private let applicationID: String
    private let disposeBag = DisposeBag()
    private let deviceScanner: GCKDeviceScanner

    var devices: [GoogleCastDevice] {
        return self.deviceScanner.devices.map() {device in
            return GoogleCastDeviceImpl(name: device.friendlyName, id: device.deviceID)
        }
    }

    init(applicationID: String) {
        self.applicationID = applicationID
        // Create filter criteria to only show devices that can run your app
        let filterCriteria = GCKFilterCriteria(forAvailableApplicationWithID: applicationID)
        // Add the criteria to the scanner to only show devices that can run your app.
        // This allows you to publish your app to the Apple App store before before publishing in Cast
        // console. Once the app is published in Cast console the cast icon will begin showing up on ios
        // devices. If an app is not published in the Cast console the cast icon will only appear for
        // whitelisted dongles
        self.deviceScanner = GCKDeviceScanner(filterCriteria: filterCriteria)
        super.init()
        let options = GCKCastOptions(receiverApplicationID: self.applicationID)
        GCKCastContext.setSharedInstanceWithOptions(options)
        self.enableLogging()
        self.deviceScanner.addListener(self)
        self.deviceScanner.startScan()
    }
    
    func playSession(device: GoogleCastDevice, session: Session) -> Observable<Void> {
        return Observable.just(device)
            .flatMap(self.connectToDevice)
            .flatMap(self.launchApplication(self.applicationID))
            .flatMap(self.playSession(session))
    }
    
    func connectToDevice(device: GoogleCastDevice) -> Observable<GCKDeviceManager> {
        return Observable.create({[unowned self] observer in
            guard let gckDevice = self.deviceScanner.devices.filter({ device.id == $0.deviceID }).first else {
                observer.onError(GoogleCastServiceError.ConnectionError)
                observer.onCompleted()
                return NopDisposable.instance
            }
            
            let appIdentifier = NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"] as! String
            let deviceManager = GCKDeviceManager(device: gckDevice as! GCKDevice, clientPackageName: appIdentifier)
            
            deviceManager.rx_didFailToConnect.subscribeNext({ _ in
                observer.onError(GoogleCastServiceError.ConnectionError)
                observer.onCompleted()
            }).addDisposableTo(self.disposeBag)
            
            deviceManager.rx_didConnect.subscribeNext({ deviceManager in
                observer.onNext(deviceManager)
//                observer.onCompleted()
            }).addDisposableTo(self.disposeBag)
            
            deviceManager.connect()
            
            return AnonymousDisposable({
                deviceManager.disconnect()
            })
        })
    }
    
    func launchApplication(applicationId: String) -> GCKDeviceManager -> Observable<GCKDeviceManager> {
        return { deviceManager in
            return Observable.create({[unowned self] observer in
                
                deviceManager.rx_didConnectToCastApplication.subscribeNext({ _ in
                    observer.onNext(deviceManager)
                }).addDisposableTo(self.disposeBag)
                
                deviceManager.didFailToConnectToApplication.subscribeNext({ _ in
                    observer.onError(GoogleCastServiceError.ConnectionError)
                    observer.onCompleted()
                }).addDisposableTo(self.disposeBag)
                
                deviceManager.launchApplication(applicationId)
                
                return AnonymousDisposable({
                    deviceManager.disconnect()
                })
            })
        }
    }
    
    func playSession(session: Session) -> GCKDeviceManager -> Observable<Void> {
        return { deviceManager in
            return Observable.create({ observer in
                let mediaInfo = GCKMediaInformation(session: session)
                let mediaControlChannel = GCKMediaControlChannel()
                //                mediaControlChannel.delegate = self
                deviceManager.addChannel(mediaControlChannel)
                let id = mediaControlChannel.loadMedia(mediaInfo, autoplay: true)
                if (id == kGCKInvalidRequestID) {
                    observer.onError(GoogleCastServiceError.PlaybackError)
                } else {
                    observer.onNext()
                }
                observer.onCompleted()
                return NopDisposable.instance
            })
        }
    }
    
}

extension GoogleCastServiceImpl: GCKMediaControlChannelDelegate {
    func mediaControlChannelDidUpdateStatus(mediaControlChannel: GCKMediaControlChannel) {
        NSLog("%@", mediaControlChannel)
    }

    func mediaControlChannelDidUpdateMetadata(mediaControlChannel: GCKMediaControlChannel) {
        NSLog("%@", mediaControlChannel)
    }
}

extension GoogleCastServiceImpl: GCKDeviceScannerListener {

    func deviceDidComeOnline(device: GCKDevice) {

    }

    func deviceDidGoOffline(device: GCKDevice) {

    }

    func deviceDidChange(device: GCKDevice) {

    }
}

extension GoogleCastServiceImpl: GCKLoggerDelegate {

    func enableLogging() {
        GCKLogger.sharedInstance().delegate = self
    }

    func logFromFunction(function: UnsafePointer<Int8>, message: String) {
        NSLog("%s %@", function, message)
    }

}
