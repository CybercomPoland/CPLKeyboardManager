//
//  TextViewTableViewCell.swift
//  CPLKeyboardManager
//
//  Created by Michal Zietera on 17.03.2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

class TextViewTableViewCell: UITableViewCell {

    @IBOutlet weak var textView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
