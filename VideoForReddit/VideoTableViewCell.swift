//
//  VideoTableViewCell.swift
//  VideoForReddit
//
//  Created by Niall on 9/12/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import UIKit

protocol VideoTableViewCellDelegate : class {
    func linkTapped(_ permalink : String)
}
class VideoTableViewCell: UITableViewCell {

    @IBOutlet weak var linkButton: UIButton!
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var title: UILabel!
    weak var delegate : VideoTableViewCellDelegate?
    var permalink : String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onLinkButton(_ sender: Any) {
        if let permalink = permalink {
            delegate?.linkTapped(permalink)
        }
        
    }
}
