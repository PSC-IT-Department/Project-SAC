//
//  InformationCell.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-23.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import UIKit

class InformationCell: UITableViewCell {

    @IBOutlet weak var labelField: UILabel!
    @IBOutlet weak var labelValue: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setupCell(viewModel: ProjectInformationViewModel) {
        labelField.text = viewModel.key
        labelValue.text = viewModel.value
    }
}
