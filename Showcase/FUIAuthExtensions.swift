//
//  FUIAuthExtensions.swift
//  Showcase
//
//  Created by Pete Barnes on 11/3/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import FirebaseAuthUI
import UIKit



// MARK: - UIViewController: FUIAuthDelegate

// This is based on information found at: https://github.com/firebase/FirebaseUI-iOS/tree/5ed77bced4552bdff7aaf41e8b95bba5f84d4e40/samples/swift
extension UIViewController: FUIAuthDelegate {
    
    public func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        guard let authError = error else { return }
        
        let errorCode = UInt((authError as NSError).code)

        if errorCode == FUIAuthErrorCode.userCancelledSignIn.rawValue {
            print("User cancelled sign-in");
            return
        }
        
        if let errorCode = AuthErrorCode(rawValue: authError._code) {
            
            AlertViewHelper.presentAlert(self, title: "Login Error", message: errorCode.errorMessage)
        }
    }
    
    public func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
        return ShowcaseAuthPickerViewController(nibName: "ShowcaseAuthPickerViewController",
                                                bundle: Bundle.main,
                                                authUI: authUI)
    }
}

// MARK:  - AuthErrorCode
// Code below based on information found at:  https://stackoverflow.com/questions/39054162/handling-errors-in-new-firebase-and-swift

extension AuthErrorCode {
    var errorMessage: String {
        switch self {
        case .emailAlreadyInUse:
            return "The email is already in use with another account."
        case .userDisabled:
            return "Your account has been disabled. Please contact support."
        case .invalidEmail, .invalidSender, .invalidRecipientEmail:
            return "Please enter a valid email."
        case .networkError:
            return "Network error. Please try again."
        case .weakPassword:
            return "Your password is too weak."
        default:
            print("Login error: \(self)")
            return "Unknown error occurred."
        }
    }
}
