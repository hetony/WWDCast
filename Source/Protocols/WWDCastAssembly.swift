//
//  ModuleFactory.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 06/07/16.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import UIKit

protocol WWDCastAssembly: class {
    func sessionsSearchController() -> UIViewController
    func sessionDetailsController(sessionId: String) -> UIViewController
    func filterController(filter: Filter, completion: FilterModuleCompletion) -> UIViewController
}
