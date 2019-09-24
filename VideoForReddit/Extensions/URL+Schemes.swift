//
//  URL+Schemes.swift
//  VideoForReddit
//
//  Created by Niall on 9/13/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import UIKit

extension URL {

    enum SupportedSchemes {
        case reddit
        case apollo
        case narwhal
    }
    
    static func openURL(string : String) -> UIAlertController? {
        let alert = UIAlertController.init(title: "Open Link", message: "Choose a default application to open these types of links going forward (this can be changed later in the settings)", preferredStyle: .actionSheet)
        
        let redditLink = (UserDefaults.standard.getOldReddit() ? "http://old.reddit.com" : "www.reddit.com") + string
        var capabilities = [SupportedSchemes]()
        
        if let redditScheme = URL.init(string: "reddit://" + redditLink) {
            if UIApplication.shared.canOpenURL(redditScheme) {
                capabilities.append(.reddit)
                alert.addAction(UIAlertAction.init(title: "Reddit", style: .default, handler: {(alert : UIAlertAction) in
                    UIApplication.shared.open(redditScheme, options: [:], completionHandler: nil)
                }))
            }
        }
        
        if let narwhalScheme = URL.init(string: "narwhal://open-url/" + redditLink) {
            if UIApplication.shared.canOpenURL(narwhalScheme) {
                capabilities.append(.narwhal)
                alert.addAction(UIAlertAction.init(title: "Narwhal", style: .default, handler: {(alert : UIAlertAction) in
                    UIApplication.shared.open(narwhalScheme, options: [:], completionHandler: nil)
                }))
            }
        }
        
        if let apolloScheme = URL.init(string: "apollo://" + redditLink) {
            if UIApplication.shared.canOpenURL(apolloScheme) {
                capabilities.append(.apollo)
                alert.addAction(UIAlertAction.init(title: "Apollo", style: .default, handler: {(alert : UIAlertAction) in
                    UIApplication.shared.open(apolloScheme, options: [:], completionHandler: nil)
                }))
            }
        }
        
        alert.addAction(UIAlertAction.init(title: "Safari", style: .default, handler: {(alert : UIAlertAction) in
            if let url = URL.init(string: redditLink) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
        
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
//        if let existingCapabilities = UserDefaults.standard.array(forKey: "schemes") as? [SupportedSchemes] {
//            if existingCapabilities == capabilities {
//                if let url = URL.init(string: redditLink) {
//                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
//                }
//                return nil
//            }
//        } else {
//            UserDefaults.standard.set(capabilities, forKey: "schemes")
//        }
        
        return alert
        
    }
}
