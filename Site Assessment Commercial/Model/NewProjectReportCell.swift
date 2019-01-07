//
//  NewProjectReportCell.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-12-06.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import UIKit
import ARKit
import RxCocoa
import RxSwift
import RxDataSources

enum NewProjectReportCellType: String, Codable {
    case ar              = "AR"
    case singleSelection = "Single Selection"
    case image           = "Image"
    case singleInput     = "Single Input"
    case twoInputs       = "Two Inputs"
    case threeInputs     = "Three Inputs"
    case notes           = "Notes"
}

class NewProjectReportCell: UICollectionViewCell {
}

class ARCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var imageviewReference: UIImageView!
    
    @IBOutlet weak var arView: ARSCNView!
}

class SingleSelectionCell: UICollectionViewCell {
    @IBOutlet weak var imageviewReference: UIImageView!

    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var buttonOptionA: UIButton!
    @IBOutlet weak var buttonOptionB: UIButton!
    @IBOutlet weak var buttonOptionC: UIButton!
    @IBOutlet weak var buttonOptionD: UIButton!
}

class ImageCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var tableView: UITableView!
}

class SingleInputCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var textValue: UITextField!
}

class TwoInputsCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var textValue1: UITextField!
    @IBOutlet weak var textValue2: UITextField!
    @IBOutlet weak var labelOperator: UILabel!
}

class ThreeInputsCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    
    @IBOutlet weak var labelOperator1: UILabel!
    @IBOutlet weak var labelOperator2: UILabel!
    
    @IBOutlet weak var textValue1: UITextField!
    @IBOutlet weak var textValue2: UITextField!
    @IBOutlet weak var textValue3: UITextField!
}

class NotesCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var textviewNotes: UITextView!
}
