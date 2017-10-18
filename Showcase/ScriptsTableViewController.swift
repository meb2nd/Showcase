//
//  ScriptsTableViewController.swift
//  Showcase
//
//  Created by Pete Barnes on 10/17/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit
import FirebaseAuthUI

class ScriptsTableViewController: UIViewController {

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

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        configureAuth()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {

        Auth.auth().removeStateDidChangeListener(_authHandle)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
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
        
        quoteScreen = ModalLoadingWindow(frame: self.view.bounds)
        quoteScreen!.title = "Obi-Wan has taught you well."
        quoteScreen!.subTitle = "Star Wars: Episode VI - Return of the Jedi"
        self.view.addSubview(self.quoteScreen!)
        
        // set the timer
        Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.dismissQuote), userInfo: nil, repeats: false)
    }
    
    @objc func dismissQuote(){
        // Dismiss the view from here
        quoteScreen?.hide()
        hasShownQuote = true
    }
    
}

// MARK: - ScriptsTableViewController: UITableViewDataSource

extension ScriptsTableViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        
        // Configure the cell...
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
}


extension ScriptsTableViewController: UITableViewDelegate {
    
    
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
