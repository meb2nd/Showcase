//
//  FavoriteScriptsTableViewController.swift
//  Showcase
//
//  Created by Pete Barnes on 10/17/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit
import CoreData
import FirebaseAuth

class FavoriteScriptsTableViewController: CoreDataTableViewController, FUIAuthViewClient {
    
    // MARK: - Properties
    var userName = "Anonymous"
    var user: User? {
        didSet {
            if user != oldValue {
                createFetchController()
            }
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet var scriptsTableView: UITableView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var noFavoritesSelectedLabel: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBarColors()
        
        scriptsTableView.tableFooterView = UIView(frame: CGRect.zero)
        scriptsTableView.backgroundView = backgroundView
        
        noFavoritesSelectedLabel.text = "No Favorites Selected."
        formatNoTableDataLabel(label: noFavoritesSelectedLabel)
        
        hideNoFavoritesSelectedLabelIfNeeded()
    }

    
    // MARK: - Actions
    
    @IBAction func signOut(_ sender: Any) {
        logoutSession()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        segueToShowPDF(segue, userName: userName)
    }
    
    // MARK: - CoredDataTableViewController functions
    
    override func getTableView() -> UITableView {
        return scriptsTableView
    }
    
    fileprivate func createFetchController() {
        
        guard let user = user else {
            fetchedResultsController = nil
            return
        }
        
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Script")
        let predicate = NSPredicate(format: "isFavorite = %@ AND uid = %@", argumentArray: [true, user.uid])
        fr.predicate = predicate
        fr.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true),
                              NSSortDescriptor(key: "dateCreated", ascending: false)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    // MARK: - FavoriteScriptsTableViewController: NSFetchedResultsControllerDelegate
    
    override func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        super.controllerDidChangeContent(controller)
        
        hideNoFavoritesSelectedLabelIfNeeded()
    }
    
    fileprivate func hideNoFavoritesSelectedLabelIfNeeded() {
        
        if let count = fetchedResultsController?.fetchedObjects?.count,
            count > 0 {
            noFavoritesSelectedLabel.isHidden = true
        } else {
            noFavoritesSelectedLabel.isHidden = false
        }
    }
    
    // MARK: - FavoriteScriptsTableViewController: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let script = fetchedResultsController!.object(at: indexPath) as! Script
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScriptCell", for: indexPath)
        
        cell.textLabel?.text = script.title
        cell.detailTextLabel?.text = script.genre
        
        // Information about custom disclosure found at:  https://medium.com/@ronm333/changing-the-color-of-a-disclosure-indicator-666a7fdd9286
        cell.accessoryType = .disclosureIndicator
        cell.accessoryView = UIImageView(image: UIImage(named: "chevron.png"))
        
        return cell
    }
}

// MARK: - FavoriteScriptsTableViewController: UITableViewDelegate

extension FavoriteScriptsTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        setBackgroundColor(forCell: cell)
    }
}

