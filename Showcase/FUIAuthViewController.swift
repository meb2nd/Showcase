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

protocol FUIAuthViewController: class {
    
    func enableUI(_ enable: Bool)
    func refreshData()
    var _authHandle: AuthStateDidChangeListenerHandle! {set get}
    var user: User? {set get}
    
}

extension FUIAuthViewController where Self: UIViewController {
    
    // MARK: Sign In and Out
    
    func signedInStatus(isSignedIn: Bool) {
        
        enableUI(isSignedIn)
        
        if (isSignedIn) {
            
           // configureDatabase()
          //  configureStorage()
           // configureRemoteConfig()
          //  fetchConfig()
        }
    }
    
    func loginSession() {
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
                if let navController = controller.navigationController,
                    navController.viewControllers.count > 1 {
                    navController.popToRootViewController(animated: true)
                }
            }
            tabBarController.selectedIndex = 0
        }
    }
    
    func configureAuth() {
        // Listen for changes in the authorization state
        _authHandle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            
            let provider: [FUIAuthProvider] = [FUIGoogleAuth()]
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
            }
        })
    }
}
