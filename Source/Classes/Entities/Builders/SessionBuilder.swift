//
//  SessionBuilder.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 04/07/16.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import Foundation
import SwiftyJSON

class SessionBuilder: EntityBuilder {

    typealias EntityType = Session

    static func build(json: JSON) throws -> EntityType {
        guard let year = Year(rawValue: json["year"].uIntValue),
            let track = Track(rawValue: json["track"].stringValue),
            let videoURL = NSURL(string: json["download_hd"].stringValue),
            let subtitles = NSURL(string: json["subtitles"].stringValue),
            let focusJSON = json["focus"].arrayObject as? [String],
            let images = json["images"].dictionaryObject as? [String: String],
            let imageURLString = images["shelf"],
            let shelfImageURL = NSURL(string: imageURLString) else {
            throw EntityBuilderError.ParsingError
        }
        let id = json["id"].intValue
        let title = json["title"].stringValue
        let summary = json["description"].stringValue

        var platforms = [Platform]()
        platforms = try focusJSON.map() { focus in
            guard let platform = Platform(rawValue: focus) else {
                throw EntityBuilderError.ParsingError
            }
            return platform
        }

        return SessionImpl(id: id, year: year, track: track, platforms: platforms, title: title,
                           summary: summary, videoURL: videoURL, subtitles: subtitles,
                           shelfImageURL: shelfImageURL)
    }
    
}
