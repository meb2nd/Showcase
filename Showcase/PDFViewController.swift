//
//  PDFViewController.swift
//  Showcase
//
//  Created by Pete Barnes on 10/17/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//
//  This class based on information found at: https://www.hackingwithswift.com/whats-new-in-ios-11

import UIKit
import PDFKit

class PDFViewController: UIViewController {
    
    // MARK: Properties
    var script: Script!
    var pdfView: PDFView!
    var activityView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        activityView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityView.center = self.view.center
        activityView.hidesWhenStopped = true
        activityView.startAnimating()
        
        self.view.addSubview(activityView)
        
        // create and add the PDF view
        pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)
        
        // make it take up the full screen
        pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pdfView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        // load the PDF and display it
        
        // Disable UI
        
        FIRDatabaseClient.sharedInstance.fetchPDF(for: script) { (pdfResult) in
            
            performUIUpdatesOnMain {
                switch pdfResult {
                case .success(let document) :
                    self.pdfView.document = document
                default:
                    self.pdfView.document = nil
                    AlertViewHelper.presentAlert(self, title: "Script Unavailble", message: "This document requested could not be found.")
                }
                
                // Renable UI
                self.activityView.stopAnimating()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
