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
    
    // MARK: - Outlets
    
    @IBOutlet weak var printButton: UIBarButtonItem!
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    @IBOutlet weak var videosButton: UIBarButtonItem!
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
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
        FIRDatabaseClient.sharedInstance.fetchPDF(for: script) { (pdfResult) in
            
            performUIUpdatesOnMain {
                switch pdfResult {
                case .success(let document) :
                    document.delegate = self
                    self.addWatermark(to: document)
                    self.pdfView.document = document
                
                default:
                    self.pdfView.document = nil
                    AlertViewHelper.presentAlert(self, title: "Script Unavailble", message: "The document requested could not be found.")
                }
                
                // Renable UI
                self.enableUI(true)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
    @IBAction func logout(_ sender: Any) {
    }
    
    @IBAction func print(_ sender: Any) {
    }
    
    @IBAction func toggleFavorite(_ sender: Any) {
    }
    
    @IBAction func viewVideos(_ sender: Any) {
    }
    
    // MARK: - UI Functions
    
    func enableUI (_ isEnabled: Bool) {
        
        printButton.isEnabled = isEnabled
        favoriteButton.isEnabled = isEnabled
        videosButton.isEnabled = isEnabled
        logoutButton.isEnabled = isEnabled
        isEnabled ? activityView.stopAnimating(): activityView.startAnimating()
        
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    // Mark - Print PDF
    func printPdf () {
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

// MARK: - PDFViewController: PDFDocumentDelegate

extension PDFViewController: PDFDocumentDelegate {
    func classForPage() -> AnyClass {
        return WatermarkPage.self
    }
}

// MARK: - PDFViewController (Watermark functions)

extension PDFViewController {
    
    fileprivate func generateWatermark() -> String {
        
        var watermark = userName.uppercased()
        
        if watermark.characters.count >= 16 {
            watermark = String(watermark.truncated())
        } else {
            var padding:Int = (15 - watermark.count)/2
            
            while padding > 0 {
                watermark = " " + watermark
                padding -= 1
            }
        }
        
        return watermark
    }
    
    fileprivate func addWatermark(to document: (PDFDocument)) {
        
        let watermark = generateWatermark()
        
        for index in 0 ... document.pageCount - 1 {
            
            if let page = document.page(at: index) as? WatermarkPage {
                
                page.watermark = watermark as NSString
            }
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
