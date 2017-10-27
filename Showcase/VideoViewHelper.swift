//
//  VideoViewHelper.swift
//  Showcase
//
//  Created by Pete Barnes on 10/26/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import AVFoundation
import AVKit
import UIKit

class VideoViewHelper {
    
    static let sharedInstance = VideoViewHelper()
    
    private init() {}
    
    func play(video: Video, presentingController: UIViewController) {
        
        let fm = FileManager.default
        
        guard let videoURLString = video.url,
            let documentDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
        }
        
        let videoURL = documentDirectory.appendingPathComponent(videoURLString)
        
        print("Trying to load video file at url = + \(videoURL)")
        
        // Filter code based on information found at:  https://stackoverflow.com/questions/39114863/applying-a-cifilter-to-a-video-file-and-saving-it
        //                                              https://developer.apple.com/videos/play/wwdc2015/510/?time=1222
        
        
        let avAsset = AVURLAsset(url: videoURL)
        
        // Begin composition
        let composition = AVVideoComposition(asset: avAsset, applyingCIFiltersWithHandler: { request in
            
            // Add black & white filter affect
            // Clamp to avoid issues with transparent pixels at the image edges
            // Useful in the event other affects (e.g. blurring) are added later...
            let tonalFilter = CIFilter(name: "CIPhotoEffectTonal")!
            tonalFilter.setDefaults()
            let source = request.sourceImage.clampedToExtent()
            tonalFilter.setValue(source, forKey: kCIInputImageKey)
            let tonalOutput = tonalFilter.outputImage!
            
            // Add watermark
            // https://medium.com/@dzungnguyen.hcm/add-overlay-image-to-video-21d9cc03c9eb
            let watermarkFilter = CIFilter(name: "CISourceOverCompositing")!
            let watermarkImage = CIImage(image: UIImage(named: "watermark")!)!
            watermarkFilter.setValue(tonalOutput, forKey: kCIInputBackgroundImageKey)
            let watermarkTransform: CGAffineTransform = CGAffineTransform(translationX: request.sourceImage.extent.width - watermarkImage.extent.width - 2, y: 0)
            watermarkFilter.setValue(watermarkImage.transformed(by: watermarkTransform), forKey: kCIInputImageKey)
            let watermarkOutput = watermarkFilter.outputImage!
            
            // Add title overlay
            let titleLayer = CATextLayer()
            let shadow = NSShadow()
            shadow.shadowColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            shadow.shadowOffset = CGSize(width: 0, height: 2)
            
            // Attributed string
            let myAttributes = [
                NSAttributedStringKey.font: UIFont(name: "HelveticaNeue-Bold", size: 10.0)! , // font
                NSAttributedStringKey.foregroundColor: UIColor.white, // font color
                NSAttributedStringKey.shadow: shadow   // shadow
            ]
            let myAttributedString = NSAttributedString(string: video.title ?? "No Title", attributes: myAttributes )
            titleLayer.string = myAttributedString
            titleLayer.fontSize = 10
            titleLayer.shadowOpacity = 0
            // https://stackoverflow.com/questions/3815443/how-to-get-text-in-a-catextlayer-to-be-clear
            let scale = UIScreen.main.scale
            titleLayer.contentsScale = scale
            titleLayer.isWrapped = true
            titleLayer.alignmentMode = kCAAlignmentCenter
            titleLayer.frame = CGRect(x: 0, y: 50, width: request.sourceImage.extent.width / scale, height: request.sourceImage.extent.height / (6 * scale))
            
            let titleUIImage = titleLayer.imageFromLayer(layer: titleLayer)
            let titleFilter = CIFilter(name: "CISourceOverCompositing")!
            let titleImage = CIImage(image: titleUIImage!)!
            titleFilter.setValue(watermarkOutput, forKey: kCIInputBackgroundImageKey)
            let titleTransform = CGAffineTransform(translationX: 5, y: request.sourceImage.extent.height - titleImage.extent.height)
            
            titleFilter.setValue(titleImage.transformed(by: titleTransform), forKey: kCIInputImageKey)
            
            // Crop the final output to the bounds of the original image
            let output = titleFilter.outputImage!.cropped(to: request.sourceImage.extent)
            
            // Provide the filter output to the composition
            request.finish(with: output, context: nil)
        })
        
        let playerItem = AVPlayerItem(asset: avAsset)
        playerItem.videoComposition = composition
        let player = AVPlayer(playerItem: playerItem)
        
        // Create a new AVPlayerViewController and pass it a reference to the player.
        let controller = AVPlayerViewController()
        controller.player = player
        
        // Modally present the player and call the player's play() method when complete.
        presentingController.present(controller, animated: true) {
            player.play()
            
            
            /*
             
             
             for sharing do the following:
             
             let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1920x1200)
             export.outputFileType = AVFileTypeQuickTimeMovie
             export.outputURL = outURL
             export.videoComposition = composition
             
             export.exportAsynchronouslyWithCompletionHandler(/*...*/)
             
             */
            
        }
    }
    
    func share(video: Video, presentingController: UIViewController) {
        
        let fm = FileManager.default
        
        guard let videoURLString = video.url,
            let documentDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
        }
        
        let videoURL = documentDirectory.appendingPathComponent(videoURLString)
        
        print("Trying to load video file at url = + \(videoURL)")
        
        let videoToShare = documentDirectory.absoluteString + videoURLString
        let url = URL(fileURLWithPath: videoToShare)
        
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        controller.completionWithItemsHandler = { (activity, success, items, error) in
            
            if(success && error == nil) {
                
                presentingController.dismiss(animated: true, completion: nil)
                
            } else {
                
                let controller = UIAlertController()
                controller.title = "Video Share Incomplete"
                controller.message = "Share was either cancelled or failed."
                
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { action in controller.dismiss(animated: true, completion: nil)
                }
                
                controller.addAction(okAction)
                presentingController.present(controller, animated: true, completion: nil)
            }
        }
        
        presentingController.present(controller, animated: true, completion: nil)
    }
}

extension CALayer {
    
    // https://stackoverflow.com/questions/3454356/uiimage-from-calayer-iphone-sdk
    func imageFromLayer(layer: CALayer) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, 0)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return outputImage
    }
}
