//
//  TopMostViewController.swift
//  Showcase
//
//  Created by Pete Barnes on 11/5/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit

// Based on code found at:  https://gist.github.com/db0company/369bfa43cb84b145dfd8

extension UIViewController {
    func topMostViewController() -> UIViewController? {
        if self.presentedViewController == nil {
            return self
        }
        if let navigation = self.presentedViewController as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController()
        }
        if let tab = self.presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        return self.presentedViewController!.topMostViewController()
    }
}

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        return self.keyWindow?.rootViewController?.topMostViewController()
    }
}
