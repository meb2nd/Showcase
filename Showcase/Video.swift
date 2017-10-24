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
    
    // MARK: - Initializer
    
    convenience init(title: String?, script: Script, url: String, insertInto context: NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: "Video", in: context) {
            self.init(entity: ent, insertInto: context)
            self.title = title
            self.script = script
            self.url = url
            self.thumbnail = getThumbnailFrom(videoURLString: url) as NSData?
            self.dateCreated = Date() as NSDate
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
    
    
    // Information for this method is located at: https://stackoverflow.com/questions/31779150/creating-thumbnail-from-local-video-in-swift
    //                                          https://stackoverflow.com/questions/33953841/how-to-get-thumbnail-image-of-video-picked-from-uipickerviewcontroller-in-swift
    private func getThumbnailFrom(videoURLString: String) -> Data? {
        
        do {
            
            let fm = FileManager.default
            guard let documentDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return nil
            }
            
            let videoURL = documentDirectory.appendingPathComponent(videoURLString)
            
            let asset = AVURLAsset(url: videoURL , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: applyFilter(toImage: cgImage)!)
            // return UIImage(CGImage: imageRef scale: 1.0 , orientation: UIImageOrientation.Right)   in case problem with orientation
            let thumbnailImageData = UIImagePNGRepresentation(thumbnail)
            
            return thumbnailImageData
            
        } catch let error {
            
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func applyFilter(toImage originalImage: CGImage) -> CGImage? {
        
        // Apply Black & White filter to image
        let ciContext = CIContext(options: nil)
        let coreImage = CIImage(cgImage: originalImage)
        let filter = CIFilter(name: "CIPhotoEffectTonal" )
        filter!.setDefaults()
        filter!.setValue(coreImage, forKey: kCIInputImageKey)
        let filteredImageData = filter!.value(forKey: kCIOutputImageKey) as! CIImage
        let filteredImageRef = ciContext.createCGImage(filteredImageData, from: filteredImageData.extent)
        return filteredImageRef
    }
}
