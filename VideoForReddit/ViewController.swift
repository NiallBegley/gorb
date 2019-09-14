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

class ViewController: UIViewController, VideoControllerDelegate, UITableViewDelegate, UITableViewDataSource, YTPlayerViewDelegate {
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var tryAgainButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playerView: YTPlayerView!
    @IBOutlet weak var detailsLabel: UILabel!
    var persistentContainer: NSPersistentContainer?
    var videoController : VideoController?
    var videos : [Video] = []
    var index = 0
    var autoplay = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let persistentContainer = persistentContainer {
            videoController = VideoController.init(container: persistentContainer)
            videoController?.delegate = self
            videoController?.deleteAll()
            videoController?.refreshVideos()
        }
        
        playerView.delegate = self
        
        let left = UISwipeGestureRecognizer(target: self, action: #selector(userSwiped(_:)))
        let right = UISwipeGestureRecognizer(target: self, action: #selector(userSwiped(_:)))
        
        left.direction = .left
        right.direction = .right
        
        view.addGestureRecognizer(left)
        view.addGestureRecognizer(right)
        
        let tapTitle = UITapGestureRecognizer(target: self, action: #selector(linkTapped(_:)))
        tapTitle.numberOfTapsRequired = 1
        titleLabel.addGestureRecognizer(tapTitle)
    }
    
    // MARK: - Interaction Callbacks
    
    @objc func linkTapped(_ sender: UITapGestureRecognizer)
    {
        if let alert = URL.openURL(string: videos[index].permalink) {
            present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func userSwiped(_ sender:UISwipeGestureRecognizer)
    {
        if sender.direction == .left {
            index += 1
        } else if sender.direction == .right {
            index -= 1
        }
        
        if self.index > 0, self.index < self.videos.count {
            loadVideo(videos[index], autoplay: true)
        }
    }
    
    @IBAction func buttonClickedTryAgain(_ sender: Any) {
        self.progressView.isHidden = false
        videoController?.refreshVideos()
    }
    
    func loadVideo(_ video : Video, autoplay: Bool) {
        DispatchQueue.main.async() {
            
            let options = [
                "playsinline" : 1,
                //According to bug reports, the autoplay variable doesn't work as intended
                "autoplay" : autoplay ? 1 : 0
            ]
            
            self.autoplay = autoplay
            self.titleLabel.text = video.title
            self.detailsLabel.text = String.init(format: "%d Upvotes - %d Comments", video.ups, video.num_comments)
            self.playerView.load(withVideoId: video.id, playerVars: options)
            self.tableView.selectRow(at: IndexPath(row: self.index, section: 0), animated: true, scrollPosition: .middle)
        }
    }
    
    // MARK: - VideoControllerDelegate
    
    func finishedRefresh(error: Error?) {
        
        if let videoController = videoController,
            error == nil {
            
            
            videos = videoController.getAllVideos()
            
            DispatchQueue.main.async() {
                
                self.tableView.isHidden = false
                self.playerView.isHidden = false
                self.titleLabel.isHidden = false
                self.detailsLabel.isHidden = false
                self.tryAgainButton.isHidden = true
                self.progressView.isHidden = true
                
                self.tableView.reloadData()
            }
            
            index = 0
            if videos.count > 0 {
                loadVideo(videos[index], autoplay: false)
            }
        } else if error != nil {
            
            DispatchQueue.main.async() {
                
                self.tableView.isHidden = true
                self.playerView.isHidden = true
                self.titleLabel.isHidden = true
                self.detailsLabel.isHidden = true
                self.tryAgainButton.isHidden = false
                
                //We're going to force cast this error now that we know it isn't nil
                let alert = UIAlertController.init(title: "Error", message: "Error fetching video list: " + error!.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "Okay", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func updateProgress(percentage: Float) {
        DispatchQueue.main.async() {
            self.progressView.setProgress(percentage, animated: true)
            
        }
    }
    
    // MARK: - TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VIDEO_TABLE_VIEW_CELL") as! VideoTableViewCell
        
        if indexPath.row < videos.count {
            let video = videos[indexPath.row]
            cell.title.text = video.title
            let image = UIImage(data: video.thumbnail_data)
            cell.thumbnail.image = image
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        index = indexPath.row
        loadVideo(videos[index], autoplay: true)
    }

    // MARK: - YTPlayerViewDelegate
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        
        if self.autoplay {
            playerView.playVideo()
        }
    }

    
    
}

