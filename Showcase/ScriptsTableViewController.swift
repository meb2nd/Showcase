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
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var noScriptsLabel: UILabel!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureAuth()
        setNavigationBarColors()
        
        // Table set up based on code found at:  https://grokswift.com/transparent-table-view/
        //                                      https://stackoverflow.com/questions/28532926/if-no-table-view-results-display-no-results-on-screen
        // no lines where there aren't cells
        scriptsTableView.tableFooterView = UIView(frame: CGRect.zero)
        scriptsTableView.backgroundView = backgroundView

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
        
        // Information abut custom disclosure found at:  https://medium.com/@ronm333/changing-the-color-of-a-disclosure-indicator-666a7fdd9286
        cell.accessoryType = .disclosureIndicator
        cell.accessoryView = UIImageView(image: UIImage(named: "chevron.png"))
        
        return cell
    }
    
    // Only show index if number of fetched objects exceed visible table rows
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if let fc = fetchedResultsController,
            let fetchedObjectCount = fc.fetchedObjects?.count {
            return fetchedObjectCount > estimatedMaxVisibleCellCount() ? fc.sectionIndexTitles: nil
        } else {
            return nil
        }
    }
    
    fileprivate func estimatedMaxVisibleCellCount() -> Int {
        
        var estimatedMaxVisibleCellCount = 0
        
        if let fc = fetchedResultsController,
            let sectionsCount = fc.sections?.count {
            
            let estimatedTableHeight = view.safeAreaLayoutGuide.layoutFrame.size.height
            let estimatedRowHeight: CGFloat = 44.0
            let estimatedHeaderHeight: CGFloat = 22.0
            let numberOfSections = CGFloat(sectionsCount)
            estimatedMaxVisibleCellCount = Int((estimatedTableHeight - numberOfSections * (estimatedHeaderHeight + estimatedRowHeight))/estimatedRowHeight)
            
            if estimatedMaxVisibleCellCount < 0 {
                estimatedMaxVisibleCellCount = Int(estimatedTableHeight/(estimatedHeaderHeight + estimatedRowHeight))
            }
        }
        
        return estimatedMaxVisibleCellCount
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
                Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.dismissQuote), userInfo: nil, repeats: false)
            }
        }
    }
    
    @objc func dismissQuote(){
        // Dismiss the view from here
        quoteScreen?.hide()
        // hasShownQuote = true
    }
}

// MARK: - ScriptsTableViewController: UITableViewDelegate

extension ScriptsTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        setBackgroundColor(forCell: cell)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let returnedView = UIView()
        returnedView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.7)

        let label = PaddedLabel(frame: CGRect(x:0, y:0, width: tableView.frame.size.width, height: 20))
        label.text = fetchedResultsController?.sections![section].name.capitalized
        label.padding = UIEdgeInsets(top: 5, left: 5, bottom: 2, right: 0)
        returnedView.addSubview(label)
        
        return returnedView
    }
}

