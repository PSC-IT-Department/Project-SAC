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
    
    private var activityIndicator = UIActivityIndicatorView(style: .gray)

    
    func configureWithData(data: MainViewModel) {
        buttonStatus.setTitle(data.status, for: .normal)
        labelProjectAddress.text = data.projectAddress
        
        if data.status == "Pending" {
            accessoryView = nil
            accessoryType = .disclosureIndicator
        } else if data.status == "Uploading" {
            accessoryType = .none
            accessoryView = activityIndicator
            startAnimation()
        } else {
            stopAnimation(withStatus: "Completed")
            accessoryView = nil
            accessoryType = .checkmark
        }
    }
    
    func startAnimation() {
        accessoryType = .none
        accessoryView = activityIndicator
        activityIndicator.startAnimating()
    }
    
    func stopAnimation(withStatus status: String) {
        activityIndicator.stopAnimating()

        if(status == "Completed") {
            accessoryView = nil
            accessoryType = .checkmark
        } else {
            accessoryView = nil
            accessoryType = .disclosureIndicator
        }
    }
}
