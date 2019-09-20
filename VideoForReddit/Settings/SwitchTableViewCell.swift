//
//  SwitchTableViewCell.swift
//  VideoForReddit
//
//  Created by Niall on 9/14/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import UIKit

class SwitchTableViewCell: UITableViewCell {

    @IBOutlet weak var switchControl: UISwitch!
    @IBOutlet weak var label: UILabel!
    private var setter : ((_ : Bool) -> ())?
    private var getter : (() -> Bool)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    func setControlFuncs(set: @escaping (_ : Bool) -> (), get: @escaping () -> Bool) {
        
        setter = set
        getter = get
        
        switchControl.setOn(get(), animated: false)
    }

    @IBAction func didSwitch(_ sender: Any) {
        let control = sender as! UISwitch
        
        if let set = setter {
            set(control.isOn)
        }
    }
}
