//
//  GeneralSettings.swift
//  Showcase
//
//  Created by Pete Barnes on 10/29/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit
import FirebaseAuthUI

/// A custom object to store and retreive your settings from UserDefaults
// Based on information from the following site: http://zappdesigntemplates.com/handle-onboarding-right-in-ios-swift/

class GeneralSettings: NSObject {
    
    class func saveOnboardingFinished() {
        let uid = FUIAuth.defaultAuthUI()?.auth?.currentUser?.uid
        UserDefaults.standard.set(true, forKey: "onboarding-\(uid ?? "")")
        UserDefaults.standard.synchronize()
    }

    class func isOnboardingFinished() -> Bool {
        let uid = FUIAuth.defaultAuthUI()?.auth?.currentUser?.uid
        return UserDefaults.standard.bool(forKey: "onboarding-\(uid ?? "")")
    }
    
    class func saveHasLaunchedVideoSwipePopoverBefore() {
        let uid = FUIAuth.defaultAuthUI()?.auth?.currentUser?.uid
        UserDefaults.standard.set(true, forKey: "hasLaunchedVideoSwipePopover-\(uid ?? "")")
        UserDefaults.standard.synchronize()
    }
    
    class func hasLaunchedVideoSwipePopoverBefore() -> Bool {
        let uid = FUIAuth.defaultAuthUI()?.auth?.currentUser?.uid
        return UserDefaults.standard.bool(forKey: "hasLaunchedVideoSwipePopover-\(uid ?? "")")
    }
    
}
