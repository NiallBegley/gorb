//
//  UserDefaults+Default.swift
//  gorb
//
//  Created by Niall Begley on 11/26/22.
//

import Foundation

struct Subreddit: Identifiable, Hashable, Codable {
    var name: String
    var id: String {
        name.lowercased()
    }
}

class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    @Published var subreddit: Subreddit {
        didSet {
            UserDefaults.standard.set(subreddit.name, forKey: UserDefaultStrings.subreddit.rawValue)
        }
    }

    @Published var subreddits: [Subreddit] {
        didSet {
            UserDefaults.standard.set(subreddits, forKey: UserDefaultStrings.subreddits.rawValue)
        }
    }

    @Published var autoplay: Bool {
        didSet {
            UserDefaults.standard.set(autoplay, forKey: UserDefaultStrings.autoplay.rawValue)
        }
    }


    init() {
        let subreddit = UserDefaults.standard.string(forKey: UserDefaultStrings.subreddit.rawValue) ?? "Videos"
        self.subreddit = Subreddit(name: subreddit)

        let subreddits = UserDefaults.standard.object(forKey: UserDefaultStrings.subreddits.rawValue) as? [String] ?? ["Videos", "YoutubeHaiku", "MealtimeVideos", "Games", "ArtisanVideos"]
        self.subreddits = subreddits.map({Subreddit(name: $0)})
        self.autoplay = UserDefaults.standard.bool(forKey: UserDefaultStrings.autoplay.rawValue)
    }

    enum LinkScheme : Int {
        case unknown
        case reddit
        case apollo
        case narwhal
        case safari
    }

    private enum UserDefaultStrings : String {
        case autoplay
        case subreddit
        case defaultsSet
        case fullscreen
        case oldReddit
        case scheme
        case availableSchemes
        case subreddits
        case wifiOnly
    }

//    func setDefaults() {
//        if !getDefaultsSet() {
//            setDefaultsSet(value: true)
//            setSubreddit(value: "Videos")
//            setAutoplay(value: true)
//            setFullscreen(value: false)
//            setOldReddit(value: false)
//            setDefaultSubreddits()
//            setWifiOnly(value: false)
//            clearSchemes()
//        }
//    }
//
//    private func getDefaultsSet() -> Bool {
//        return bool(forKey: UserDefaultStrings.defaultsSet.rawValue)
//    }
//
//    private func setDefaultsSet(value : Bool) {
//        set(value, forKey: UserDefaultStrings.defaultsSet.rawValue)
//    }
//
//    func setDefaultSubreddits() {
//        set(, forKey: UserDefaultStrings.subreddits.rawValue)
//    }
//    func getSubreddits() -> [String] {
//        let subreddits =  array(forKey: UserDefaultStrings.subreddits.rawValue) as? [String] ?? [String]()
//        return subreddits
//    }
//
//    func setSubreddits(value: [String]) {
//        set(value, forKey: UserDefaultStrings.subreddits.rawValue)
//    }
//
//    func clearSchemes() {
//        setScheme(value: .unknown)
//        setAvailableSchemes(values: [])
//    }
//    func getScheme() -> LinkScheme {
//        let val =  integer(forKey: UserDefaultStrings.scheme.rawValue)
//        return LinkScheme(rawValue: val) ?? .unknown
//    }
//
//    func setScheme(value : LinkScheme) {
//        set(value.rawValue, forKey: UserDefaultStrings.scheme.rawValue)
//    }
//
//    func getAvailableSchemes() -> [LinkScheme] {
//        let schemes = array(forKey: UserDefaultStrings.availableSchemes.rawValue) as? [Int] ?? [Int]()
//
//        let schemeEnums = schemes.map{(rawValue) -> LinkScheme in
//            return (LinkScheme(rawValue: rawValue) ?? .unknown)
//        }
//        return schemeEnums
//    }
//
//    func setAvailableSchemes(values : [LinkScheme]) {
//        let rawvals = values.map{(val) -> Int in
//            return val.rawValue
//        }
//        set(rawvals, forKey: UserDefaultStrings.availableSchemes.rawValue)
//    }
//
//    func getAutoplay() -> Bool {
//        return bool(forKey: UserDefaultStrings.autoplay.rawValue)
//    }
//
//    func setAutoplay(value: Bool) {
//        set(value, forKey: UserDefaultStrings.autoplay.rawValue)
//    }
//
//    func getFullscreen() -> Bool {
//        return bool(forKey: UserDefaultStrings.fullscreen.rawValue)
//    }
//
//    func setFullscreen(value: Bool) {
//        set(value, forKey: UserDefaultStrings.fullscreen.rawValue)
//    }
//
//    func setOldReddit(value: Bool) {
//        set(value, forKey: UserDefaultStrings.oldReddit.rawValue)
//    }
//
//    func getOldReddit() -> Bool {
//        return bool(forKey: UserDefaultStrings.oldReddit.rawValue)
//    }
//
//    func setSubreddit(value : String) {
//        set(value, forKey: UserDefaultStrings.subreddit.rawValue)
//    }
//
//    func getSubreddit() -> String {
//        if let val = string(forKey: UserDefaultStrings.subreddit.rawValue) {
//            return val
//        } else {
//            return "Videos"
//        }
//    }
//
//    func setWifiOnly(value: Bool) {
//        set(value, forKey: UserDefaultStrings.wifiOnly.rawValue)
//    }
//
//    func getWifiOnly() -> Bool {
//        return bool(forKey: UserDefaultStrings.wifiOnly.rawValue)
//    }
}
