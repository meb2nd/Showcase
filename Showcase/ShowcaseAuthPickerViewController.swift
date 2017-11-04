//
//  ShowcaseAuthPickerViewController.swift
//  Showcase
//
//  Created by Pete Barnes on 10/26/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit
import FirebaseAuthUI

@objc(ShowcaseAuthPickerViewController)

class ShowcaseAuthPickerViewController: FUIAuthPickerViewController {
    
    @IBOutlet weak var logoImageView: UIImageView!
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        super.traitCollectionDidChange(previousTraitCollection)
        
        if ((self.traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass)
            || (self.traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass)) {
            
            if self.traitCollection.verticalSizeClass == .compact {
                logoImageView.alpha = 0.5
            } else {
                logoImageView.alpha = 1.0
            }
        }
    }
}
