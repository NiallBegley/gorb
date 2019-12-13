//
//  VideoTableViewController.swift
//  
//
//  Created by Niall on 11/19/19.
//

import UIKit

class VideoTableViewController: UITableViewController, VideoTableViewCellDelegate {
    
    //We'll set this in the embedded segue
    lazy var parentController : ViewController = ViewController.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshAllVideos(_:)), for: .valueChanged)
//        tableView.refreshControl = refreshControl
        
    }
    
    @objc func refreshAllVideos(_ sender: Any) {
        parentController.refreshAllVideos()
        refreshControl?.endRefreshing()
      }
    
    // MARK: - Actions
    
    @IBAction func onBtnClickedSettings(_ sender: Any) {
        parentController.performSegue(withIdentifier: "SETTINGS_SEGUE", sender: self)
    }
    
    // MARK: - Methods for Parent VC - must be called from main thread
    func selectRow(at indexPath: IndexPath, animated: Bool) {
        tableView.selectRow(at: indexPath, animated: animated, scrollPosition: .middle)
    }
    
    func reloadRows(at indexPaths: [IndexPath]) {
       tableView.beginUpdates()
       tableView.reloadRows(at: indexPaths, with: .none)
       tableView.endUpdates()
    }
    
    func finishedRefresh(withVideos videos: [Video], error : Error?) {
        
        refreshControl?.endRefreshing()
        
        if error == nil, videos.count > 0 {

            let video = videos[0]
            
            let formatter = DateFormatter.hhmma
            let date = formatter.string(from: video.created_at)
            refreshControl?.attributedTitle = NSAttributedString(string: "Last Updated: \(date)")
            
            tableView.isHidden = false
        } else if error == nil, videos.count == 0 {
            tableView.isHidden = true
        }
        
        tableView.reloadData()
        tableView.selectRow(at: IndexPath.init(row: 0, section: 0), animated: false, scrollPosition: .none)
    }
    // MARK: - TableView
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parentController.getVideoCount()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "/r/\(UserDefaults.standard.getSubreddit())"
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        //We can't grab the actual cell from the tableview here because there is a high likelihood that the tableview is in the process of updating, so just grab a empty cell so we can easily reference the width of the title label and calculate the real height from that
        if let cell = tableView.dequeueReusableCell(withIdentifier: "VIDEO_TABLE_VIEW_CELL") as? VideoTableViewCell,
            let textLabel = cell.title,
            let video = parentController.getVideo(at: indexPath.row) {
            
            let text = video.title
            
            let constrainedBox = CGSize(width: textLabel.bounds.width, height: .greatestFiniteMagnitude)
            let boundingBox = text.boundingRect(with: constrainedBox, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: textLabel.font], context: nil)
            return max(66.0, ceil(boundingBox.height) + 20)
        }
            
        return 66.0
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VIDEO_TABLE_VIEW_CELL") as! VideoTableViewCell
        
        if let video =  parentController.getVideo(at: indexPath.row) {
            cell.title.text = video.title
            
            cell.linkButton.isHidden = (indexPath.row != parentController.getIndex())
            
            //Right now we only show the link button on the currently playing video so we could just do a lookup in the videos array when the button is pressed, but I'll associate each cell with its link for it to pass back to the view controller just in case something changes
            cell.permalink = video.permalink
            cell.delegate = self
            
            let image = video.thumbnail_data.count > 0 ? UIImage(data: video.thumbnail_data) : UIImage(named: "placeholder")
            cell.thumbnail.image = image
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        updateLinkButtons(forCurrentIndex: parentController.getIndex(), newIndex: indexPath)
        
        parentController.loadVideo(at: indexPath.row)
    }

    func updateLinkButtons(forCurrentIndex index : Int, newIndex indexPath : IndexPath) {
        if index >= 0, index < parentController.getVideoCount() {
            if let oldCell = tableView.cellForRow(at: IndexPath.init(row: index, section: 0)) as? VideoTableViewCell {
                oldCell.linkButton.isHidden = true
            }
        }
        
        if let newCell = tableView.cellForRow(at: indexPath) as? VideoTableViewCell {
            newCell.linkButton.isHidden = false
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HEADER_CELL") as! SubredditHeaderTableViewCell
            cell.title.text = ("/r/\(UserDefaults.standard.getSubreddit())" as NSString).uppercased
            
            return cell.contentView
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let shareAction = UIContextualAction.init(style: .normal, title: "Share") { (action, view, completionHandler) in
            
            if let video = self.parentController.getVideo(at: indexPath.row)
            {
                let browserLink = (UserDefaults.standard.getOldReddit() ? "https://old.reddit.com" : "https://www.reddit.com") + video.permalink
                guard let url = URL.init(string: browserLink) else { return }
                
                let activityController = UIActivityViewController.init(activityItems: [url], applicationActivities: nil)
                DispatchQueue.main.async() {
                    self.present(activityController, animated: true, completion: nil)
                    
                }
        
            }
        }
        shareAction.backgroundColor = UIColor.flatBlue()
        
        return UISwipeActionsConfiguration.init(actions: [shareAction])
        
    }
    
    // MARK: - VideoTableViewCellDelegate
       
   func linkTapped(_ permalink : String) {
   
    if let alert = SchemeHandler.determineSchemes(permalink) {
           present(alert, animated: true, completion: nil)
       } else {
           URL.openURL(string: permalink)
       }
   }
}
