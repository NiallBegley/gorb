//
//  ViewController.swift
//  VideoForReddit
//
//  Created by Niall on 9/7/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import UIKit
import youtube_ios_player_helper
import CoreData
import ChameleonFramework

class ViewController: UIViewController, VideoControllerDelegate, YTPlayerViewDelegate, SettingsDelegate, VideoTableViewCellDelegate {
    @IBOutlet weak var progressView: UIActivityIndicatorView!
    @IBOutlet weak var tryAgainButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var playerView: YTPlayerView!
    var persistentContainer: NSPersistentContainer?
    var videoController : VideoController?
    var videos : [Video] = []
    var index = 0
    var autoplay = false
    let refreshControl = UIRefreshControl()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.setDefaults()
        
        refreshControl.addTarget(self, action: #selector(refreshAllVideos(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        if let persistentContainer = persistentContainer {
            videoController = VideoController.init(container: persistentContainer)
            videoController?.delegate = self
            refreshAllVideos(self)
        }
        
        playerView.delegate = self
        
        let left = UISwipeGestureRecognizer(target: self, action: #selector(userSwiped(_:)))
        let right = UISwipeGestureRecognizer(target: self, action: #selector(userSwiped(_:)))
        
        left.direction = .left
        right.direction = .right
        
        view.addGestureRecognizer(left)
        view.addGestureRecognizer(right)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        view.backgroundColor = UIColor.black
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SETTINGS_SEGUE",
            let vc = segue.destination as? SettingsTableViewController {
                view.backgroundColor = UIColor.white
                vc.delegate = self
        }
    }
    
    // MARK: - VideoTableViewCellDelegate
    
    func linkTapped(_ permalink : String) {
        if let alert = URL.openURL(string: permalink) {
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - Interaction Callbacks
    @objc func refreshAllVideos(_ sender: Any) {
        _ = videoController?.deleteAll()
        videoController?.refreshVideos()
    }
    
    @objc func userSwiped(_ sender:UISwipeGestureRecognizer)
    {
        let oldIndex = index
        
        if sender.direction == .left {
            index += 1
        } else if sender.direction == .right {
            index -= 1
        }
        
        if self.index > 0, self.index < self.videos.count {

            updateLinkButtons(forCurrentIndex: oldIndex, newIndex: IndexPath.init(row: index, section: 0))
            
            loadVideo(videos[index], autoplay: true)
        }
    }
    
    @IBAction func buttonClickedTryAgain(_ sender: Any) {
        self.progressView.isHidden = true
        videoController?.refreshVideos()
    }
    
    func loadVideo(_ video : Video, autoplay: Bool) {
        DispatchQueue.main.async() {
            
            let options = [
                "playsinline" : UserDefaults.standard.getFullscreen() ? 0 : 1,
                //According to bug reports, the autoplay variable doesn't work as intended (or at all, really)
                "autoplay" : autoplay ? 1 : 0
            ]
            
            self.autoplay = autoplay
            self.playerView.load(withVideoId: video.id, playerVars: options)
            self.tableView.selectRow(at: IndexPath(row: self.index, section: 0), animated: true, scrollPosition: .middle)
        }
    }
    
    // MARK: - VideoControllerDelegate
    
    func updateThumbnails(indexPaths: [IndexPath]) {
        DispatchQueue.main.async() {
            
            self.tableView.beginUpdates()
            
            self.tableView.reloadRows(at: indexPaths, with: .none)
            self.tableView.endUpdates()

            //Maintain the selection of the first cell after reload
            if indexPaths.contains(IndexPath.init(row: 0, section: 0)),
                self.index == 0 {
                    self.tableView.selectRow(at: IndexPath.init(row: 0, section: 0), animated: false, scrollPosition: .none)
                         
                         
            }
            
        }
    }
    
    func toggleControls(hidden hide : Bool) {
        self.tableView.isHidden = hide
        self.playerView.isHidden = hide
    }
    
    func finishedRefresh(error: Error?) {
        
        if let videoController = videoController,
            error == nil {
        
            videos = videoController.getAllVideos()

            DispatchQueue.main.async() {
                self.refreshControl.endRefreshing()

                if self.videos.count > 0 {
                    let video = self.videos[0]
                    let formatter = DateFormatter.hhmma
                    let date = formatter.string(from: video.created_at)
                    
                    self.refreshControl.attributedTitle = NSAttributedString(string: "Last Updated: \(date)")
                }
                
                self.toggleControls(hidden: false)
                self.progressView.isHidden = false
                self.tryAgainButton.isHidden = true
                self.tableView.reloadData()
                
                //Select the first video in the tableview
                self.tableView.selectRow(at: IndexPath.init(row: 0, section: 0), animated: false, scrollPosition: .none)
                    
            }
            
            index = 0
            if videos.count > 0 {
                loadVideo(videos[index], autoplay: false)
            }
        } else if error != nil {
            
            DispatchQueue.main.async() {
                self.refreshControl.endRefreshing()
                self.toggleControls(hidden: true)
                self.progressView.isHidden = true
                self.tryAgainButton.isHidden = false
                
                //We're going to force cast this error now that we know it isn't nil
                let alert = UIAlertController.init(title: "Error", message: "Error fetching video list: " + error!.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "Okay", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - SettingsDelegate
    func needsUpdate() {
        DispatchQueue.main.async() {
            self.view.backgroundColor = UIColor.black
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            self.toggleControls(hidden: true)
        }
        _ = videoController?.deleteAll()
        videoController?.refreshVideos()
    }
    
    // MARK: - YTPlayerViewDelegate
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        
        if self.autoplay, UserDefaults.standard.getAutoplay() {
            playerView.playVideo()
        }
    }

    
    
}

