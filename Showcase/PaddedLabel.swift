//
//  PaddedLabel.swift
//  Showcase
//
//  Created by Pete Barnes on 11/2/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//
// Class taken from infomration found at: https://stackoverflow.com/questions/27459746/adding-space-padding-to-a-uilabel

import UIKit

final class PaddedLabel: UILabel
{
    var padding: UIEdgeInsets?
    
    override func draw(_ rect: CGRect) {
        if let insets = padding {
            self.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
        } else {
            self.drawText(in: rect)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            if let insets = padding {
                contentSize.height += insets.top + insets.bottom
                contentSize.width += insets.left + insets.right
            }
            return contentSize
        }
    }
}
