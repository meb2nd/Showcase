//
//  QuoteClient.swift
//  Showcase
//
//  Created by Pete Barnes on 10/18/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import Foundation

struct MovieQuote {
    
    // MARK: - Properties
    
    let quote: String
    let movie: String
}

final class QuoteClient : NSObject {
    
    // MARK: - Properties
    
    // shared session
    var session = URLSession.shared
    
    // NetworkClient
    let scheme = QuoteClient.Constants.ApiScheme
    let host = QuoteClient.Constants.ApiHost
    let path = QuoteClient.Constants.ApiPath
    
    // MARK: - Initializers
    
    override init() {
        super.init()
    }
    
    // MARK: - HTTP Tasks
    
    func taskForGETMethod(_ method: String, parameters: [String: String?], completionHandlerForGET: @escaping (_ result: AnyObject?, _ error: APIError?) -> Void) -> URLSessionDataTask {
        
        /* 1. Set the common parameters */
        let headers = [ParameterKeys.APIKey: ParameterValues.APIKey,
                       ParameterKeys.Format: ParameterValues.ResponseFormat]
        
        
        /* 2/3. Build the URL, Configure the request */
        let request = buildTheURL(method, parameters: parameters, headers: headers as [String : AnyObject])
        
        
        /* 4. Make the request */
        return makeTheTask(request: request as URLRequest, errorDomain: "QuoteClient.taskForGETMethod", completionHandler: completionHandlerForGET)
        
    }
    
    func getMovieQuote (_ completion: @escaping (_ quote: MovieQuote?, _ error: APIError?) -> Void) {
        
        let parameters = [ParameterKeys.Category: ParameterValues.Movies]
        
        _ = taskForGETMethod("", parameters: parameters){ (result, error) in
            
            guard (error == nil) else {
                
                print("There was an error in the request: \(String(describing: error))")
                completion(nil, error)
                return
            }
            
            /* GUARD: Did request return a movie quote */
            guard let cat = result?[JSONResponseKeys.Category] as? String, cat == ResponseValues.Movies else {
                
                print("Response did ot return a movie quote: \(String(describing: result))")
                completion(nil, APIError.jsonMappingError(converstionError: DecodeError.custom("Did not get a movie quote.")))
                return
            }
            
            /* GUARD: Is "quote" key in our result? */
            guard let quote = result?[JSONResponseKeys.Quote] as? String else {
                
                print("Cannot find key '\(JSONResponseKeys.Quote)' in \(String(describing: result))")
                completion(nil, APIError.jsonMappingError(converstionError: DecodeError.missingKey(JSONResponseKeys.Quote)))
                return
            }
            
            /* GUARD: Is "author" key in our result? */
            guard let movie = result?[JSONResponseKeys.Author] as? String else {
                
                print("Cannot find key '\(JSONResponseKeys.Author)' in \(String(describing: result))")
                completion(nil, APIError.jsonMappingError(converstionError: DecodeError.missingKey(JSONResponseKeys.Author)))
                return
            }
            
            let movieQuote = MovieQuote(quote: quote, movie: movie)
            
            completion(movieQuote, nil)
        }
    }
    

    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> QuoteClient {
        struct Singleton {
            static var sharedInstance = QuoteClient()
        }
        return Singleton.sharedInstance
    }
}

// MARK: - FlickrClient: NetworkClient

extension QuoteClient: NetworkClient {
    
    func preprocessData (data: Data) -> Data {
        return data
    }
}

