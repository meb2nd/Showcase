//
//  Video+CoreDataClass.swift
//  Showcase
//
//  Created by Pete Barnes on 10/18/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//
//  Code for the image handling based on information from: https://www.lynda.com/Swift-tutorials/AVFoundation-Essentials-iOS-Swift/504183-2.html

import CoreData
import Photos
import UIKit

@objc(Video)
public class Video: NSManagedObject {

    
    // http://nshipster.com/nstemporarydirectory/
    
    func cleanup (fileURL: URL) {
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            // ...
        }
    }
    
    
    // Information for this method is located at: https://stackoverflow.com/questions/31779150/creating-thumbnail-from-local-video-in-swift
    //                                          https://stackoverflow.com/questions/33953841/how-to-get-thumbnail-image-of-video-picked-from-uipickerviewcontroller-in-swift
    func getThumbnailFrom(path: URL) -> UIImage? {
        
        do {
            
            let asset = AVURLAsset(url: path , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            // return UIImage(CGImage: imageRef scale: 1.0 , orientation: UIImageOrientation.Right)   in case problem with orientation
            let png = UIImagePNGRepresentation(thumbnail)
            
            return thumbnail
            
        } catch let error {
            
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
            
        }
        
    }
}
