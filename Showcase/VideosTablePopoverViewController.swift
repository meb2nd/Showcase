//
//  VideosTablePopoverViewController.swift
//  Showcase
//
//  Created by Pete Barnes on 10/30/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

// Code for this class based on information from:  http://theapplady.net/show-popover-view-via-tableview-cell/
//                                                 https://stackoverflow.com/questions/39415854/how-to-play-a-looping-video-in-ios

import UIKit
import AVFoundation

class VideosTablePopoverViewController: UIViewController {
   
    // MARK: - Properties

    @objc var player: AVPlayer!
    
    // MARK: - Outlets
    

    @IBOutlet weak var videoPlayerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var videosCellSwipePlayerView: PlayerView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dontShowAnymoreButton: UIButton!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    
    // MARK: - Actions
    
    @IBAction func tappedGestureRecognizer(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func dontShowAnymore(_ sender: Any) {
        
        GeneralSettings.saveOnboardingFinished()
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if GeneralSettings.hasLaunchedVideoSwipePopoverBefore() {
            
            videoPlayerHeightConstraint.constant = 125
        } else {
            
            videoPlayerHeightConstraint.constant = 50
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedGestureRecognizer))
        view.gestureRecognizers = [tapGestureRecognizer]

        let backgroundcolor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        view.backgroundColor = backgroundcolor
        
        let bundle: Bundle = Bundle.main
        let videoPath: String = bundle.path(forResource: "video-cell-swipe", ofType: "mp4")!
        let videoURL : URL = URL(fileURLWithPath: videoPath)
        
        player = AVPlayer(url: videoURL as URL)
        player.automaticallyWaitsToMinimizeStalling = false
        videosCellSwipePlayerView.player = player
        videosCellSwipePlayerView.backgroundColor = backgroundcolor
        

        // Set the TextField's textColor, font, and text property
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 18.0)!
        titleLabel.text = " Swipe to reveal options ... "
        titleLabel.backgroundColor = UIColor.black
        
        // Set up button
        dontShowAnymoreButton.setTitle(" Don't Show Me This Again ", for: .normal)
        dontShowAnymoreButton.tintColor = UIColor.white
        dontShowAnymoreButton.backgroundColor = UIColor.red
        dontShowAnymoreButton.isHidden = !GeneralSettings.hasLaunchedVideoSwipePopoverBefore()
        
        addObserver(self, forKeyPath: #keyPath(player.currentItem.status), options: [.old, .new], context: nil)
        
    }
    
    // https://stackoverflow.com/questions/46317061/use-safe-area-layout-programmatically
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObserver(self, forKeyPath: "player.currentItem.status", context: nil)
    }
    
    // MARK: - Key-Value Observing
    // This is based on information found at: https://cocoacasts.com/key-value-observing-kvo-and-swift-3/
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(player.currentItem.status) {
            
            if let status = player.currentItem?.status,
                status == AVPlayerItemStatus.readyToPlay {
                player.play()
            }
        }
    }
}
