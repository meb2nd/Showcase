//
//  Video+CoreDataProperties.swift
//  Showcase
//
//  Created by Pete Barnes on 10/18/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//
//

import Foundation
import CoreData


extension Video {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Video> {
        return NSFetchRequest<Video>(entityName: "Video")
    }

    @NSManaged public var dateCreated: NSDate?
    @NSManaged public var thumbnail: NSData?
    @NSManaged public var title: String?
    @NSManaged public var url: String?
    @NSManaged public var script: Script?

}
