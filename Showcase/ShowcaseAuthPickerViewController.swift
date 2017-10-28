//
//  ShowcaseAuthPickerViewController.swift
//  Showcase
//
//  Created by Pete Barnes on 10/26/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import UIKit
import FirebaseAuthUI

@objc(FUICustomAuthPickerViewController)

class ShowcaseAuthPickerViewController: FUIAuthPickerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let logo = UIImage(named: "Logo")
        let logoImageView = UIImageView(image: logo)
        view.addSubview(logoImageView)
        

        // Do any additional setup after loading the view.
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
