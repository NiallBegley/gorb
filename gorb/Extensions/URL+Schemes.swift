//
//  URL+Schemes.swift
//  gorb
//
//  Created by Niall on 9/13/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import UIKit

extension URL {

    static func schemeURL(forScheme scheme : UserDefaults.LinkScheme, forLink redditLink : String) -> URL? {
        
        var schemeIdentifier = ""
        
        switch scheme {
            case .apollo:
                schemeIdentifier = "apollo://"
                break;
            
            case .reddit:
                schemeIdentifier = "reddit://"
                break;
            
            case .narwhal:
                schemeIdentifier = "narwhal://open-url/"
                break;
            
            default:
                break;
        }
        
        return schemeIdentifier.isEmpty ? nil : URL.init(string: schemeIdentifier + redditLink)
    }
    
    static func openURL(string : String) {
        let browserLink = (UserDefaults.standard.getOldReddit() ? "https://old.reddit.com" : "https://www.reddit.com") + string
        let redditLink = "www.reddit.com" + string
        
        if let url = schemeURL(forScheme: UserDefaults.standard.getScheme(), forLink: redditLink) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else if let url = URL.init(string: browserLink) {
           UIApplication.shared.open(url, options: [:], completionHandler: nil)
       }
    }
    
}
