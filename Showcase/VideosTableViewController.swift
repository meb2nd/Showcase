//
//  VideosTableViewController.swift
//  Showcase
//
//  Created by Pete Barnes on 10/17/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//
// Code for this class taken from information found at:  https://www.raywenderlich.com/94404/play-record-merge-videos-ios-swift

import UIKit
import CoreData
import MediaPlayer
import MobileCoreServices
import Photos
import FirebaseAuth
import AVKit
import AVFoundation

class VideosTableViewController: CoreDataTableViewController, UINavigationControllerDelegate {
    
    // MARK: - Properties
    var script: Script!
    var deleteVideoIndexPath: IndexPath? = nil
    var videoOutput: AVPlayerItemVideoOutput!
    
    // MARK: - Outlets
    
    @IBOutlet weak var videosTableView: UITableView!
    @IBOutlet weak var captureVideoButton: UIBarButtonItem!
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videosTableView.separatorInset = UIEdgeInsetsMake(0, 5, 0, 5)
        createFetchController()
        
    }
    
    // MARK: - CoreDataTableViewController functions
    
    override func getTableView() -> UITableView {
        return videosTableView
    }
    
    fileprivate func createFetchController() {
        
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Video")
        let predicate = NSPredicate(format: "script = %@", argumentArray: [script])
        fr.predicate = predicate
        fr.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true),
                              NSSortDescriptor(key: "dateCreated", ascending: false)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    // MARK: - ScriptsTableViewController: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let video = fetchedResultsController!.object(at: indexPath) as! Video
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell", for: indexPath)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        cell.textLabel?.text = video.script?.title
        cell.detailTextLabel?.text = "Recorded \(dateFormatter.string(from: video.dateCreated! as Date))"
        if let imageData = video.thumbnail {
            cell.imageView?.image = UIImage(data: imageData as Data)
        }
        
        return cell
    }
    
    // MARK: - Actions
    
    @IBAction func logout(_ sender: Any) {
        logoutSession()
    }
    
    @IBAction func pickAnImageFromCamera(_ sender: Any) {
        
        startCameraFromViewController(viewController: self, withDelegate: self)
    }
    
    // MARK:  Helper
    
    func startCameraFromViewController(viewController: UIViewController, withDelegate delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate) -> Bool {
        if UIImagePickerController.isSourceTypeAvailable(.camera) == false {
            return false
        }
        
        let cameraController = UIImagePickerController()
        cameraController.mediaTypes = [kUTTypeMovie as NSString as String]
        cameraController.sourceType = .camera
        cameraController.cameraCaptureMode = .video
        cameraController.allowsEditing = false
        cameraController.delegate = delegate
        cameraController.videoMaximumDuration = TimeInterval(90.0)
        
        present(cameraController, animated: true, completion: nil)
        return true
    }
}

// MARK: - VideosTableViewController: UIImagePickerControllerDelegate

extension VideosTableViewController: UIImagePickerControllerDelegate {
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        dismiss(animated: true, completion: nil)
        // Handle a movie capture
        if mediaType == kUTTypeMovie {
            guard let movieURL = info[UIImagePickerControllerMediaURL] as? NSURL else { return }
            
            let fm = FileManager.default
            
            guard let documentDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }
            
            // https://stackoverflow.com/questions/41162610/create-directory-in-swift-3-0
            let videoPath = "showcase_videos/" + Auth.auth().currentUser!.uid
            let videoDirectory = documentDirectory.appendingPathComponent(videoPath)
            let videoURLString = videoPath + "/\(Double(Date.timeIntervalSinceReferenceDate * 1000)).MOV"
            let url = documentDirectory.appendingPathComponent(videoURLString)
            
            if !fm.fileExists(atPath: videoDirectory.path) {
                do {
                    try fm.createDirectory(atPath: videoDirectory.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Couldn't create document directory")
                }
            }
            
            print("Document directory is \(videoDirectory)")
            
            do {
                try fm.moveItem(at: movieURL as URL, to: url)
                print("Moved the movie file from the temporary directory.")
                print("New location is: \(url)")
            } catch {
                let saveError = error as NSError
                print("Failed to move the movie file from the temporary directory.")
                print("\(saveError), \(saveError.localizedDescription)")
                return
            }
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let stack = appDelegate.stack
            
            stack.performBackgroundBatchOperation() { (workerContext) in
                
                let backgroundScript = workerContext.object(with: self.script.objectID) as! Script
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .medium
                
                workerContext.performAndWait {
                    _ = Video(title: backgroundScript.title! + " - \(dateFormatter.string(from: Date()))",
                        script: backgroundScript,
                        url: videoURLString,
                        insertInto: workerContext)
                }
                
                do {
                    if workerContext.hasChanges {
                        try workerContext.save()
                    }
                } catch {
                    let saveError = error as NSError
                    print("Unable to Save Video")
                    print("\(saveError), \(saveError.localizedDescription)")
                }
            }
        }
    }
    
    @objc func video(_ videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        var title = "Success"
        var message = "Video was saved"
        if let _ = error {
            title = "Error"
            message = "Video failed to save"
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - UIImagePickerController
// https://stackoverflow.com/questions/33058691/use-uiimagepickercontroller-in-landscape-mode-in-swift-2-0

extension UIImagePickerController
{
    override open var shouldAutorotate: Bool {
        return true
    }
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .all
    }
}
// MARK: - VideosTableViewController: UITableViewDelegate

extension VideosTableViewController: UITableViewDelegate {
    
    // Code below based on code found at:   https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/MediaPlaybackGuide/Contents/Resources/en.lproj/GettingStarted/GettingStarted.html
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let video = fetchedResultsController!.object(at: indexPath) as? Video,
            let videoURLString = video.url {
            let fm = FileManager.default
            
            guard let documentDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }
            
            let videoURL = documentDirectory.appendingPathComponent(videoURLString)
            
            print("Trying to load video file at url = + \(videoURL)")
            
            // Filter code based on infomrmation found at:  https://stackoverflow.com/questions/39114863/applying-a-cifilter-to-a-video-file-and-saving-it
            //                                              https://developer.apple.com/videos/play/wwdc2015/510/?time=1222
            
            // For black & white filter affect
            
            let avAsset = AVURLAsset(url: videoURL)
            let tonalFilter = CIFilter(name: "CIPhotoEffectTonal")!
            
            // https://medium.com/@dzungnguyen.hcm/add-overlay-image-to-video-21d9cc03c9eb
            let watermarkFilter = CIFilter(name: "CISourceOverCompositing")!
            let watermarkImage = CIImage(image: UIImage(named: "watermark")!)!

            // Begin composition
            let composition = AVVideoComposition(asset: avAsset, applyingCIFiltersWithHandler: { request in
                
                tonalFilter.setDefaults()
                
                // Clamp to avoid issues with transparent pixels at the image edges
                // Useful in the event other affects (e.g. blurring) are added later...
                let source = request.sourceImage.clampedToExtent()
                tonalFilter.setValue(source, forKey: kCIInputImageKey)
                
                // Vary filter parameters based on video timing
                //let seconds = CMTimeGetSeconds(request.compositionTime)
                //filter.setValue(seconds * 10.0, forKey: kCIInputRadiusKey)
                
                let tonalOutput = tonalFilter.outputImage!
                
                // Add watermark
                watermarkFilter.setValue(tonalOutput, forKey: kCIInputBackgroundImageKey)
                let watermarkTransform: CGAffineTransform = CGAffineTransform(translationX: request.sourceImage.extent.width - watermarkImage.extent.width - 2, y: 0)
                watermarkFilter.setValue(watermarkImage.transformed(by: watermarkTransform), forKey: kCIInputImageKey)
                
                // Crop the final output to the bounds of the original image
                let watermarkOutput = watermarkFilter.outputImage!
                
                // Add title
                // Create overlay title
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
                //titleLayer.font = CTFontCreateWithName("HelveticaNeue-Bold" as CFString, 18, nil)
                titleLayer.fontSize = 10
                //titleLayer.foregroundColor
                titleLayer.shadowOpacity = 0
                // https://stackoverflow.com/questions/3815443/how-to-get-text-in-a-catextlayer-to-be-clear
                titleLayer.contentsScale = UIScreen.main.scale
                titleLayer.isWrapped = true
                //titleLayer.alignmentMode = kCAAlignmentCenter
                
                let scale = UIScreen.main.scale
                
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
            present(controller, animated: true) {
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
    }
    
    // Following based on code fouund at:  https://www.hackingwithswift.com/example-code/uikit/how-to-customize-swipe-edit-buttons-in-a-uitableview
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            self.deleteVideoIndexPath = indexPath
            self.confirmDelete()
        }
        
        let share = UITableViewRowAction(style: .normal, title: "Share") { (action, indexPath) in
            self.shareVideo(indexPath: indexPath)
        }
        
        share.backgroundColor = UIColor.blue
        
        return [delete, share]
    }
    
    // MARK: Helpers
    // The code for the delete functionality is based on information found at the following URL:
    // https://www.andrewcbancroft.com/2015/07/16/uitableview-swipe-to-delete-workflow-in-swift/
    
    func confirmDelete() {
        let alert = UIAlertController(title: "Delete Video", message: "Are you sure you want to permanently delete this Video?", preferredStyle: .actionSheet)
        
        let DeleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: handleDeleteVideo)
        let CancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: cancelDeleteVideo)
        
        alert.addAction(DeleteAction)
        alert.addAction(CancelAction)
        
        // Support display in iPad
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.size.width / 2.0, y: view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        present(alert, animated: true, completion: nil)
    }
    
    func handleDeleteVideo(alertAction: UIAlertAction!) -> Void {
        if let indexPath = deleteVideoIndexPath,
            let video = fetchedResultsController!.object(at: indexPath) as? Video,
            let videoURLString = video.url {
            
            let fm = FileManager.default
            guard let documentDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }
            
            let videoURL = documentDirectory.appendingPathComponent(videoURLString)
            
            print("Trying to delete video file at url = + \(videoURL)")
            
            do {
                try fm.removeItem(at: videoURL)
            } catch {
                print("Failed to delete video file at url = + \(videoURL)")
            }
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.stack.context
            
            if let video = context.object(with: video.objectID) as? Video {
                
                context.delete(video)
                
                context.performAndWait {
                    do {
                        if context.hasChanges {
                            try context.save()
                        }
                    } catch {
                        print(error)
                    }
                }
            }
            
            deleteVideoIndexPath = nil
        }
    }
    
    func cancelDeleteVideo(alertAction: UIAlertAction!) {
        deleteVideoIndexPath = nil
    }
    
    // Code for the completionWithItemsHandler in the following method is based upon information found at the following URL
    // http://seanwernimont.weebly.com/blog/december-02nd-2015
    
    func shareVideo(indexPath: IndexPath) {
        
        if let video = fetchedResultsController!.object(at: indexPath) as? Video,
            let videoURLString = video.url  {
            
            let fm = FileManager.default
            
            guard let documentDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }
            
            let videoURL = documentDirectory.appendingPathComponent(videoURLString)
            
            print("Trying to load video file at url = + \(videoURL)")
            
            let videoToShare = documentDirectory.absoluteString + videoURLString
            let url = URL(fileURLWithPath: videoToShare)
            
            let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            controller.completionWithItemsHandler = {
                (activity, success, items, error) in
                if(success && error == nil){
                    
                    self.dismiss(animated: true, completion: nil)
                    
                } else {
                    
                    let controller = UIAlertController()
                    controller.title = "Video Share Incomplete"
                    controller.message = "Share was either cancelled or failed."
                    
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { action in controller.dismiss(animated: true, completion: nil)
                    }
                    
                    controller.addAction(okAction)
                    self.present(controller, animated: true, completion: nil)
                }
            }
            
            present(controller, animated: true, completion: nil)
        }
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

