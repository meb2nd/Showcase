//
//  StoryboardManager
//  Showcase
//
//  Created by Pete Barnes on 10/29/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//
// Code base on information loacted at:  http://zappdesigntemplates.com/handle-onboarding-right-in-ios-swift/

import UIKit

class StoryboardManager {
    class func videosTablePopoverViewController() -> VideosTablePopoverViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideosTablePopoverViewController") as! VideosTablePopoverViewController
    }
}
