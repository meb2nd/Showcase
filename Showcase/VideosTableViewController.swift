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

class VideosTableViewController: CoreDataTableViewController, UINavigationControllerDelegate {
    
    // MARK: - Properties
    var script: Script!
    var deleteVideoIndexPath: IndexPath? = nil
    var captureVideoButton: UIBarButtonItem!
    var priorCount = 0
    var hasCapturedFirstVideo = false
    
    // MARK: - Outlets
    
    @IBOutlet weak var videosTableView: UITableView!
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videosTableView.separatorInset = UIEdgeInsetsMake(0, 5, 0, 5)
        createFetchController()
        
        captureVideoButton = UIBarButtonItem(title: "Capture Video", style: .plain, target: self, action: #selector(pickAnImageFromCamera))
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolbarItems = [captureVideoButton, spacer]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: false)
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
    // Code for popover functionality based on information cound at:  https://stackoverflow.com/questions/27353691/uipopoverpresentationcontroller-displaying-popover-as-full-screen
    //
    
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
        cell.accessoryType = .disclosureIndicator
        
        if hasCapturedFirstVideo,
            indexPath.row == 0,
            !GeneralSettings.isOnboardingFinished() {
            
                performUIUpdatesOnMain() {
                    self.displayPopover(at: indexPath)
                }
        }
        
        return cell
    }
    
    // MARK: Helper function
    
    fileprivate func displayPopover(at indexPath: IndexPath) {
        if let cell = videosTableView.cellForRow(at: indexPath) {
            let popover = StoryboardManager.videosTablePopoverViewController()
            popover.modalPresentationStyle = .popover
            popover.popoverPresentationController?.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
            popover.popoverPresentationController?.delegate = self
            popover.popoverPresentationController?.sourceView = cell
            popover.popoverPresentationController?.sourceRect = cell.bounds
            popover.popoverPresentationController?.permittedArrowDirections = .any
            // Adjust height for "Don't Show Again" Button
            popover.preferredContentSize = CGSize(width: 320, height: GeneralSettings.hasLaunchedVideoSwipePopoverBefore() ? 200: 100)
            present(popover, animated: true, completion: nil)
            
            if !GeneralSettings.hasLaunchedVideoSwipePopoverBefore() {
                GeneralSettings.saveHasLaunchedVideoSwipePopoverBefore()
            }
        }
    }
    
    // MARK: - VideosTableViewController: NSFetchedResultsControllerDelegate
    
    override func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        guard let currentCount = fetchedResultsController?.fetchedObjects?.count else {return}
        
        if currentCount == 1 && priorCount == 0 {
            hasCapturedFirstVideo = true
        } else {
            hasCapturedFirstVideo = false
        }
        
        priorCount = currentCount
        
        super.controllerDidChangeContent(controller)
    }
    
    // MARK: - Actions
    
    @IBAction func logout(_ sender: Any) {
        logoutSession()
    }

    
   @objc func pickAnImageFromCamera() {
        
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
            
            VideoManager.sharedInstance.saveVideo(atURL: movieURL as URL, forScript: self.script)
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
        
        if let video = fetchedResultsController!.object(at: indexPath) as? Video {
            
            VideoViewHelper.sharedInstance.play(video: video, presentingController: self)
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
            let video = fetchedResultsController!.object(at: indexPath) as? Video {
            
            VideoManager.sharedInstance.delete(video: video)
            
            deleteVideoIndexPath = nil
        }
    }
    
    func cancelDeleteVideo(alertAction: UIAlertAction!) {
        deleteVideoIndexPath = nil
    }
    
    func shareVideo(indexPath: IndexPath) {
        
        if let video = fetchedResultsController!.object(at: indexPath) as? Video {
            
            VideoViewHelper.sharedInstance.share(video: video, presentingController: self)
        }
    }
}

// MARK: VideosTableViewController: UIPopoverPresentationControllerDelegate

extension VideosTableViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
