//
//  NetworkService.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 09/07/16.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import Foundation
import RxSwift

protocol NetworkService: class {

    func request<Builder: EntityBuilder>(url: NSURL, parameters: [String: AnyObject], builder: Builder.Type) -> Observable<Builder.EntityType>
}
