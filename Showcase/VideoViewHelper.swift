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
    
    // MARK: - Main Video Functions
    
    func play(video: Video, presentingController: UIViewController) {
        
        
        // Begin composition
        let (comp, asset) = createComposition(forVideo: video)
        
        guard let composition = comp,
            let avAsset = asset else {
                AlertViewHelper.presentAlert(presentingController, title: "Video Error", message: "Cannot play the requested video.")
                return
        }
        
        let playerItem = AVPlayerItem(asset: avAsset)
        playerItem.videoComposition = composition
        let player = AVPlayer(playerItem: playerItem)
        
        // Create a new AVPlayerViewController and pass it a reference to the player.
        let controller = AVPlayerViewController()
        controller.player = player
        
        // Modally present the player and call the player's play() method when complete.
        presentingController.present(controller, animated: true) {
            player.play()
        }
    }
    
    
    // Code below is based on information found at: http://seanwernimont.weebly.com/blog/december-02nd-2015
    //                                              https://developer.apple.com/videos/play/wwdc2015/510/?time=1222
    //                                              https://www.lynda.com/Swift-tutorials/AVFoundation-Essentials-iOS-Swift/504183-2.html
    func share(video: Video, presentingController: UIViewController) {
        
        // Begin composition
        let (comp, asset) = createComposition(forVideo: video)
        
        guard let composition = comp,
            let avAsset = asset else {
                AlertViewHelper.presentAlert(presentingController, title: "Video Error", message: "Cannot play the requested video.")
                return
        }
        
        let videoToShare = NSTemporaryDirectory() + "tempMonologue.mp4"
        let shareURL = URL(fileURLWithPath: videoToShare)
        guard let export = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPreset1920x1080) else {return}
        export.outputFileType = AVFileType.mp4
        export.outputURL = shareURL
        export.videoComposition = composition
        do {
            try FileManager.default.removeItem(at: shareURL) // Delete exisiting temp file if exists
        } catch {
            print("There was an error deleting temp video file: \(error)")
        }
        
        export.exportAsynchronously(completionHandler: {
            switch export.status {
            case .completed:
                print("success")
                performUIUpdatesOnMain {
                    self.presentActivityView(withURL: shareURL, presentingController: presentingController)
                }
                break
            case .cancelled:
                print("cancelled")
                break
            case .exporting:
                print("exporting")
                break
            case .failed:
                print("failed: \(String(describing: export.error))")
                break
            case .unknown:
                print("unknown")
                break
            case .waiting:
                print("waiting")
                break
            }
        })
    }
    
    // MARK:  Helper Functions
    
    fileprivate func createTitleImage(forVideo video: Video, request: AVAsynchronousCIImageFilteringRequest) -> UIImage? {
        
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
        // Code fix for pixelated font found at: https://stackoverflow.com/questions/3815443/how-to-get-text-in-a-catextlayer-to-be-clear
        let scale = UIScreen.main.scale
        titleLayer.contentsScale = scale
        titleLayer.isWrapped = true
        titleLayer.alignmentMode = kCAAlignmentCenter
        titleLayer.frame = CGRect(x: 0, y: 50, width: request.sourceImage.extent.width / scale, height: request.sourceImage.extent.height / (6 * scale))
        
        let titleUIImage = titleLayer.imageFromLayer(layer: titleLayer)
        
        return titleUIImage
    }
    
    fileprivate func createComposition(forVideo video: Video) -> (AVVideoComposition?, AVAsset?) {
        
        let fm = FileManager.default
        
        guard let videoURLString = video.url,
            let documentDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return (nil, nil)
        }
        
        let videoURL = documentDirectory.appendingPathComponent(videoURLString)
        
        print("Trying to load video file at url = + \(videoURL)")
        
        // Filter code based on information found at:  https://stackoverflow.com/questions/39114863/applying-a-cifilter-to-a-video-file-and-saving-it
        //                                              https://developer.apple.com/videos/play/wwdc2015/510/?time=1222
        
        
        let avAsset = AVURLAsset(url: videoURL)
        
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
            // Code below based on information from:  https://medium.com/@dzungnguyen.hcm/add-overlay-image-to-video-21d9cc03c9eb
            let watermarkFilter = CIFilter(name: "CISourceOverCompositing")!
            let watermarkImage = CIImage(image: UIImage(named: "watermark")!)!
            watermarkFilter.setValue(tonalOutput, forKey: kCIInputBackgroundImageKey)
            let watermarkTransform: CGAffineTransform = CGAffineTransform(translationX: request.sourceImage.extent.width - watermarkImage.extent.width - 2, y: 0)
            watermarkFilter.setValue(watermarkImage.transformed(by: watermarkTransform), forKey: kCIInputImageKey)
            let watermarkOutput = watermarkFilter.outputImage!
            
            // Add title overlay
            
            let titleUIImage = self.createTitleImage(forVideo: video, request: request)
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
        
        return (composition, avAsset)
    }
    
    fileprivate func presentActivityView(withURL url: URL, presentingController: UIViewController) {
        
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        activityController.completionWithItemsHandler = { (activity, success, items, error) in
            
            if (success && error == nil) {
                
                presentingController.dismiss(animated: true, completion: nil)
                
            } else {
                
                let alertController = UIAlertController()
                alertController.title = "Video Share Incomplete"
                alertController.message = "Share was either cancelled or failed."
                
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { action in alertController.dismiss(animated: true, completion: nil)
                }
                
                alertController.addAction(okAction)
                presentingController.present(alertController, animated: true, completion: nil)
            }
        }
        
        presentingController.present(activityController, animated: true, completion: nil)
    }
}

// MARK: - CALayer (Helper functions)

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
