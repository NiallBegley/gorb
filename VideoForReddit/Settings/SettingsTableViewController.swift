//
//  SettingsTableViewController.swift
//  VideoForReddit
//
//  Created by Niall on 9/14/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import UIKit

protocol SettingsDelegate : class {
    func needsUpdate()
}

class SettingsTableViewController: UITableViewController, PickerDelegate {

    private enum Settings : Int {
        case autoplay
        case subreddit
        case fullscreen
        case oldReddit
    }
    
    weak var delegate : SettingsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PICKER_SEGUE",
            let vc = segue.destination as? PickerTableViewController {
            
            //TODO: Need to store this somewhere else
            vc.setData(["Videos", "YoutubeHaiku", "MealtimeVideos", "Games", "ArtisanVideos"], withGetter: UserDefaults.standard.getSubreddit, andSetter: UserDefaults.standard.setSubreddit(value:))
            vc.delegate = self
        }
    }
    
    func didSelect(_ value: String) {
        delegate?.needsUpdate()
        
        if let vc = navigationController?.viewControllers.first {
            navigationController?.popToViewController(vc, animated: true)
        }
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == Settings.autoplay.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SWITCH_CELL") as! SwitchTableViewCell
            cell.setControlFuncs(set: UserDefaults.standard.setAutoplay(value:), get: UserDefaults.standard.getAutoplay)
            cell.label.text = "Autoplay videos"
            return cell
            
        } else if indexPath.row == Settings.subreddit.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PICKER_CELL") as! PickerTableViewCell
          
            cell.label.text = "Subreddit"
            cell.detail.text = UserDefaults.standard.getSubreddit()
            
            return cell
        } else if indexPath.row == Settings.fullscreen.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SWITCH_CELL") as! SwitchTableViewCell
            cell.setControlFuncs(set: UserDefaults.standard.setFullscreen(value:), get: UserDefaults.standard.getFullscreen)
            cell.label.text = "Fullscreen"
            return cell
            
        } else if indexPath.row == Settings.oldReddit.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SWITCH_CELL") as! SwitchTableViewCell
            cell.setControlFuncs(set: UserDefaults.standard.setOldReddit(value:), get: UserDefaults.standard.getOldReddit)
            cell.label.text = "Use \"old.reddit\" for external links"
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PICKER_CELL") as! PickerTableViewCell
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == Settings.subreddit.rawValue {
            performSegue(withIdentifier: "PICKER_SEGUE", sender: nil)
        }
    }
    
}
