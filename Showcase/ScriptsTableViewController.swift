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
    
    var user: User?
    var userName = "Anonymous"
    var _authHandle: AuthStateDidChangeListenerHandle!
    var hasShownQuote = false
    var quoteScreen: ModalLoadingWindow?
    
    // MARK: - Outlets
    
    @IBOutlet weak var loginStackView: UIStackView!
    @IBOutlet weak var scriptsTableView: UITableView!
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //sectionNameKeyPath: #keyPath(Quote.author)
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Script")
        fr.sortDescriptors = [NSSortDescriptor(key: "genre", ascending: true),
                              NSSortDescriptor(key: "title", ascending: true),
                              NSSortDescriptor(key: "dateCreated", ascending: false)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: #keyPath(Script.genre), cacheName: nil)
        
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
    
    // Pass tableview to super class
    override func getTableView() -> UITableView {
        return scriptsTableView
    }
    
    // MARK: Actions
    
    @IBAction func showLoginView(_ sender: Any) {
        loginSession()
    }
    

    @IBAction func signOut(_ sender: Any) {
        logoutSession()
    }
    
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
    
    // MARK: - ScriptsTableViewController: UITableViewDataSource

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let script = fetchedResultsController!.object(at: indexPath) as! Script
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScriptCell", for: indexPath)

        cell.textLabel?.text = script.title
        cell.detailTextLabel?.text = "Gender: \(script.gender?.capitalized ?? " ")"
        
        return cell
    }
    
    /*
     // Override to support conditional editing of the table view.
     func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
}

// MARK: - ScriptsTableViewController: FUIAuthViewController 
extension ScriptsTableViewController: FUIAuthViewController {
    
    func refreshData() {
        
    }
    
    func enableUI(_ enable: Bool) {
        
        loginStackView.isHidden = enable
        scriptsTableView.isHidden = !enable
        logoutButton.isEnabled = enable
        tabBarController?.tabBar.isUserInteractionEnabled = enable
        if enable {showQuoteIfNeeded()}
    }
}
