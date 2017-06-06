//
//  Resource.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 29/11/2016.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import Foundation
import SwiftyJSON

extension String {
    var URLEscaped: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
    }
}

struct Resource<T> {

    let url: URL
    let parameters: [String: AnyObject]
    let parser: (_ json: JSON) throws -> T
    var request: URLRequest? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.queryItems = parameters.keys.map { key in
            URLQueryItem(name: key.URLEscaped, value: "\(String(describing: parameters[key]))".URLEscaped)
        }
        guard let url = components.url else {
            return nil
        }
        return URLRequest(url: url)
    }

    init(url: URL, parser: @escaping (_ json: JSON) throws -> T) {
        self.init(url: url, parameters: [:], parser: parser)
    }

    init(url: URL, parameters: [String: AnyObject], parser: @escaping (_ json: JSON) throws -> T) {
        self.url = url
        self.parameters = parameters
        self.parser = parser
    }
}
