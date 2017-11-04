//
//  ViewControllerExtensions.swift
//  Showcase
//
//  Created by Pete Barnes on 10/17/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit
import FirebaseAuthUI

// MARK: - UIViewController (Common functions)

extension UIViewController {
    
    func logoutSession() {
        
        let alert = UIAlertController(title: "Logout Confirmation", message: "Are you sure you want to Logout?", preferredStyle: .actionSheet)
        
        let LogoutAction = UIAlertAction(title: "Yes", style: .destructive, handler: handleLogout)
        
        let CancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        alert.addAction(LogoutAction)
        alert.addAction(CancelAction)
        
        // Support display in iPad
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.size.width / 2.0, y: view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        present(alert, animated: true, completion: nil)
    }
    
    func handleLogout(alertAction: UIAlertAction!) -> Void {
        do {
            GeneralSettings.resetHasShownQuote()
            try Auth.auth().signOut()
        } catch {
            print("Unable to sign out: \(error)")
        }
    }
    
    func setNavigationBarColors() {
        
        let barColor =  UIColor(red: 0.898, green: 0.898, blue: 0.898, alpha: 1.0)
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = barColor
        navigationController?.toolbar.barTintColor = barColor
    }
    
    func enableTabBar(_ isEnabled: Bool) {
        
        if  let arrayOfTabBarItems = self.tabBarController?.tabBar.items {
            
            for tabBarItem in arrayOfTabBarItems {
                tabBarItem.isEnabled = isEnabled
            }
        }
    }
}
