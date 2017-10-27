//
//  VideoManager.swift
//  Showcase
//
//  Created by Pete Barnes on 10/26/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import Foundation
import FirebaseAuth

class VideoManager {
    
    static let sharedInstance = VideoManager()
    
    private init() {}
    
    func delete(video: Video) {
        
        let fm = FileManager.default
        
        guard  let videoURLString = video.url,
            
            let documentDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask).first  else {
                return
            }
            
            let videoURL = documentDirectory.appendingPathComponent(videoURLString)
            
            print("Trying to delete video file at url = + \(videoURL)")
            
            do {
                try fm.removeItem(at: videoURL)
            } catch {
                print("Failed to delete video file at url = + \(videoURL)")
            }
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.stack.context
            
            if let video = context.object(with: video.objectID) as? Video {
                
                context.delete(video)
                
                context.performAndWait {
                    do {
                        if context.hasChanges {
                            try context.save()
                        }
                    } catch {
                        print(error)
                    }
                }
            }
    }
    
    func saveVideo(atURL videoURL: URL, forScript script: Script) {
        
        let fm = FileManager.default
        
        guard let documentDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        // https://stackoverflow.com/questions/41162610/create-directory-in-swift-3-0
        let videoPath = "showcase_videos/" + Auth.auth().currentUser!.uid
        let videoDirectory = documentDirectory.appendingPathComponent(videoPath)
        let videoURLString = videoPath + "/\(Double(Date.timeIntervalSinceReferenceDate * 1000)).MOV"
        let url = documentDirectory.appendingPathComponent(videoURLString)
        
        if !fm.fileExists(atPath: videoDirectory.path) {
            do {
                try fm.createDirectory(atPath: videoDirectory.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Couldn't create document directory")
            }
        }
        
        print("Document directory is \(videoDirectory)")
        
        do {
            try fm.moveItem(at: videoURL, to: url)
            print("Moved the movie file from the temporary directory.")
            print("New location is: \(url)")
        } catch {
            let saveError = error as NSError
            print("Failed to move the movie file from the temporary directory.")
            print("\(saveError), \(saveError.localizedDescription)")
            return
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stack = appDelegate.stack
        
        stack.performBackgroundBatchOperation() { (workerContext) in
            
            let backgroundScript = workerContext.object(with: script.objectID) as! Script
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            
            workerContext.performAndWait {
                _ = Video(title: backgroundScript.title! + " - \(dateFormatter.string(from: Date()))",
                    script: backgroundScript,
                    url: videoURLString,
                    insertInto: workerContext)
            }
            
            do {
                if workerContext.hasChanges {
                    try workerContext.save()
                }
            } catch {
                let saveError = error as NSError
                print("Unable to Save Video")
                print("\(saveError), \(saveError.localizedDescription)")
            }
        }
    }
}
