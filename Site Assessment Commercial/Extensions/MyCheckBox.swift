//
//  MyCheckBox.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-01-14.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import UIKit

class MyCheckBox: UIButton {
    let checkedImage = UIImage(named: "CheckBox_Checked")! as UIImage
    let uncheckedImage = UIImage(named: "CheckBox_Unchecked")! as UIImage
    
    var isChecked: Bool = false {
        didSet {
            if isChecked == true {
                self.setImage(checkedImage, for: .normal)
            } else {
                self.setImage(uncheckedImage, for: .normal)
            }
        }
    }
    
    override func awakeFromNib() {
        self.isChecked = false
        self.isHidden = true
    }
}
