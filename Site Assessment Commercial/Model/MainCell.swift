//
//  MainCell.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-23.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import UIKit

class MainCell: UITableViewCell {

    @IBOutlet weak var buttonStatus: UIButton!
    @IBOutlet weak var labelProjectAddress: UILabel!

    
    func configureWithData(data: MainViewModel) {
        buttonStatus.setTitle(data.status, for: .normal)
        labelProjectAddress.text = data.projectAddress
    }
}
