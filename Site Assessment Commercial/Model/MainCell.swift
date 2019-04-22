//
//  MainCell.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-23.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import UIKit

class MainCell: UITableViewCell {

    @IBOutlet weak var labelProjectAddress: UILabel!
    
    private var activityIndicator = UIActivityIndicatorView(style: .gray)

    func configureWithData(data: MainViewModel) {
        labelProjectAddress.text = data.projectAddress
        
        if data.status == .pending {
            accessoryView = nil
            accessoryType = .disclosureIndicator
        } else if data.status == .uploading {
            accessoryView = activityIndicator
            startAnimation()
        } else {
            stopAnimation(withStatus: .completed)
            accessoryView = nil
            accessoryType = .checkmark
        }
        
        labelProjectAddress.sizeToFit()
    }
    
    func configureCell(text: String) {
        labelProjectAddress.text = text
    }
    
    func startAnimation() {
        accessoryView = activityIndicator
        activityIndicator.startAnimating()
    }
    
    func stopAnimation(withStatus status: UploadStatus) {
        activityIndicator.stopAnimating()

        switch status {
        case .completed:
            accessoryView = nil
            accessoryType = .checkmark
        default:
            accessoryView = nil
            accessoryType = .disclosureIndicator
        }
    }
}
