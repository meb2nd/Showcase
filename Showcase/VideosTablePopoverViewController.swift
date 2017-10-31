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
   
    @IBOutlet weak var videosCellSwipePlayerView: PlayerView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let backgroundcolor = UIColor(red:0.5, green:0.5, blue:0.5, alpha: 0.5)
        self.view.backgroundColor = backgroundcolor
        
        let bundle: Bundle = Bundle.main
        let videoPath: String = bundle.path(forResource: "video-cell-swipe", ofType: "mp4")!
        let videoURL : URL = URL(fileURLWithPath: videoPath)
        
        let player = AVPlayer(url: videoURL as URL)
        videosCellSwipePlayerView.player = player
        videosCellSwipePlayerView.backgroundColor = backgroundcolor
        player.play()
        loopVideo(videoPlayer: player)

        // Set the TextField's textColor, font, and text property
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 18.0)!
        titleLabel.text = " Swipe to reveal options ... "
        titleLabel.backgroundColor = UIColor.black

    }

    func loopVideo(videoPlayer: AVPlayer) {
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { notification in
            
            videoPlayer.seek(to: kCMTimeZero)
            videoPlayer.play()
        }
    }
}
