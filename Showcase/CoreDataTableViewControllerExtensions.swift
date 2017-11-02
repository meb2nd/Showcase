//
//  CoreDataTableViewControllerExtensions.swift
//  Showcase
//
//  Created by Pete Barnes on 10/26/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit

// MARK: - CoreDataTableViewController (Common Segues)

extension CoreDataTableViewController {
    
    func segueToShowPDF(_ segue: UIStoryboardSegue, userName: String) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier! == "showPDF",
            let pdfVC = segue.destination as? PDFViewController,
            let indexPath = tableView?.indexPathForSelectedRow {
            
            // Pass data to the PDF View Controller
            let script = fetchedResultsController!.object(at: indexPath) as! Script
            pdfVC.script = script
            pdfVC.userName = userName
        }
    }
    
    func setBackgroundColor(forCell cell: UITableViewCell) {
        
        cell.backgroundColor = UIColor(white: 1, alpha: 0.7)
        cell.textLabel?.backgroundColor = UIColor(white: 1, alpha: 0.0)
        cell.detailTextLabel?.backgroundColor = UIColor(white: 1, alpha: 0.0)

    }
}
