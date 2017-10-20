//
//  FUIAuthViewClient.swift
//  Showcase
//
//  Created by Pete Barnes on 10/20/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import Foundation
import Firebase

protocol FUIAuthViewClient: class {
    
    var user: User? {set get}
    var userName: String {set get}
    
}
