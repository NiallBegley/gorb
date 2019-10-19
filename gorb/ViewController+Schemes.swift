//
//  ViewController+Schemes.swift
//  gorb
//
//  Created by Niall on 10/8/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import Foundation
import UIKit

extension ViewController {
    
    // MARK: - Schemes
    
    fileprivate func createSchemeAlertAction(forRedditLink link: String, withScheme scheme : UserDefaults.LinkScheme, _ title: String, addToSchemeList currentSchemes: inout [UserDefaults.LinkScheme]) -> UIAlertAction? {
        
        if let redditScheme = URL.schemeURL(forScheme: scheme, forLink: link) {
            if UIApplication.shared.canOpenURL(redditScheme) {
                currentSchemes.append(scheme)
                return UIAlertAction.init(title: title, style: .default, handler: {(alert : UIAlertAction) in
                    UserDefaults.standard.setScheme(value: scheme)
                    UIApplication.shared.open(redditScheme, options: [:], completionHandler: nil)
                })
            }
        }
        
        return nil
    }
    
    func determineSchemes(_ permalink : String) -> UIAlertController?{
        
        let alert = UIAlertController.init(title: "Open Link", message: "Choose a default application to open these types of links going forward (this can be changed later in the settings)", preferredStyle: .actionSheet)
        
        let browserLink = (UserDefaults.standard.getOldReddit() ? "https://old.reddit.com" : "https://www.reddit.com") + permalink
        let redditLink = "www.reddit.com" + permalink


        var currentSchemes : [UserDefaults.LinkScheme] = []
        let savedSchemes = UserDefaults.standard.getAvailableSchemes()
        
        if let alertAction = createSchemeAlertAction(forRedditLink: redditLink, withScheme: .reddit, "Reddit", addToSchemeList: &currentSchemes) {
                alert.addAction(alertAction)
        }
       
        if let alertAction = createSchemeAlertAction(forRedditLink: redditLink, withScheme: .narwhal, "Narwhal", addToSchemeList: &currentSchemes) {
                alert.addAction(alertAction)
        }
        
         if let alertAction = createSchemeAlertAction(forRedditLink: redditLink, withScheme: .apollo, "Apollo", addToSchemeList: &currentSchemes) {
                alert.addAction(alertAction)
           }
        
        alert.addAction(UIAlertAction.init(title: "Safari", style: .default, handler: {(alert : UIAlertAction) in
            if let url = URL.init(string: browserLink) {
                UserDefaults.standard.setScheme(value: .safari)
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: {(alert : UIAlertAction) in
            //The user cancelled so we need to reset the schemes back to the saved ones to make sure we show this alert again
            UserDefaults.standard.setAvailableSchemes(values: savedSchemes)
        }))
        
        if !currentSchemes.elementsEqual(savedSchemes) {
            UserDefaults.standard.setAvailableSchemes(values: currentSchemes)
            return alert
        }
        
        //The available schemes didn't change, so we don't need to show this alert
        return nil
    }
}
