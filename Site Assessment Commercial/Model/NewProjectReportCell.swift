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
    case image              = "Image"
    case notes              = "Notes"
    case multipleSelection  = "Multiple Selection"
    case inputs             = "Inputs"
    case TrussType          = "Truss Type"
    case selectionsWithImageOther = "Selections With Image Other"
}
typealias ImageGallerySection = AnimatableSectionModel<String, String>

class TrussTypeCell: UICollectionViewCell {
    
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let data = [
        ImageGallerySection(model: "", items: ["Add_Picture"])
    ]

    var sections = BehaviorRelay(value: [ImageGallerySection]())
    
    var images: [UIImage]! = []

    var disposeBag = DisposeBag()
    
    func setupDataSource() {
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<ImageGallerySection> (
            configureCell: { (_, cv, indexPath, element) in
                let cell = cv.dequeueReusableCell(withReuseIdentifier: "ImageGalleryCell", for: indexPath) as! ImageGalleryCell
                
                if let image = UIImage(named: element) {
                    cell.imageView.image = image
                } else {
                    cell.imageView.image = nil
                }
                return cell
        },
            configureSupplementaryView: { (ds, cv, kind, ip) in
                let section = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Section", for: ip) as! CollectionReusableView
                section.labelSectionName.text = "\(ds[ip.section].model)"
                return section
            }
        )
        
        sections
            .asObservable()
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }

    func setupCell(question: QuestionStructure, imageAttrs: [ImageAttributes]?) {
        labelKey.text = question.Name

        if let imgName = question.Image {
            imageView.image = UIImage(named: imgName)
        } else {
            imageView.image = nil
        }
        
        if let value = question.Value {
            textField.text = value
        } else {
            if let option = question.Options?.first {
                textField.placeholder = option
            } else {
                textField.placeholder = "Please select a shape."
            }
        }
        
        textField.autocorrectionType = .no
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []

        /*
        if let imgAttrs = imageAttrs {
            let images = imgAttrs.compactMap { UIImage(contentsOfFile: $0.name) }
            
            print("images.count = \(images.count)")
            self.images = images
        }
         */

        collectionView.reloadData()
    }
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()

        labelKey.text = nil
        imageView.image = nil
        textField.text = nil
        images = nil
    }
}

class MultipleSelectionCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet var optionGroup: [MyCheckBox]!
    
    var disposeBag = DisposeBag()
    var indexPath: IndexPath!
    var delegate: SelectionCellDelegate?
    
    @IBAction func buttonTapped(_ sender: MyCheckBox) {
        delegate?.buttonDidClicked(button: sender, indexPath: indexPath)
    }
    
    func setupCell(with question: QuestionStructure) {
        labelKey.text = question.Name
        
        optionGroup.forEach { $0.isHidden = true }
        
        if let options = question.Options {
            for (index, option) in options.enumerated() {
                
                optionGroup[index].setTitle(option, for: .normal)
                optionGroup[index].isHidden = false
                
                question.Value?.split(separator: ",").compactMap({String($0)}).forEach({
                    if optionGroup[index].title(for: .normal) == $0 {
                        optionGroup[index].isChecked = true
                    }
                })
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()

        labelKey.text = nil
        optionGroup.forEach {$0.isChecked = false}
    }
}

class ARCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var arView: ARSCNView!
    
    var disposeBag = DisposeBag()

    func setupCell(with question: QuestionStructure) {
        labelKey.text = question.Name
    }
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()

        super.prepareForReuse()
    }
}

protocol SelectionCellDelegate {
    func buttonDidClicked(button: MyCheckBox, indexPath: IndexPath)
}

class ImageCell: UICollectionViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var collectionView: ImageGalleryCollectionView!
    var disposeBag = DisposeBag()
    
    var imageAttrs: [ImageAttributes]? = nil
    var images: [UIImage]? = nil
    
    private let imageDefault = UIImage(named: "Add_Pictures")!

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        
        layoutAttributes.bounds.size.height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        
        return layoutAttributes
    }
    
    func loadImages(_ questionName: String) {
        guard let prjFolder = DataStorageService.sharedDataStorageService.currentProjectHomeDirectory else {
            print("[retrieveData - FileManager.default.urls] failed.")
            return
        }

        let questionImageAttrs = try? FileManager.default.contentsOfDirectory(at: prjFolder, includingPropertiesForKeys: nil).filter{ $0.lastPathComponent.contains(questionName) && $0.pathExtension == "png" }.compactMap { url -> (UIImage?, ImageAttributes?) in
            
            if let image = UIImage(contentsOfFile: url.path) {
                let fileName = url.deletingPathExtension().lastPathComponent
                let imgAttr = ImageAttributes(name: fileName)
                
                return (image, imgAttr)
            }
            
            return (nil, nil)
        }
        
        self.imageAttrs = questionImageAttrs?.compactMap({$0.1})
        self.images = questionImageAttrs?.compactMap({$0.0})
    }
        
    func setupCell(question: QuestionStructure) {
        
        labelKey.text = question.Name

        loadImages(question.Name)
        collectionView.isUserInteractionEnabled = false
        collectionView.images = self.images ?? []
        collectionView.reloadData()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()

        labelKey.text = nil
        collectionView.images = [imageDefault]
    }
    
}

class NotesCell: UICollectionViewCell  {

    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var textView: UITextView!

    var disposeBag = DisposeBag()

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
        
        disposeBag = DisposeBag()
        labelKey.text = nil
        setupTextView()
    }
}

class ImageGalleryCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
    }
}

class InputsCell: UICollectionViewCell {
    
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    
    var disposeBag = DisposeBag()

    func setupCell(question: QuestionStructure) {
        labelKey.text = question.Name
        
        setupTextField(options: question.Options, value: question.Value)
        
        if let imageName = question.Image, imageName != "" {
            imageView.image = UIImage(named: imageName)
            imageView.isUserInteractionEnabled = true
        } else {
            imageView.image = nil
            imageView.isUserInteractionEnabled = false
        }
    }
    
    func setupTextField(options: [String]?, value: String?) {
        textField.isUserInteractionEnabled = false
        textField.keyboardType = .numberPad

//        textField.autocorrectionType = .no
//        textField.inputAssistantItem.leadingBarButtonGroups = []
//        textField.inputAssistantItem.trailingBarButtonGroups = []

        if let value = value, value != "" {
            textField.text = value
        } else {
            if let options = options {
                let placeholder = options.joined(separator: " x ")
                textField.placeholder = placeholder
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()

        labelKey.text = nil
        imageView.image = nil
        textField.text = nil
    }
}

class SelectionsWithImageOtherCell: UICollectionViewCell {
    
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var optionGroup: [MyCheckBox]!

    var disposeBag = DisposeBag()
    var delegate: SelectionCellDelegate?
    var indexPath: IndexPath!

    @IBAction func buttonTapped(_ sender: MyCheckBox) {
        delegate?.buttonDidClicked(button: sender, indexPath: indexPath)
    }
    
    func setupCell(question: QuestionStructure) {
        labelKey.text = question.Name
        
        optionGroup.forEach {
            $0.isHidden = true
            $0.isChecked = false
        }
        
        if let options = question.Options {
            for (index, option) in options.enumerated() {
                
                let button = optionGroup[index]
                button.setTitle(option, for: .normal)
                button.isHidden = false
           }
        }

        if let value = question.Value, value != "" {
            optionGroup.first(where: {$0.title(for: .normal) == value})?.isChecked = true
        }
        
        if let imageName = question.Image, imageName != "" {
            imageView.image = UIImage(named: imageName)
            imageView.isUserInteractionEnabled = true
        } else {
            imageView.image = nil
            imageView.isUserInteractionEnabled = false
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
        labelKey.text = nil
        imageView.image = nil
        optionGroup.forEach { $0.isChecked = false }
    }
}
