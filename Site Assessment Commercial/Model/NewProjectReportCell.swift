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
    case ar                 = "AR"
    case singleSelection    = "Single Selection"
    case selectionWithImage = "Selection With Image"
    case image              = "Image"
    case singleInput        = "Single Input"
    case twoInputs          = "Two Inputs"
    case threeInputs        = "Three Inputs"
    case inputsWithImage    = "Inputs with Image"
    case notes              = "Notes"
    case selectionWithOther = "Selection With Other Option"
    case multipleSelection  = "Multiple Selection"
}

class TrussTypeCell: UICollectionViewCell {
    
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var collectionView: ImageGalleryCollectionView!
    
    func setupCell(with question: QuestionStructure) {
        labelKey.text = question.Name
    }
    
    override func prepareForReuse() {
        labelKey.text = nil
        imageView.image = nil
        textField.text = nil
        collectionView.images = nil
    }
}

class MultipleSelectionCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet var optionGroup: [MyCheckBox]!

    var indexPath: IndexPath!
    var delegate: SelectionCellDelegate?
    
    @IBAction func buttonTapped(_ sender: MyCheckBox) {
        delegate?.buttonDidClicked(button: sender, indexPath: indexPath)
    }
    
    func setupCell(with question: QuestionStructure) {
        labelKey.text = question.Name
        
        optionGroup.forEach { $0.isHidden = true }
        for (index, option) in question.Options.enumerated() {
            
            optionGroup[index].setTitle(option, for: .normal)
            optionGroup[index].isHidden = false
            
            question.Value?.split(separator: ",").compactMap({String($0)}).forEach({
                if optionGroup[index].title(for: .normal) == $0 {
                    optionGroup[index].isChecked = true
                }
            })
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        labelKey.text = nil
        optionGroup.forEach {$0.isChecked = false}
    }
}

class SelectionWithOtherCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    
    @IBOutlet var optionGroup: [MyCheckBox]!
    
    var indexPath: IndexPath!
    var delegate: SelectionCellDelegate?

    @IBAction func buttonTapped(_ sender: MyCheckBox) {
        delegate?.buttonDidClicked(button: sender, indexPath: indexPath)
    }
    
    func setupCell(with question: QuestionStructure) {
        labelKey.text = question.Name

        optionGroup.forEach { $0.isHidden = true }
        question.Options.enumerated().forEach {
            optionGroup[$0.offset].setTitle($0.element, for: .normal)
            optionGroup[$0.offset].isHidden = false
            
            if let value = question.Value,
                optionGroup[$0.offset].title(for: .normal) == value {
                optionGroup[$0.offset].isChecked = true
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        labelKey.text = nil
        optionGroup.forEach { $0.isChecked = false }
    }
}

class ARCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var arView: ARSCNView!
    
    func setupCell(with question: QuestionStructure) {
        labelKey.text = question.Name
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
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
    
    func setupCell(with question: QuestionStructure) {
        labelKey.text = question.Name
        
        buttonGroup.forEach {$0.isHidden = true}
        for (index, option) in question.Options.enumerated(){
            
            buttonGroup[index].setTitle(option, for: .normal)
            buttonGroup[index].isHidden = false
            
            if let value = question.Value,
                buttonGroup[index].title(for: .normal) == value {
                buttonGroup[index].isChecked = true
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        labelKey.text = nil
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
    
    func setupCell(question: QuestionStructure) {
        
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
    
    func setupCell(question: QuestionStructure) {
        labelKey.text = question.Name
        textValue.text = question.Value
        textValue.keyboardType = .numberPad
    }
    
    override func prepareForReuse() {
        textValue.text = nil
    }
}

class TwoInputsCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var labelOperator: UILabel!
    @IBOutlet var textFields: [UITextField]!

    func setupCell(question: QuestionStructure) {
        labelKey.text = question.Name
        
        if let values = question.Value {
            values.split(separator: ",", maxSplits: 2, omittingEmptySubsequences: true).compactMap({String($0)}).enumerated().forEach({ textFields[$0.offset].text = $0.element })
        }
        
        textFields.forEach({$0.keyboardType = .numberPad})
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        labelKey.text = nil
        textFields.forEach {$0.text = nil}
    }
}

class ThreeInputsCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet var labelOperators: [UILabel]!
    @IBOutlet var textFields: [UITextField]!

    func setupCell(question: QuestionStructure) {
        labelKey.text = question.Name
        
        if let values = question.Value {
            values.split(separator: ",", maxSplits: 3, omittingEmptySubsequences: true).compactMap({String($0)}).enumerated().forEach({ textFields[$0.offset].text = $0.element })
        }
        
        textFields.forEach({$0.keyboardType = .numberPad})
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        labelKey.text = nil
        textFields.forEach {$0.text = nil}
    }
}

class NotesCell: UICollectionViewCell  {

    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    func setupCell(question: QuestionStructure) {
        labelKey.text = question.Name

        textView.setFrame()
        textView.returnKeyType = .done

        setupTextView(text: question.Value)
    }
    
    private func setupTextView(text: String? = nil) {
        if let text = text, text != "" {
            textView.text = text
            textView.textColor = UIColor.black
        } else {
            textView.text = "Notes: "
            textView.textColor = UIColor.lightGray
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        labelKey.text = nil
        setupTextView()
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
    
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet var optionGroup: [MyCheckBox]!
    @IBOutlet weak var imageView: UIImageView!
    
    var delegate: SelectionCellDelegate?
    var indexPath: IndexPath!

    @IBAction func buttonTapped(_ sender: MyCheckBox) {
        delegate?.buttonDidClicked(button: sender, indexPath: indexPath)
    }

    func setupCell(question: QuestionStructure) {
        labelKey.text = question.Name
        
        optionGroup.forEach {$0.isHidden = true}
        for (index, option) in question.Options.enumerated() {
            
            optionGroup[index].setTitle(option, for: .normal)
            optionGroup[index].isHidden = false
            
            if let value = question.Value, optionGroup[index].title(for: .normal) == value {
                optionGroup[index].isChecked = true
            }
        }
        
        if question.Key == "sac_structuralType" {
            imageView.image = UIImage(named: "Combined")
        } else if question.Key == "sac_endThreeWebMemberType" {
            imageView.image = UIImage(named: "End Three Web Member Type")
        } else {
            imageView.image = UIImage(named: "Image Placeholder")
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        labelKey.text = nil
        imageView.image = nil
        optionGroup.forEach {$0.setTitle(nil, for: .normal)}
    }
}

class InputsWithImageCell: UICollectionViewCell {

    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet var textFields: [UITextField]!
    @IBOutlet var labelOperatorGroup: [UILabel]!
    @IBOutlet weak var imageView: UIImageView!
    
    func setupCell(question: QuestionStructure) {
        labelKey.text = question.Name
        
        if let values = question.Value {
            values.split(separator: ",", maxSplits: 3, omittingEmptySubsequences: true).compactMap({String($0)}).enumerated().forEach({ textFields[$0.offset].text = $0.element })
        }
        
        if question.Key == "sac_sizeOfBottomChord" {
            imageView.image = UIImage(named: "Size of Bottom Chord")
        } else {
            imageView.image = UIImage(named: "Image Placeholder")
        }
        
        textFields.forEach({$0.keyboardType = .numberPad})
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        labelKey.text = nil
        imageView.image = nil
        labelOperatorGroup.forEach {$0.text = nil}
        textFields.forEach {$0.text = nil}
    }
}
