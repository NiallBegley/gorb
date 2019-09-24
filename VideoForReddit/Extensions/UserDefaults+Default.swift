//
//  UserDefaults+Default.swift
//  VideoForReddit
//
//  Created by Niall on 9/14/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    private enum UserDefaultStrings : String {
        case autoplay
        case subreddit
        case defaultsSet
        case fullscreen
        case oldReddit
    }
    
    func setDefaults() {
        if !getDefaultsSet() {
            setDefaultsSet(value: true)
            setSubreddit(value: "Videos")
            setAutoplay(value: true)
            setFullscreen(value: false)
            setOldReddit(value: false)
        }
    }
    
    private func getDefaultsSet() -> Bool {
        return bool(forKey: UserDefaultStrings.defaultsSet.rawValue)
    }
    
    private func setDefaultsSet(value : Bool) {
        set(value, forKey: UserDefaultStrings.defaultsSet.rawValue)
    }
    
    func getAutoplay() -> Bool {
        return bool(forKey: UserDefaultStrings.autoplay.rawValue)
    }
    
    func setAutoplay(value: Bool) {
        set(value, forKey: UserDefaultStrings.autoplay.rawValue)
    }
    
    func getFullscreen() -> Bool {
        return bool(forKey: UserDefaultStrings.fullscreen.rawValue)
    }
    
    func setFullscreen(value: Bool) {
        set(value, forKey: UserDefaultStrings.fullscreen.rawValue)
    }
    
    func setOldReddit(value: Bool) {
        set(value, forKey: UserDefaultStrings.oldReddit.rawValue)
    }
    
    func getOldReddit() -> Bool {
        return bool(forKey: UserDefaultStrings.oldReddit.rawValue)
    }
    
    func setSubreddit(value : String) {
        set(value, forKey: UserDefaultStrings.subreddit.rawValue)
    }
    
    func getSubreddit() -> String {
        if let val = string(forKey: UserDefaultStrings.subreddit.rawValue) {
            return val
        } else {
            return "Videos"
        }
    }
}
