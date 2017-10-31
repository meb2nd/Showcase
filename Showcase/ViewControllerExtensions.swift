//
//  ViewControllerExtensions.swift
//  Showcase
//
//  Created by Pete Barnes on 10/17/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit
import FirebaseAuthUI

extension UIViewController {
    
    func logoutSession() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("unable to sign out: \(error)")
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

// https://github.com/firebase/FirebaseUI-iOS/tree/5ed77bced4552bdff7aaf41e8b95bba5f84d4e40/samples/swift
extension UIViewController: FUIAuthDelegate {
    
    public func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        guard let authError = error else { return }
        
        let errorCode = UInt((authError as NSError).code)
        
        switch errorCode {
        case FUIAuthErrorCode.userCancelledSignIn.rawValue:
            print("User cancelled sign-in");
            break
        default:
            let detailedError = (authError as NSError).userInfo[NSUnderlyingErrorKey] ?? authError
            print("Login error: \((detailedError as! NSError).localizedDescription)");
        }
    }
    
    
    public func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
        return ShowcaseAuthPickerViewController(nibName: "ShowcaseAuthPickerViewController",
                                                bundle: Bundle.main,
                                                authUI: authUI)
    }
}
