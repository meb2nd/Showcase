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
    
    // MARK: - Outlets
    
    @IBOutlet weak var videosTableView: UITableView!
    @IBOutlet weak var captureVideoButton: UIBarButtonItem!
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createFetchController()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier! == "playVideo",
            let videoVC = segue.destination as? VideoViewController,
            let indexPath = tableView?.indexPathForSelectedRow,
            let video = fetchedResultsController!.object(at: indexPath) as? Video {
            
            // Pass data to the Video View Controller
            videoVC.video = video
        }
    }
    
    @IBAction func logout(_ sender: Any) {
        logoutSession()
    }
    
    
    // MARK: - CoredDataTableViewController functions
    
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
        
        cell.textLabel?.text = video.script?.title
        cell.detailTextLabel?.text = video.dateCreated?.description
        
        return cell
    }
    
    @IBAction func pickAnImageFromAlbum(_ sender: Any) {
        
        setUpImagePicker (sourceType: .savedPhotosAlbum)
    }
    
    @IBAction func pickAnImageFromCamera(_ sender: Any) {
        
        startCameraFromViewController(viewController: self, withDelegate: self)
    }
    
    func setUpImagePicker (sourceType: UIImagePickerControllerSourceType) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        if sourceType == .camera {
            imagePicker.cameraCaptureMode = .video
        }
        //imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func startMediaBrowserFromViewController(viewController: UIViewController, usingDelegate delegate: UINavigationControllerDelegate & UIImagePickerControllerDelegate) -> Bool {
        // 1
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) == false {
            return false
        }
        
        // 2
        let mediaUI = UIImagePickerController()
        mediaUI.sourceType = .savedPhotosAlbum
        mediaUI.mediaTypes = [kUTTypeMovie as NSString as String]
        mediaUI.allowsEditing = true
        mediaUI.delegate = delegate
        
        // 3
        present(mediaUI, animated: true, completion: nil)
        return true
    }
    
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
        cameraController.videoMaximumDuration = TimeInterval(30.0)
        
        present(cameraController, animated: true, completion: nil)
        return true
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

// MARK: - UIImagePickerControllerDelegate
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
                dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
                var newVideo: Video!
                
                workerContext.performAndWait {
                    newVideo = Video(context: workerContext)
                    newVideo.script = backgroundScript
                    newVideo.url = videoURLString
                    newVideo.title = backgroundScript.title // ?? "" + " - \(dateFormatter.string(from: Date()))"
                    newVideo.dateCreated = Date() as NSDate
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
}


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

extension VideosTableViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let video = fetchedResultsController!.object(at: indexPath) as? Video,
            let videoURLString = video.url {
            let fm = FileManager.default
            
            guard let documentDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }

            let videoURL = documentDirectory.appendingPathComponent(videoURLString)
            
            print("Trying to load video file at url = + \(videoURL)")

            
            // Create an AVPlayer, passing it the URL.
            let player = AVPlayer(url: videoURL)
            
            // Create a new AVPlayerViewController and pass it a reference to the player.
            let controller = AVPlayerViewController()
            controller.player = player
            
            // Modally present the player and call the player's play() method when complete.
            present(controller, animated: true) {
                player.play()
            }
        }
    }
}

