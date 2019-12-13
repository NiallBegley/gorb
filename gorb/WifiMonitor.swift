//
//  WifiMonitor.swift
//  gorb
//
//  Created by Niall on 12/10/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import Foundation
import Network
import UIKit

class WifiMonitor {
    fileprivate let monitor = NWPathMonitor()
    var isExpensive = false
    
    
    init() {
        monitor.pathUpdateHandler = { path in

            if UserDefaults.standard.getWifiOnly(),
                path.isExpensive {
                
                self.isExpensive = true
//
              
            } else
            {
                self.isExpensive = false
            }
        }
        
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }
    
//    func getWifiError() -> UIAlertController {
//        let alert = UIAlertController.init(title: "Network Error", message: "You have selected Wi-Fi only playback.  Connect to a Wi-Fi network or go to the settings to change.", preferredStyle: .alert)
//        alert.addAction(UIAlertAction.init(title: "Okay", style: .default, handler: nil))
//
//        return alert
//    }
    
    func getWifiError() -> Error {
        return WifiError.noWifi
    }
}

public enum WifiError: Error {
    case noWifi
}

extension WifiError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noWifi:
            return NSLocalizedString("You have selected Wi-Fi only playback.  Connect to a Wi-Fi network or go to the settings to change.", comment: "No Wifi Error")
        }
    }
}
