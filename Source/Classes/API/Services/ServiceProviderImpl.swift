//
//  ServiceProviderImpl.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 09/07/16.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import Foundation

final class ServiceProviderImpl: ServiceProvider {

    private(set) var reachability: ReachabilityService
    private(set) var scheduler: SchedulerService
    private(set) var network: NetworkService
    private(set) var googleCast: GoogleCastService
    private(set) var cache: CacheService

    init(reachability: ReachabilityService, scheduler: SchedulerService, network: NetworkService, googleCast: GoogleCastService, cache: CacheService) {
        self.reachability = reachability
        self.scheduler = scheduler
        self.network = network
        self.googleCast = googleCast
        self.cache = cache
    }
}

extension ServiceProviderImpl {
    
    static let defaultServiceProvider: ServiceProvider = {
        guard let reachability = try? ReachabilityServiceImpl() else {
            fatalError("Failed to create reachability service!")
        }
        let scheduler = SchedulerServiceImpl()
        let network = NetworkServiceImpl()
        let googleCast = GoogleCastServiceImpl(applicationID: WWDCEnvironment.googleCastAppID)
        let cache = CacheServiceImpl()
        return ServiceProviderImpl(reachability: reachability, scheduler: scheduler, network: network, googleCast: googleCast, cache: cache)
    }()

}
