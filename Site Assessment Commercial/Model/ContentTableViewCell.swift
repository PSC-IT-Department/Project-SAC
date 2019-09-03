//
//  ContentTableViewCell.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-07-24.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import UIKit
import ARKit
import RxCocoa
import RxSwift
import RxDataSources

class TvTrussTypeCell: UITableViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var imageTrussType: UIImageView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!

    private let cellID = "ImageGalleryCell"
    
    let data = [
        ImageGallerySection(model: "", items: ["Add_Picture"])
    ]
    
    var sections = BehaviorRelay(value: [ImageGallerySection]())
    
    var images: [UIImage]! = []
    
    var disposeBag = DisposeBag()
    
    func setupDataSource() {
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<ImageGallerySection> (
            configureCell: { (_, collectionView, indexPath, element) in
                let cellId = "ImageGalleryCell"
                let cellIdentifier = CellIdentifier<ImageGalleryCell>(reusableIdentifier: cellId)
                let cell = collectionView.dequeueReusableCellWithIdentifier(identifier: cellIdentifier,
                                                                            forIndexPath: indexPath)
                
                if let image = UIImage(named: element) {
                    cell.imageView.image = image
                } else {
                    cell.imageView.image = nil
                }
                return cell
        },
            configureSupplementaryView: { (dataSource, collectionView, kind, indexPath) in
                let section = collectionView.dequeueReusableSupplementaryView (
                    ofKind: kind,
                    withReuseIdentifier: "Section",
                    for: indexPath
                    // swiftlint:disable:next force_cast
                    ) as! CollectionReusableView
                
                section.labelSectionName.text = "\(dataSource[indexPath.section].model)"
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
        
        imageTrussType.image = UIImage(named: "Truss_Type")

        if let value = question.Value, value != "" {
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
        
        //collectionView.reloadData()
        collectionView.isHidden = true
    }
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
        
        labelKey.text = nil
        imageTrussType.image = UIImage(named: "Truss_Type")
        textField.text = nil
        images = nil
        
        collectionView.isHidden = true
    }
}

class TvMultipleSelectionCell: UITableViewCell {
    @IBOutlet var labelKey: UILabel!
    @IBOutlet var optionGroup: [MyCheckBox]!
    
    @IBAction func buttonTapped(sender: MyCheckBox) {
        delegate?.buttonDidClicked(button: sender, indexPath: indexPath)
    }
    
    var disposeBag = DisposeBag()
    var indexPath: IndexPath!
    weak var delegate: SelectionCellDelegate?
    
    func setupCell(with question: QuestionStructure) {
        labelKey.text = question.Name

        optionGroup.forEach {
            $0.isHidden = true
            $0.imageView?.contentMode = .scaleAspectFit
        }
        
        if let options = question.Options {
            for (index, option) in options.enumerated() {
                optionGroup[index].setTitle(option, for: .normal)
                optionGroup[index].isHidden = false
            }
        }
        
        let optionIndexedTitles = optionGroup.enumerated().compactMap { (offset, element) -> (Int, String?) in
            return (offset, element.title(for: .normal))
        }
        
        question.Value?.split(separator: ",").compactMap({String($0)}).forEach({ (value) in
            autoreleasepool {
                if let index = optionIndexedTitles.firstIndex(where: {$0.1 == value}) {
                    optionGroup[index].isChecked = true
                } else {
                    if let index = optionIndexedTitles.firstIndex(where: {$0.1 == "Other"}) {
                        optionGroup[index].setTitle(value, for: .normal)
                        optionGroup[index].isChecked = true
                    }
                }
            }
        })
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
        
        labelKey.text = nil
        optionGroup.forEach {$0.isChecked = false}
    }
}

class TvImageCell: UITableViewCell {
    @IBOutlet weak var labelKey: UILabel!
    @IBOutlet weak var collectionView: ImageGalleryCollectionView!
    
    var disposeBag = DisposeBag()

    var images: [UIImage] = [UIImage(named: "Add_Pictures")!]

    private let imageDefault = UIImage(named: "Add_Pictures")!
    
    func loadImages(_ imgAttrs: [ImageAttributes]?) {
        guard let prjFolder = DataStorageService.shared.projectDir else {
            print("[retrieveData - FileManager.default.urls] failed.")
            return
        }
        
        let fileManager = FileManager.default
        let result = Result {try fileManager.contentsOfDirectory(at: prjFolder, includingPropertiesForKeys: nil)}
        switch result {
        case .success(let urls):
            let _images = imgAttrs?.compactMap { (imgAttr) -> UIImage? in
                if let url = urls.first(where: {$0.lastPathComponent.contains(imgAttr.name) &&
                    $0.pathExtension == "png"}),
                    let image = UIImage(contentsOfFile: url.path) {
                    return image
                } else {
                    return nil
                }
            }
            images = _images ?? [imageDefault]
        default:
            break
        }
    }
    
    func setupCell(question: QuestionStructure) {
        labelKey.text = question.Name
        collectionView.isUserInteractionEnabled = false
        collectionView.images = images
        collectionView.reloadData()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}

class TvNotesCell: UITableViewCell {
    @IBOutlet var labelKey: UILabel!
    @IBOutlet var textView: UITextView!
    
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

class TvInputsCell: UITableViewCell {
    @IBOutlet weak var labelKey: UILabel!
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var imageField: UIImageView!
    
    var disposeBag = DisposeBag()
    
    func setupCell(question: QuestionStructure) {
        labelKey.text = question.Name
        
        setupTextField(options: question.Options, value: question.Value)
        
        if let imageName = question.Image, imageName != "" {
            imageField.image = UIImage(named: imageName)
            imageField.isUserInteractionEnabled = true
        } else {
            imageField.image = nil
            imageField.isUserInteractionEnabled = false
        }
    }
    
    func setupTextField(options: [String]?, value: String?) {
        textField.isUserInteractionEnabled = false
        textField.keyboardType = .numberPad
        
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
        imageField.image = nil
        textField.text = nil
    }
}

class TvSelectionCell: UITableViewCell {
    @IBOutlet var labelKey: UILabel!
    @IBOutlet var optionGroup: [MyCheckBox]!
    @IBOutlet var imageField: UIImageView!
    
    @IBAction func buttonTapped(sender: MyCheckBox) {
        delegate?.buttonDidClicked(button: sender, indexPath: indexPath)
    }
    
    weak var delegate: SelectionCellDelegate?
    
    var disposeBag = DisposeBag()
    var indexPath: IndexPath!
    
    func setupCell(question: QuestionStructure) {
        labelKey.text = question.Name

        optionGroup.forEach({
            $0.imageView?.contentMode = .scaleAspectFit
            $0.imageEdgeInsets = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)
        })

        if let options = question.Options {
            for (index, option) in options.enumerated() {
                
                let button = optionGroup[index]
                button.setTitle(option, for: .normal)
                button.isHidden = false

                if let defaultValue = question.Default, defaultValue == option,
                    let storedValue = question.Value, storedValue == "" {
                    button.isChecked = true
                }
            }
        }

        if let value = question.Value, value != "" {
            if let index = optionGroup.firstIndex(where: {$0.title(for: .normal) == value}) {
                optionGroup[index].isChecked = true
            } else {
                if let index = optionGroup.firstIndex(where: {$0.title(for: .normal) == "Other"}) {
                    optionGroup[index].setTitle(value, for: .normal)
                    optionGroup[index].isChecked = true
                }
            }
        }
        
        if let imageName = question.Image, imageName != "" {
            imageField.image = UIImage(named: imageName)
            imageField.isUserInteractionEnabled = true
            imageField.isHidden = false
        } else {
            imageField.image = nil
            imageField.isUserInteractionEnabled = false
            imageField.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
        imageField.image = nil
        optionGroup.forEach {
            $0.isChecked = false
            $0.isHidden = true
        }
        
        selectionStyle = .none
    }
}

class TvARCell: UITableViewCell {
}
