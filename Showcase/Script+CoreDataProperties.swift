//
//  Script+CoreDataProperties.swift
//  Showcase
//
//  Created by Pete Barnes on 10/18/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//
//

import Foundation
import CoreData


extension Script {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Script> {
        return NSFetchRequest<Script>(entityName: "Script")
    }

    @NSManaged public var title: String?
    @NSManaged public var genre: String?
    @NSManaged public var favorite: Bool
    @NSManaged public var gender: String?
    @NSManaged public var document: NSData?
    @NSManaged public var dateCreated: NSDate?
    @NSManaged public var url: URL?
    @NSManaged public var videos: NSSet?

}

// MARK: Generated accessors for videos
extension Script {

    @objc(addVideosObject:)
    @NSManaged public func addToVideos(_ value: Video)

    @objc(removeVideosObject:)
    @NSManaged public func removeFromVideos(_ value: Video)

    @objc(addVideos:)
    @NSManaged public func addToVideos(_ values: NSSet)

    @objc(removeVideos:)
    @NSManaged public func removeFromVideos(_ values: NSSet)

}
