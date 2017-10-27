//
//  ScriptsTableViewController.swift
//  Showcase
//
//  Created by Pete Barnes on 10/17/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit
import FirebaseAuthUI
import CoreData

class ScriptsTableViewController: CoreDataTableViewController {
    
    // MARK: - Properties
    
    var hasShownQuote = false
    var quoteScreen: ModalLoadingWindow?
    var userName = "Anonymous"
    var _authHandle: AuthStateDidChangeListenerHandle!
    var user: User? {
        didSet {
            if user != oldValue {
                createFetchController()
                if let tabBarController = tabBarController, let user = user {
                    injectViewController(tabBarController, withUser: user)
                }
            }
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var loginStackView: UIStackView!
    @IBOutlet weak var scriptsTableView: UITableView!
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureAuth()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        
        Auth.auth().removeStateDidChangeListener(_authHandle)
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
        let predicate = NSPredicate(format: "uid = %@", argumentArray: [user.uid])
        fr.predicate = predicate
        fr.sortDescriptors = [NSSortDescriptor(key: "genre", ascending: true),
                              NSSortDescriptor(key: "title", ascending: true),
                              NSSortDescriptor(key: "dateCreated", ascending: false)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: #keyPath(Script.genre), cacheName: nil)
    }
    
    fileprivate func injectViewController (_ viewController: UIViewController, withUser user: User) {
        
        // Following code is based upon information found at: http://cleanswifter.com/dependency-injection-with-storyboards/
        if let tabVC = viewController as? UITabBarController {
            for controller in tabVC.viewControllers ?? [] {
                injectViewController(controller, withUser: user)
            }
        } else if let navVC = viewController as? UINavigationController{
            for controller in navVC.viewControllers {
                injectViewController(controller, withUser: user)
            }
        } else if let firstViewController = viewController as? FUIAuthViewClient {
            firstViewController.user = user
        }
    }
    
    // MARK: - Actions
    
    @IBAction func showLoginView(_ sender: Any) {
        loginSession()
    }
    
    
    @IBAction func signOut(_ sender: Any) {
        logoutSession()
    }
    
    // MARK: - ScriptsTableViewController: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let script = fetchedResultsController!.object(at: indexPath) as! Script
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScriptCell", for: indexPath)
        
        cell.textLabel?.text = script.title
        cell.detailTextLabel?.text = "Gender: \(script.gender?.capitalized ?? " ")"
        
        return cell
    }
}

// MARK: - ScriptsTableViewController: FUIAuthViewController

extension ScriptsTableViewController: FUIAuthViewController {
    
    func refreshData() {
        fetchedResultsController = nil
        if let favoritesVC = tabBarController?.viewControllers?[1] as? FavoriteScriptsTableViewController {
            favoritesVC.fetchedResultsController = nil
        }
    }
    
    func enableUI(_ enable: Bool) {
        
        loginStackView.isHidden = enable
        scriptsTableView.isHidden = !enable
        logoutButton.isEnabled = enable
        tabBarController?.tabBar.isUserInteractionEnabled = enable
        if enable {showQuoteIfNeeded()}
    }
}

// MARK - ScriptsTableViewController (Quote display functions)

extension ScriptsTableViewController {
    
    // Auto dismiss function located at: https://stackoverflow.com/questions/33861565/how-to-show-a-message-on-screen-for-a-few-seconds
    
    func showQuoteIfNeeded() {
        
        guard !hasShownQuote else {return}
        
        QuoteClient.sharedInstance().getMovieQuote { (movieQuote, error) in
            
            performUIUpdatesOnMain {
                self.quoteScreen = ModalLoadingWindow(frame: self.view.bounds)
                self.quoteScreen!.title = movieQuote?.quote ?? "Obi-Wan has taught you well."
                self.quoteScreen!.subTitle = movieQuote?.movie ?? "Star Wars: Episode VI - Return of the Jedi"
                self.view.addSubview(self.quoteScreen!)
                
                // set the timer
                Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.dismissQuote), userInfo: nil, repeats: false)
            }
        }
    }
    
    @objc func dismissQuote(){
        // Dismiss the view from here
        quoteScreen?.hide()
        // hasShownQuote = true
    }
}
