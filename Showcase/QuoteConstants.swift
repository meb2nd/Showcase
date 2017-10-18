//
//  QuoteConstants.swift
//  Showcase
//
//  Created by Pete Barnes on 10/18/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

// MARK: - QuoteClient (Constants)

extension QuoteClient {
    
    // MARK: - Constants
    
    struct Constants {
        
        // MARK: URLs
        
        static let ApiScheme = "https"
        static let ApiHost = "andruxnet-random-famous-quotes.p.mashape.com"
        static let ApiPath = ""
        
    }
    
    
    // MARK: - Parameter Keys
    
    struct ParameterKeys {
        static let Category = "cat"
        static let APIKey = "X-Mashape-Key"
        static let Format = "Accept"
    }
    
    // MARK: - Parameter Values
    
    struct ParameterValues {
        static let APIKey = "xOwQiM3w7amsh5nAKmavLZoHIvE2p1jbc6hjsna7dWmSGk87S4"
        static let ResponseFormat = "application/json"
        static let Movies = "movies"
        static let Famous = "famous"
    }
    
    // MARK: - JSON Response Keys
    
    struct JSONResponseKeys {
        
        static let Quote = "quote"
        static let Author = "author"
        static let Category = "category"
    }
    
    // MARK: - Quote Response Values
    
    struct ResponseValues {
        static let Movies = "Movies"
        static let Famous = "Famous"
    }
    
}
