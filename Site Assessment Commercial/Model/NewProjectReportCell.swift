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
    case selectionWithImage = "Selection With Image"
    case image           = "Image"
    case singleInput     = "Single Input"
    case twoInputs       = "Two Inputs"
    case threeInputs     = "Three Inputs"
    case inputsWithImage = "Inputs with Image"
    case notes           = "Notes"
}

class ARCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var imageviewReference: UIImageView!
    
    @IBOutlet weak var arView: ARSCNView!
}

protocol SelectionCellDelegate {
    func buttonDidClicked(button: MyCheckBox, indexPath: IndexPath)
}

class SingleSelectionCell: UICollectionViewCell {
    @IBOutlet var buttonGroup: [MyCheckBox]!
    @IBOutlet weak var labelKey: UILabel!
        
    var indexPath: IndexPath!
    var delegate: SelectionCellDelegate?
    
    @IBAction func buttonTapped(_ sender: MyCheckBox) {
        delegate?.buttonDidClicked(button: sender, indexPath: indexPath)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        buttonGroup.forEach {$0.isChecked = false}
    }
}

class ImageCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var collectionView: ImageGalleryCollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collectionView.isUserInteractionEnabled = false
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        
        layoutAttributes.bounds.size.height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        
        return layoutAttributes
    }
    
    func setupCell(question: QuestionaireConfigs_QuestionsWrapper) {
        
        guard let prjFolder = DataStorageService.sharedDataStorageService.currentProjectHomeDirectory else {
            print("[retrieveData - FileManager.default.urls] failed.")
            return
        }
        
        let questionImages = try? FileManager.default.contentsOfDirectory(at: prjFolder, includingPropertiesForKeys: nil).filter{ $0.lastPathComponent.contains(question.Name) && $0.pathExtension == "png" }.map { (fileURL) -> UIImage in
            guard let image = UIImage(contentsOfFile: fileURL.path)
                else {
                    print("[retrieveProjectList - JSONDecoder().decode failed]")
                    return UIImage()
            }
            
            return image
        }
        
        labelKey.text = question.Name
        collectionView.images = questionImages ?? []
        collectionView.reloadData()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        labelKey.text = nil
        collectionView.images = nil
    }
    
}

class SingleInputCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var textValue: UITextField!
    
    override func prepareForReuse() {
        textValue.text = nil
    }
}

class TwoInputsCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var labelOperator: UILabel!
    @IBOutlet var textFields: [UITextField]!


    override func prepareForReuse() {
        super.prepareForReuse()
        
        textFields.forEach {$0.text = nil}
    }
}

class ThreeInputsCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet var labelOperators: [UILabel]!
    @IBOutlet var textFields: [UITextField]!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        textFields.forEach {$0.text = nil}
    }
}

class NotesCell: UICollectionViewCell  {

    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var textviewNotes: UITextView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        textviewNotes.text = "Notes: "
        textviewNotes.textColor = UIColor.lightGray
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textviewNotes.text = "Notes: "
        textviewNotes.textColor = UIColor.lightGray
    }
}

class ImageGalleryCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        layoutAttributes.bounds.size.height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        
        return layoutAttributes
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
    }
}

class SelectionWithImageCell: UICollectionViewCell {
    
    @IBOutlet weak var labelQuestion: UILabel!
    @IBOutlet var OptionGroup: [MyCheckBox]!
    @IBOutlet weak var imageView: UIImageView!
    
    var delegate: SelectionCellDelegate?
    var indexPath: IndexPath!

    @IBAction func buttonTapped(_ sender: MyCheckBox) {
        delegate?.buttonDidClicked(button: sender, indexPath: indexPath)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        labelQuestion.text = nil
        imageView.image = nil
        OptionGroup.forEach {$0.setTitle(nil, for: .normal)}
    }
}

class InputsWithImageCell: UICollectionViewCell {

    @IBOutlet weak var labelQuestion: UILabel!
    @IBOutlet var textFieldGroup: [UITextField]!
    @IBOutlet var labelOperatorGroup: [UILabel]!
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        labelQuestion.text = nil
        imageView.image = nil
        labelOperatorGroup.forEach {$0.text = nil}
        textFieldGroup.forEach {$0.text = nil}
    }
}
