//
//  PDFViewController.swift
//  Showcase
//
//  Created by Pete Barnes on 10/17/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//
//  This class based on information found at: https://www.hackingwithswift.com/whats-new-in-ios-11
//                                            https://stackoverflow.com/questions/30203010/how-do-i-change-the-z-index-or-stack-order-of-uiview
//                                            https://developer.apple.com/videos/play/wwdc2017/241/

import UIKit
import PDFKit
import FirebaseAuth

class PDFViewController: UIViewController, FUIAuthViewClient {
    
    // MARK: - Properties
    var script: Script!
    var pdfView: PDFView!
    var activityView: UIActivityIndicatorView!
    var user: User?
    var userName = "Anonymous"
    var isFavorite = false
    var printButton: UIBarButtonItem!
    var favoriteButton: UIBarButtonItem!
    var videosButton: UIBarButtonItem!
    
    // MARK: - Outlets

    @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // https://www.hackingwithswift.com/example-code/uikit/how-to-show-and-hide-a-toolbar-inside-a-uinavigationcontroller
        
        printButton = UIBarButtonItem(title: "Print", style: .plain, target: self, action: #selector(printPdf))
        favoriteButton = UIBarButtonItem(image: UIImage(named: "heart"), style: .plain, target: self, action: #selector(toggleFavorite))
        videosButton = UIBarButtonItem(title: "Videos", style: .plain, target: self, action: #selector(showVideos))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolbarItems = [printButton, spacer, favoriteButton, spacer, videosButton]
        
        activityView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityView.center = view.center
        activityView.hidesWhenStopped = true
        
        view.addSubview(activityView)
        
        // create and add the PDF view
        pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)
        
        // make it take up the full screen
        pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pdfView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        // Center document on gray background
        pdfView.autoScales = true
        pdfView.backgroundColor = UIColor.lightGray
        
        view.sendSubview(toBack: pdfView)
        
        
        // Disable UI
        enableUI(false)
        
        // load the PDF and display it
        FIRDatabaseClient.sharedInstance.fetchPDF(for: script, userName: userName) { (pdfResult) in
            
            performUIUpdatesOnMain {
                switch pdfResult {
                case .success(let document) :
                    self.pdfView.document = document
                    
                default:
                    self.pdfView.document = nil
                    AlertViewHelper.presentAlert(self, title: "Script Unavailable", message: "The document requested could not be found.")
                }
                
                // Renable UI
                self.enableUI(true)
                self.favoriteButton.tintColor = (self.script.isFavorite) ? nil : .black
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    // MARK: - Actions
    
    @IBAction func logout(_ sender: Any) {
        logoutSession()
    }
    
    @IBAction func print(_ sender: Any) {
        printPdf ()
    }
    
    @objc func toggleFavorite() {
        
        let shouldFavorite = !isFavorite
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stack = appDelegate.stack
        let context = stack.context
        let mainContextScript = context.object(with: script.objectID) as! Script
        
        context.performAndWait {
            mainContextScript.isFavorite = shouldFavorite
            do {
                if context.hasChanges {
                    try context.save()
                }
                self.isFavorite = shouldFavorite
                performUIUpdatesOnMain {
                    self.favoriteButton.tintColor = (shouldFavorite) ? nil : .black
                }
                
            } catch {
                let saveError = error as NSError
                print("Unable to Save Script")
                print("\(saveError), \(saveError.localizedDescription)")
            }
        }
    }
    
    // MARK: - UI Functions
    
    func enableUI (_ isEnabled: Bool) {
        
        printButton.isEnabled = isEnabled
        favoriteButton.isEnabled = isEnabled
        videosButton.isEnabled = isEnabled
        logoutButton.isEnabled = isEnabled
        isEnabled ? activityView.stopAnimating(): activityView.startAnimating()
        
    }
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier! == "showVideosList",
            let videosTableVC = segue.destination as? VideosTableViewController  {
            
            // Pass data to the Videos Table View Controller
            videosTableVC.script = script
        }
    }
    
    @objc func showVideos() {
        performSegue(withIdentifier: "showVideosList", sender: self)
    }
    
    
    // Mark - Print PDF
    @objc func printPdf () {
        if let document = script.document,
            UIPrintInteractionController.canPrint(document as Data) {
            let printInfo = UIPrintInfo(dictionary: nil)
            printInfo.jobName = script.title!
            printInfo.outputType = .general
            
            let printController = UIPrintInteractionController.shared
            printController.printInfo = printInfo
            printController.showsNumberOfCopies = false
            
            printController.printingItem = script.document
            
            printController.present(animated: true)
        }
    }
}

// MARK - String
// This extension is from: https://medium.com/@johnsundell/exploring-the-new-string-api-in-swift-4-ce7d2c1cae00
extension String {
    func truncated() -> Substring {
        return prefix(15)
    }
}
