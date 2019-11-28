//
//  SettingsTableViewController.swift
//  gorb
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
        case resetComments
    }
    
    weak var delegate : SettingsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(false, animated: true)
        
        view.backgroundColor = UIColor.white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {
            navigationController?.setNavigationBarHidden(true, animated: true)
            view.backgroundColor = UIColor.black
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PICKER_SEGUE",
            let vc = segue.destination as? PickerTableViewController,
            let indexPath = sender as? IndexPath {
            
            if indexPath.row == Settings.subreddit.rawValue {
                vc.setData(UserDefaults.standard.getSubreddits(), withDataSetter: UserDefaults.standard.setSubreddits(value:), valueGetter: UserDefaults.standard.getSubreddit, andSetter: UserDefaults.standard.setSubreddit(value:))
                
                vc.setValidator(validateSubreddit(_:), withErrorMessage: "Subreddit is too long, contains a space, or has an invalid character")
                vc.delegate = self
            }
        }
    }
    
    func validateSubreddit(_ subreddit : String) -> Bool {
        let pattern = "^[A-Za-z0-9][A-Za-z0-9_]{2,20}$"

        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: subreddit.count)
        
        guard let _ = regex?.firstMatch(in: subreddit, range: range) else {
            return false
        }
        
//        return (url as NSString).substring(with: result.range)
        
        return true
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
        return 5
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
            
        } else if indexPath.row == Settings.resetComments.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BASIC_CELL") as! UITableViewCell
            cell.textLabel?.text = "Reset comment handler"
            
            return cell
        }
        
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PICKER_CELL") as! PickerTableViewCell
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == Settings.subreddit.rawValue {
            performSegue(withIdentifier: "PICKER_SEGUE", sender: indexPath)
        } else if indexPath.row == Settings.resetComments.rawValue {
            let alert = UIAlertController.init(title: "Warning", message: "Reset the current default choice for opening comments?  You will be prompted next time you try and open a link to comments.", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "Yes", style: .default, handler: {(alert : UIAlertAction) in
                    UserDefaults.standard.clearSchemes()
            }))
            
            alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
            
            present(alert, animated: true, completion: {() in
                tableView.deselectRow(at: indexPath, animated: true)
            })
            
        }
    }
    
}
