//
//  ModalLoadingWindow.swift
//  Showcase
//
//  Created by Pete Barnes on 10/18/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

// The code for this class is from:  http://www.byteblocks.com/Post/Modal-Loading-Indicator-View-Implementation-In-iOS

import Foundation
import UIKit
public class ModalLoadingWindow: UIView{
    var overlayWindow: UIView?
    var infoStackWindow: UIStackView?
    var titleLabel: UILabel?
    var subTitleLabel: UILabel?
    var activityIndicator: UIActivityIndicatorView?
    var progressView: UIProgressView?
    public var title:String = "Loading..."{
        didSet{
            if let label = titleLabel{
                label.text = title
                setNeedsLayout()
            }
        }
    }
    
    public var subTitle:String? {
        didSet{
            if let label = subTitleLabel{
                label.text = subTitle
                setNeedsLayout()
            }
        }
    }
    
    func initialize(){
        backgroundColor = UIColor.black
        alpha = 0.5
        clipsToBounds = true
        
        overlayWindow = UIView(frame: bounds)
        overlayWindow!.translatesAutoresizingMaskIntoConstraints = false
        overlayWindow!.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        createInformationStackView()
        overlayWindow!.addSubview(infoStackWindow!)
        addSubview(overlayWindow!)
        addViewConstraints()
    }
    
    func createInformationStackView(){
        infoStackWindow = UIStackView()
        infoStackWindow!.backgroundColor = UIColor.red
        infoStackWindow!.axis = .vertical
        infoStackWindow!.alignment = .center
        infoStackWindow!.distribution = .fill
        infoStackWindow!.spacing = 8.0
        infoStackWindow!.translatesAutoresizingMaskIntoConstraints = false
        infoStackWindow!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        createActivityIndicator()
        createTitle()
        createSubtitle()
        createProgressView()
        
        infoStackWindow!.addArrangedSubview(activityIndicator!)
        infoStackWindow!.addArrangedSubview(titleLabel!)
        infoStackWindow!.addArrangedSubview(subTitleLabel!)
        infoStackWindow!.addArrangedSubview(progressView!)
    }
    
    func createTitle(){
        titleLabel = UILabel(frame: CGRect(x:0, y:0, width: frame.width, height: 20))
        titleLabel!.text = title
        titleLabel!.textColor = UIColor.white
        titleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        titleLabel!.textAlignment = .center
        
        // Following lines added to permit word wrapping
        titleLabel!.numberOfLines = 0
        titleLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        titleLabel?.preferredMaxLayoutWidth = frame.width
        
        titleLabel!.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func createSubtitle(){
        subTitleLabel = UILabel(frame: CGRect(x:0, y:0, width: frame.width, height: 20))
        subTitleLabel!.textColor = UIColor.white
        subTitleLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.subheadline)
        subTitleLabel!.text = subTitle
        subTitleLabel!.textAlignment = .center
        subTitleLabel!.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func createActivityIndicator(){
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator!.startAnimating()
        activityIndicator!.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func createProgressView(){
        progressView = UIProgressView(progressViewStyle: .default)
        progressView!.progress = 0.0
        progressView!.isHidden = true
        progressView!.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func addViewConstraints(){
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addConstraintsForOverlay()
        addConstraintsForStackView()
        addConstraintsForProgressView()
    }
    
    func addConstraintsForOverlay(){
        overlayWindow?.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        overlayWindow?.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        overlayWindow?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        overlayWindow?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    func addConstraintsForStackView(){
        let xCenterConstraint = NSLayoutConstraint(item: infoStackWindow!, attribute: .centerX,
                                                   relatedBy: .equal, toItem: infoStackWindow!.superview,
                                                   attribute: .centerX, multiplier: 1, constant: 0)
        overlayWindow!.addConstraint(xCenterConstraint)
        
        let yCenterConstraint = NSLayoutConstraint(item: infoStackWindow!, attribute: .centerY,
                                                   relatedBy: .equal, toItem: infoStackWindow!.superview,
                                                   attribute: .centerY, multiplier: 1, constant: 0)
        overlayWindow!.addConstraint(yCenterConstraint)
    }
    
    func addConstraintsForProgressView() {
        let leadingConstraint = NSLayoutConstraint(item: progressView!, attribute: .leading,
                                                   relatedBy: .equal, toItem: infoStackWindow,
                                                   attribute: .leading, multiplier: 1, constant: 20)
        overlayWindow!.addConstraint(leadingConstraint)
        
        let trailingConstraint = NSLayoutConstraint(item: progressView!, attribute: .trailing,
                                                   relatedBy: .equal, toItem: infoStackWindow,
                                                   attribute: .trailing, multiplier: 1, constant: -20)
        overlayWindow!.addConstraint(trailingConstraint)
    }
    
    public func hide(){
        removeFromSuperview()
    }
    
    override public func layoutSubviews() {
        //NOTE: Add code if some last minute layout changes are needed
    }
    
    required public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
