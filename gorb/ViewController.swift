//
//  ViewController.swift
//  gorb
//
//  Created by Niall on 9/7/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import UIKit
import YoutubePlayer_in_WKWebView
import CoreData
import ChameleonFramework
import Network
import CocoaLumberjack

class ViewController: UIViewController, VideoControllerDelegate, WKYTPlayerViewDelegate, SettingsDelegate {
    @IBOutlet weak var progressView: UIActivityIndicatorView!
    @IBOutlet weak var tryAgainButton: UIButton!
    @IBOutlet weak var playerView: WKYTPlayerView!
    @IBOutlet weak var noVideosLabel: UILabel!
    var persistentContainer: NSPersistentContainer?
    fileprivate var videoController : VideoController?
    fileprivate var videos : [Video] = []
    fileprivate var index = 0
    var autoplay = false
    weak var tableViewController : VideoTableViewController?
    fileprivate let wifiMonitor = WifiMonitor.init()
    fileprivate var refreshing = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        DDLogDebug("viewDidLoad")
        
        super.viewDidLoad()
        
        if let persistentContainer = self.persistentContainer {
            self.videoController = VideoController.init(container: persistentContainer)
            self.videoController?.delegate = self
        }
        
        UserDefaults.standard.setDefaults()
        
        playerView.delegate = self
        
        let left = UISwipeGestureRecognizer(target: self, action: #selector(userSwiped(_:)))
        let right = UISwipeGestureRecognizer(target: self, action: #selector(userSwiped(_:)))
        
        left.direction = .left
        right.direction = .right
        
        view.addGestureRecognizer(left)
        view.addGestureRecognizer(right)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        view.backgroundColor = UIColor.black
        
        if !wifiMonitor.isExpensive {
            DDLogDebug("Internet isn't expensive")
            refreshAllVideos()
        } else {
            DDLogDebug("Internet IS expensive")
            finishedRefresh(error: wifiMonitor.getWifiError())
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        DDLogDebug("viewDidAppear")
        view.backgroundColor = UIColor.black
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        DDLogDebug("Performing \(String(describing: segue.identifier)) segue")
        if segue.identifier == "SETTINGS_SEGUE",
            let vc = segue.destination as? SettingsTableViewController {
                view.backgroundColor = UIColor.white
                vc.delegate = self
        } else if segue.identifier == "TABLE_VIEW_EMBED_SEGUE",
            let vc = segue.destination as? VideoTableViewController {
                tableViewController = vc
            tableViewController?.parentController = self
                
            }
    }
    
    override func didReceiveMemoryWarning() {
        DDLogDebug("didReceiveMemoryWarning")
        videoController?.cancelRefresh()
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Interaction Callbacks
    func refreshAllVideos() {
        DDLogDebug("refreshAllVideos")
        
        if !wifiMonitor.isExpensive {
            refreshing = true
            _ = videoController?.deleteAll()
            videoController?.refreshVideos()
        } else if refreshing {
            DDLogDebug("Ignoring refresh request - we're already refreshing")
        } else {
            displayError(wifiMonitor.getWifiError())
        }
        
        
    }
    
    @objc func userSwiped(_ sender:UISwipeGestureRecognizer)
    {
        let oldIndex = index
        
        if sender.direction == .left {
            DDLogDebug("User swiped left")
            index += 1
        } else if sender.direction == .right {
            DDLogDebug("User swiped right")
            index -= 1
        }
        
        if self.index > 0, self.index < self.videos.count {

            tableViewController?.updateLinkButtons(forCurrentIndex: oldIndex, newIndex: IndexPath.init(row: index, section: 0))
            
            loadVideo(videos[index], autoplay: true)
        }
    }
    
    @IBAction func buttonClickedTryAgain(_ sender: Any) {
        DDLogDebug("Button clicked try again")
        if wifiMonitor.isExpensive {
            displayError(wifiMonitor.getWifiError())
            return
        }
        
        self.progressView.isHidden = false
        self.tryAgainButton.isHidden = true
        videoController?.refreshVideos()
    }
    
    func loadVideo(at index : Int) {
        DDLogDebug("loadVideo at index: \(index) of \(videos.count)")
        self.index = index
        loadVideo(videos[index], autoplay: true)
    }
    
    func loadVideo(_ video : Video, autoplay: Bool) {
        if wifiMonitor.isExpensive {
            displayError(wifiMonitor.getWifiError())
            return
        }
        
        DispatchQueue.main.async() {
            
            let options = [
                "playsinline" : UserDefaults.standard.getFullscreen() ? 0 : 1,
                //According to bug reports, the autoplay variable doesn't work as intended (or at all, really)
                "autoplay" : autoplay ? 1 : 0
            ]
            
            self.autoplay = autoplay
            self.playerView.load(withVideoId: video.id, playerVars: options)
            self.tableViewController?.selectRow(at: IndexPath(row: self.index, section: 0), animated: true)
            
           
        }
    }
    
    // MARK: - VideoControllerDelegate
    func updateThumbnails(indexPaths: [IndexPath]) {
        DispatchQueue.main.async() {
            DDLogDebug("updateThumnails on main thread reloading cells at paths: \(indexPaths) with a total video count of \(self.videos.count)")
            self.tableViewController?.reloadRows(at: indexPaths)
     
            //Maintain the selection of the first cell after reload
            if indexPaths.contains(IndexPath.init(row: 0, section: 0)),
                self.index == 0 {
                self.tableViewController?.selectRow(at: IndexPath.init(row: 0, section: 0), animated: false)
                         
                         
            }
            
        }
    }
    
    func toggleControls(hidden hide : Bool) {
        self.tableViewController?.view.isHidden = hide
        self.playerView.isHidden = hide
    }
    
    func finishedRefresh(error: Error?) {
        DDLogDebug("Finished refresh")
        refreshing = false
        
        if let videoController = videoController,
            error == nil {
        
            videos = videoController.getAllVideos()
            
            DispatchQueue.main.async() {
               DDLogDebug("Calling into tableViewController.finishedRefresh from main thread with video count \(self.videos.count)")
                self.tableViewController?.finishedRefresh(withVideos: self.videos, error: error)

                self.noVideosLabel.isHidden = (self.videos.count > 0)
                self.toggleControls(hidden: false)
                self.progressView.isHidden = true
                self.tryAgainButton.isHidden = true
                
            }
            
            index = 0
            if videos.count > 0 {
                loadVideo(videos[index], autoplay: false)
            }
        } else if error != nil {
            
            //We're going to force cast this error now that we know it isn't nil
            displayError(error!)
           
        }
    }
    
    func displayError(_ error : Error) {
        DispatchQueue.main.async() {
           self.toggleControls(hidden: true)
           self.progressView.isHidden = true
           self.tryAgainButton.isHidden = false
           
           
           let alert = UIAlertController.init(title: "Error", message: "Error fetching video list: " + error.localizedDescription, preferredStyle: .alert)
           alert.addAction(UIAlertAction.init(title: "Okay", style: .default, handler: nil))
           self.present(alert, animated: true, completion: nil)
       }
   }
    
    // MARK: - SettingsDelegate
    func needsUpdate() {
        DispatchQueue.main.async() {
            //Reset the playerview in case this subreddit contains no videos - we don't want it showing a video thumbnail from the previous subreddit
            self.playerView.load(withVideoId: "")
            self.view.backgroundColor = UIColor.black
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            self.toggleControls(hidden: true)
        }
        _ = videoController?.deleteAll()
        videoController?.refreshVideos()
    }
    
    // MARK: - YTPlayerViewDelegate
    
    func playerViewDidBecomeReady(_ playerView: WKYTPlayerView) {
        DDLogDebug("playerViewDidBecomeReady")
        if self.autoplay, UserDefaults.standard.getAutoplay() {
            playerView.playVideo()
        }
    }

    // MARK: - Videos Array Accessors
    
    func getVideo(at index: Int) -> Video? {
        if index >= 0, index < videos.count {
            return videos[index]
        } else {
            DDLogDebug("Error fetching video in getVideo - Asked for index \(index) but our total video count is \(videos.count)")
        }
        
        return nil
    }
    
    func getVideoCount() -> Int {
        return videos.count
    }
    
    func getIndex() -> Int {
        return index
    }
    
}

