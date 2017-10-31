//
//  PlayerView.swift
//  Showcase
//
//  Created by Pete Barnes on 10/30/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

// Code based on information found at:

import UIKit
import AVFoundation

class PlayerView: UIView {
    
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        
        set {
            playerLayer.player = newValue
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override public class var layerClass:Swift.AnyClass {
        get {
            return AVPlayerLayer.self
        }
    }
    
}
