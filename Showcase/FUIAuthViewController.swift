//
//  FUIAuthViewController.swift
//  Showcase
//
//  Created by Pete Barnes on 10/17/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import FirebaseFacebookAuthUI

protocol FUIAuthViewController: class {
    
    func enableUI(_ enable: Bool)
    func refreshData()
    var _authHandle: AuthStateDidChangeListenerHandle! {set get}
    var user: User? {set get}
    var userName: String {set get}
    
}

extension FUIAuthViewController where Self: UIViewController {
    
    // MARK: Sign In and Out
    
    func signedInStatus(isSignedIn: Bool) {
        
        enableUI(isSignedIn)
        
        if (isSignedIn) {
            
            FIRDatabaseClient.sharedInstance.configureDatabase()
            FIRDatabaseClient.sharedInstance.configureStorage()
        }
    }
    
    func loginSession() {
        FUIAuth.defaultAuthUI()?.delegate = self
        let authViewController = FUIAuth.defaultAuthUI()!.authViewController()
        self.present(authViewController, animated: true, completion: nil)
    }
}

//MARK : - FUIAuthViewController (Config Auth)
extension FUIAuthViewController where Self: UIViewController {

    fileprivate func resetTabBar() {
        
        if let tabBarController = self.tabBarController,
            let controllers = tabBarController.viewControllers {
            for controller in controllers {
                if let navController = controller as? UINavigationController,
                    navController.viewControllers.count > 1 {
                    // Need pop to root without animation to prevent issue with setting tab bar controller
                    // https://stackoverflow.com/questions/21681185/tabbar-disappears-when-selectedindex-value-changes-on-ios-7
                    navController.popToRootViewController(animated: false)
                }
            }
            
            tabBarController.selectedIndex = 0
        }
    }
    
    func configureAuth() {
        
        // Listen for changes in the authorization state
        _authHandle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            
            let provider: [FUIAuthProvider] = [FUIFacebookAuth(), FUIGoogleAuth()]
            FUIAuth.defaultAuthUI()?.providers = provider
            
            self.refreshData()
            
            // Check to see if there is a current user
            guard let activeUser = user else {
                
                // User must sign in
                self.resetTabBar()
                self.signedInStatus(isSignedIn: false)
                self.loginSession()
                return
            }
            
            // Check to see if the current user is the current FIRUser
            if self.user != activeUser {
                
                self.resetTabBar()
                self.user = activeUser
                self.signedInStatus(isSignedIn: true)

                if let name = user!.email?.components(separatedBy: "@")[0] {
                    self.userName = name
                } else if let displayName = user?.displayName {
                    self.userName = displayName
                } else {
                    self.userName = "Anonymous"
                }
            }
        })
    }
}
