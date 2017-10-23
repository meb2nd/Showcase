//
//  VideoViewController.swift
//  Showcase
//
//  Created by Pete Barnes on 10/23/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class VideoViewController: UIViewController {

    // MARK: Properties
    
    var video: Video!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        
        // https://stackoverflow.com/questions/25932570/how-to-play-video-with-avplayerviewcontroller-avkit-in-swift
        let fm = FileManager.default
        
        guard let documentDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let videoURLString = video.url!
        let videoURL = documentDirectory.appendingPathComponent(videoURLString)
        
        print("Trying to load video file at url = + \(videoURL)")

        let player = AVPlayer(url: videoURL)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.view.bounds
        self.view.layer.addSublayer(playerLayer)
        player.play()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
