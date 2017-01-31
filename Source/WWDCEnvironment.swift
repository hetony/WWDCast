//
//  WWDCastAPI.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 04/07/16.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import Foundation

struct WWDCEnvironment {
    static var configURL: URL {
        let configURLString = "https://devimages-cdn.apple.com/wwdc-services/g7tk3guq/xhgbpyutb6wvn2xcrbcz/wwdc.json"
        if let configURL = URL(string: configURLString) {
            return configURL
        }
        fatalError("Failed to create url from \(configURLString)")
    }

    static let googleCastAppID = "B8373B04"
}
