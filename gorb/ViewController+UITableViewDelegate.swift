//
//  ViewController+UITableViewDelegate.swift
//  gorb
//
//  Created by Niall on 9/30/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import Foundation
import UIKit

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "/r/\(UserDefaults.standard.getSubreddit())"
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        //If the row is selected, recalculate the height so that we can show the entire height instead of the truncated version
        if tableView.indexPathForSelectedRow?.row == indexPath.row {
            
            //We can't grab the actual cell from the tableview here because there is a high likelihood that the tableview is in the process of updating, so just grab a empty cell so we can easily reference the width of the title label and calculate the real height from that
            if let cell = tableView.dequeueReusableCell(withIdentifier: "VIDEO_TABLE_VIEW_CELL") as? VideoTableViewCell,
                let textLabel = cell.title {
                let text = videos[index].title
                
                let constrainedBox = CGSize(width: textLabel.bounds.width, height: .greatestFiniteMagnitude)
                let boundingBox = text.boundingRect(with: constrainedBox, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: textLabel.font], context: nil)
                return max(66.0, ceil(boundingBox.height) + 20)
            }
        }
            
        return 66.0
        
    }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
           //Fire off an update to trigger a recalculation of the tableviewcell heights - this will allow us to show the entire video title if it is currently being truncated.
           self.tableView.beginUpdates()
           self.tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VIDEO_TABLE_VIEW_CELL") as! VideoTableViewCell
        
        if indexPath.row < videos.count {
            let video = videos[indexPath.row]
            cell.title.text = video.title
            
            cell.linkButton.isHidden = (indexPath.row != index)
            
            //Right now we only show the link button on the currently playing video so we could just do a lookup in the videos array when the button is pressed, but I'll associate each cell with its link for it to pass back to the view controller just in case something changes
            cell.permalink = video.permalink
            cell.delegate = self
            
            let image = video.thumbnail_data.count > 0 ? UIImage(data: video.thumbnail_data) : UIImage(named: "placeholder")
            cell.thumbnail.image = image
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        updateLinkButtons(forCurrentIndex: index, newIndex: indexPath)
        
        index = indexPath.row
        loadVideo(videos[index], autoplay: true)
    }

    func updateLinkButtons(forCurrentIndex index : Int, newIndex indexPath : IndexPath) {
        if index >= 0, index < videos.count {
            if let oldCell = tableView.cellForRow(at: IndexPath.init(row: index, section: 0)) as? VideoTableViewCell {
                oldCell.linkButton.isHidden = true
            }
        }
        
        if let newCell = tableView.cellForRow(at: indexPath) as? VideoTableViewCell {
            newCell.linkButton.isHidden = false
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HEADER_CELL") as! SubredditHeaderTableViewCell
            cell.title.text = ("/r/\(UserDefaults.standard.getSubreddit())" as NSString).uppercased
            
            return cell.contentView
        }
        
        return nil
    }
    
}
