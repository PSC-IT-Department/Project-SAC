//
//  NewProjectReportViewController.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-23.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

import Photos

import YangMingShan
import SwifterSwift

import MYTableViewIndex

class NewProjectReportViewController: UIViewController, UICollectionViewDelegateFlowLayout {
    
    typealias EachSection = AnimatableSectionModel<String, QuestionaireConfigs_QuestionsWrapper>

    @IBOutlet weak var reviewButton: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate var tableViewIndexController: TableViewIndexController!
    fileprivate(set) var tableViewIndex: TableViewIndex!

    private var prjData = SiteAssessmentDataStructure()
    
    private var answers: [[Bool]]! = [] {
        didSet {
            //totalMissing -= 1
            //setupReviewButton()
        }
    }
    
    private var totalMissing = 0
    
    var sections = BehaviorRelay(value: [EachSection]())
    
    let disposeBag = DisposeBag()
    
    var initialValue: [EachSection]!
    
    static func instantiateFromStoryBoard(withProjectData data: SiteAssessmentDataStructure) -> NewProjectReportViewController {
        let viewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "NewProjectReportViewController") as! NewProjectReportViewController
        viewController.prjData = data
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupDataSource()
        setupIndexList()
        setupCellTapHandling()
        setupDelegate()
        setupReviewButton()
    }
}

extension NewProjectReportViewController {
    func setupView() {
        self.title = "Questionaire"
        self.setBackground()
    }
    
    func setupDataSource() {
        initialValue = loadData()
        
        let (configureCollectionViewCell, configureSupplementaryView) = collectionViewDataSourceUI()
        
        let cvReloadDataSource = RxCollectionViewSectionedReloadDataSource (
            configureCell: configureCollectionViewCell,
            configureSupplementaryView: configureSupplementaryView
        )
        
        self.sections.accept(initialValue)
        
        self.sections.asObservable()
            .bind(to: collectionView.rx.items(dataSource: cvReloadDataSource))
            .disposed(by: disposeBag)
    }
    
    func setupIndexList() {
        let backgroundView = BackgroundView()

        tableViewIndexController = TableViewIndexController(scrollView: collectionView)
        
        tableViewIndexController.tableViewIndex.backgroundView = backgroundView
        tableViewIndexController.tableViewIndex.indexInset = UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)
        tableViewIndexController.tableViewIndex.indexOffset = UIOffset()
        
        tableViewIndexController.layouter = { tableView, tableIndex in
            var frame = tableIndex.frame
            if (UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft) {
                frame.origin = CGPoint(x: frame.origin.x + 3, y: frame.origin.y)
            } else {
                frame.origin = CGPoint(x: frame.origin.x - 3, y: frame.origin.y)
            }
            tableIndex.frame = frame
        };
        
        tableViewIndexController.tableViewIndex.delegate = self
        tableViewIndexController.tableViewIndex.dataSource = self
        
        tableViewIndex = tableViewIndexController.tableViewIndex
    }
    
    func setupCellTapHandling() {
        collectionView
            .rx
            .itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                if let item = self?.initialValue?[indexPath.section].items[indexPath.item] {
                    
                    switch item.QType {
                        
                    case .singleInput:
                        let alertController = UIAlertController(title: item.Name, message: "", preferredStyle: .alert)
                        
                        let cell = self?.collectionView.cellForItem(at: indexPath) as! SingleInputCell
                        
                        item.Options.forEach({ (option) in
                            alertController.addTextField { (textField) -> Void in
                                textField.placeholder = option
                                textField.keyboardType = UIKeyboardType.decimalPad
                                
                                textField.tag = cell.textValue.tag
                            }
                        })
                        
                        let confirmAction = UIAlertAction(title: "Confim", style: .default, handler: { (action: UIAlertAction) in
                            
                            if let textField = alertController.textFields?.first, let text = textField.text {
                                cell.textValue.text = text
                                
                                self?.updateValue(indexPath: indexPath, value: text)
                                
                                if item.Interdependence == "Yes" {
                                    let section = self?.initialValue[indexPath.section]
                                    let relatedSections = section?.items.filter({ (eachItem) -> Bool in
                                        return eachItem.Dependent?.first?.key == item.Key
                                    })
                                    
                                    var newSections: [QuestionaireConfigs_QuestionsWrapper]? = []
                                    for i in 0 ..< Int(text)! {
                                        _ = relatedSections?.compactMap({ (question: QuestionaireConfigs_QuestionsWrapper) in
                                            var ele = question
                                            if i > 0 {
                                                ele.Key.append("_\(i)")
                                                ele.Name.append("_\(i)")
                                            }
                                            newSections?.append(ele)
                                        })
                                    }
                                    
                                    let firstIndex = section?.items.firstIndex(of: (relatedSections?.first)!)
                                    let lastIndex  = section?.items.firstIndex(of: (relatedSections?.last)!)
                                    
                                    let rangeExpression = firstIndex! ... lastIndex!
                                    self?.initialValue[indexPath.section].items.replaceSubrange(rangeExpression, with: newSections!)
                                    
                                    self?.sections.accept(self!.initialValue)
                                    
                                    self?.setupReviewButton()
                                }
                            }
                        })
                        
                        let cancelAction  = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                        
                        alertController.addAction(confirmAction)
                        alertController.addAction(cancelAction)
                        
                        self?.present(alertController, animated: true, completion: nil)
                        
                    case .twoInputs:
                        let alertController = UIAlertController(title: item.Name, message: "", preferredStyle: .alert)
                        
                        let cell = self?.collectionView.cellForItem(at: indexPath) as! TwoInputsCell
                        
                        for(index, title) in item.Options.enumerated() {
                            alertController.addTextField(configurationHandler: { (textField) in
                                textField.placeholder = title
                                textField.keyboardType = UIKeyboardType.decimalPad
                                textField.tag = cell.textFields[index].tag
                            })
                        }
                        
                        let confirmAction = UIAlertAction(title: "Confirm", style: .default, handler: { (action: UIAlertAction) in
                            if let textFields = alertController.textFields {
                                let value = textFields.compactMap ({
                                    let textField = cell.viewWithTag($0.tag) as! UITextField
                                    textField.text = $0.text
                                    return textField.text}).joined(separator: ",")
                                
                                self?.updateValue(indexPath: indexPath, value: value)
                            }
                        })
                        
                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                        
                        alertController.addAction(confirmAction)
                        alertController.addAction(cancelAction)
                        
                        self?.present(alertController, animated: true, completion: nil)
                        
                    case .inputsWithImage:
                        let alertController = UIAlertController(title: item.Name, message: "", preferredStyle: .alert)
                        let cell = self?.collectionView.cellForItem(at: indexPath) as! InputsWithImageCell
                        
                        for(index, title) in item.Options.enumerated() {
                            alertController.addTextField(configurationHandler: { (textField) in
                                textField.placeholder = title
                                textField.keyboardType = UIKeyboardType.decimalPad
                                textField.tag = cell.textFieldGroup[index].tag
                            })
                        }
                        
                        let confirmAction = UIAlertAction(title: "Confirm", style: .default, handler: { (action: UIAlertAction) in
                            if let textFields = alertController.textFields {
                                let value = textFields.compactMap ({
                                    let textField = cell.viewWithTag($0.tag) as! UITextField
                                    textField.text = $0.text
                                    return textField.text}).joined(separator: ",")
                                
                                self?.updateValue(indexPath: indexPath, value: value)
                            }
                        })
                        
                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                        
                        alertController.addAction(confirmAction)
                        alertController.addAction(cancelAction)
                        
                        self?.present(alertController, animated: true, completion: nil)
                        
                    case .threeInputs:
                        let alertController = UIAlertController(title: item.Name, message: "", preferredStyle: .alert)
                        let cell = self?.collectionView.cellForItem(at: indexPath) as! ThreeInputsCell
                        
                        for(index, title) in item.Options.enumerated() {
                            alertController.addTextField(configurationHandler: { (textField) in
                                textField.placeholder = title
                                textField.keyboardType = UIKeyboardType.decimalPad
                                textField.tag = cell.textFields[index].tag
                            })
                        }
                        
                        let confirmAction = UIAlertAction(title: "Confirm", style: .default, handler: { (action: UIAlertAction) in
                            if let textFields = alertController.textFields {
                                let value = textFields.compactMap ({
                                    let textField = cell.viewWithTag($0.tag) as! UITextField
                                    textField.text = $0.text
                                    return textField.text}).joined(separator: ",")
                                
                                self?.updateValue(indexPath: indexPath, value: value)
                            }
                        })
                        
                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                        
                        alertController.addAction(confirmAction)
                        alertController.addAction(cancelAction)
                        
                        self?.present(alertController, animated: true, completion: nil)
                        
                    case .image:
                        if self?.checkPermission() == true {
                            let pickerViewController = YMSPhotoPickerViewController.init()
                            pickerViewController.numberOfPhotoToSelect = 9
                            
                            self?.yms_presentCustomAlbumPhotoView(pickerViewController, delegate: self)
                            
                        } else {
                            // AlertController popup
                            let alertController = UIAlertController(title: item.Name, message: "No permission to access, please allow in settings.", preferredStyle: .alert)
                            
                            let confirmAction = UIAlertAction(title: "Confrim", style: .default, handler: nil)
                            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                            
                            alertController.addAction(confirmAction)
                            alertController.addAction(cancelAction)
                            
                            self?.present(alertController, animated: true, completion: nil)
                        }
                        
                    case .notes:
                        let cell = self?.collectionView.cellForItem(at: indexPath) as! NotesCell
                        cell.textviewNotes.becomeFirstResponder()
                        
                    default:
                        return
                    }
                }
            })
            .disposed(by: disposeBag)
    }

    func setupDelegate() {
        collectionView
            .rx
            .setDelegate(self)
            .disposed(by: disposeBag)
    }
    
    func setupReviewButton() {
        if totalMissing > 0 {
            reviewButton.backgroundColor = UIColor.red
            reviewButton.setTitleColor(UIColor.white, for: .normal)
            reviewButton.setTitle("Missing (\(totalMissing))", for: .normal)
        } else {
            reviewButton.setTitle("Review", for: .normal)
            reviewButton.backgroundColor = UIColor.blue
            reviewButton.setTitleColor(UIColor.white, for: .normal)
        }
    }
    
    func getQuestionByIndexPath(indexPath: IndexPath) -> QuestionaireConfigs_QuestionsWrapper? {
        
        return initialValue[indexPath.section].items[indexPath.row]
    }
    
    func setupViewModel() {
        
        // Review Button
        setupReviewButton()
        
        // Update Data Source
        sections.accept(self.initialValue)
    }
    
    func updateValue(indexPath: IndexPath, value: String) {
        if initialValue[indexPath.section].items[indexPath.row].Value == nil {
            answers[indexPath.section][indexPath.row] = true
        }
        initialValue[indexPath.section].items[indexPath.row].Value = value
        sections.accept(self.initialValue)
        
        updateIndexItems(indexPath: indexPath, checked: true)
    }
    
    func loadData()->[EachSection] {
        
        DataStorageService.sharedDataStorageService.storeCurrentProjectData(data: prjData)

        let eachSections = self.prjData.prjQuestionnaire.enumerated().map { (arg) -> EachSection in
            
            let (section, row) = arg
            let questions = row.Questions.enumerated().filter({ (index, question) -> Bool in
                question.Value?.isEmpty == false
            })

            totalMissing += row.Questions.count - questions.count
            answers.append(Array(repeating: false, count: row.Questions.count))
            
            questions.forEach({ (index, _) in
                answers[section][index] = true
            })
            
            return EachSection(model: row.Name, items: row.Questions)
        }
        
        return eachSections
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = collectionView.bounds.width
        var height = CGFloat(50)
        
        let section = indexPath.section
        
        let item = initialValue[section].items[indexPath.item]

        switch item.QType {
        case .ar, .image, .notes:
            height = CGFloat(400)
        case .singleSelection:
            height = CGFloat(95)
        case .inputsWithImage, .selectionWithImage:
            height = CGFloat(350)
        default:
            height = CGFloat(50)
        }
    
        return CGSize(width: width, height: height)
    }
    
    @IBAction func buttonReviewDidClicked(_ sender: UIButton) {
        
        prjData.prjQuestionnaire = self.initialValue.map { return QuestionaireConfigs_SectionsWrapper(name: $0.model, questions: $0.items)}
        
        DataStorageService.sharedDataStorageService.storeCurrentProjectData(data: prjData)
        
        let vc = ReviewViewController.instantiateFromStoryBoard(withProjectData: prjData)
        
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func collectionViewDataSourceUI() -> (
        CollectionViewSectionedDataSource<EachSection>.ConfigureCell,
        CollectionViewSectionedDataSource<EachSection>.ConfigureSupplementaryView
        ) {
            return (
                { (_, collectionView, indexPath, item) in
                    
                    switch item.QType {
                    case .image:
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
                        cell.setupCell(question: item)
                        return cell
                        
                    case .ar:
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ARCell", for: indexPath) as! ARCell
                        cell.labelKey.text = item.Name
                        return cell
                        
                    case .notes:
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NotesCell", for: indexPath) as! NotesCell
                        
                        let borderColor : UIColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
                        cell.textviewNotes.layer.borderWidth = 0.5
                        cell.textviewNotes.layer.borderColor = borderColor.cgColor
                        cell.textviewNotes.layer.cornerRadius = 5.0
                        
                        if let text = item.Value, text != "" {
                            cell.textviewNotes.text = text
                        }
                        
                        cell.labelKey.text = item.Name
                        cell.textviewNotes.returnKeyType = .done
                        cell.textviewNotes.delegate = self
                        
                        return cell
                        
                    case .singleInput:
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SingleInputCell", for: indexPath) as! SingleInputCell
                        cell.labelKey.text = item.Name
                        cell.textValue.text = item.Value
                        return cell
                        
                    case .singleSelection:
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SingleSelectionCell", for: indexPath) as! SingleSelectionCell
                        cell.labelKey.text = item.Name
                
                        cell.buttonGroup.forEach {$0.isHidden = true}
                        for (index, option) in item.Options.enumerated(){
                            
                            cell.buttonGroup[index].setTitle(option, for: .normal)
                            cell.buttonGroup[index].isHidden = false
                            
                            if let value = item.Value, cell.buttonGroup[index].title(for: .normal) == value {
                                cell.buttonGroup[index].isChecked = true
                            }
                        }
                                                
                        cell.delegate = self
                        cell.indexPath = indexPath
                        
                        return cell
                        
                    case .threeInputs:
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThreeInputsCell", for: indexPath) as! ThreeInputsCell
                        
                        let values = item.Value?.split(separator: ",", maxSplits: 3, omittingEmptySubsequences: true)

                        cell.labelKey.text = item.Name
                        values?.enumerated().forEach({ (index, value) in
                            cell.textFields[index].text = String(value)
                        })
                        
                        return cell
                        
                    case .twoInputs:
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TwoInputsCell", for: indexPath) as! TwoInputsCell
                        
                        let values = item.Value?.split(separator: ",", maxSplits: 2, omittingEmptySubsequences: true)

                        cell.labelKey.text = item.Name
                        
                        values?.enumerated().forEach({ (index, value) in
                            cell.textFields[index].text = String(value)
                        })
                        
                        return cell
                        
                    case .inputsWithImage:
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InputsWithImageCell", for: indexPath) as! InputsWithImageCell

                        let values = item.Value?.split(separator: ",", maxSplits: 3, omittingEmptySubsequences: true)
                        
                        cell.labelQuestion.text = item.Name
                        values?.enumerated().forEach {
                            cell.textFieldGroup?[$0.offset].text = String($0.element)
                        }
                        
                        if item.Key == "sac_sizeOfBottomChord" {
                            cell.imageView.image = UIImage(named: "Size of Bottom Chord")
                        } else {
                            cell.imageView.image = UIImage(named: "Image Placeholder")
                        }
                        
                        return cell
                        
                    case .selectionWithImage:
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectionWithImageCell", for: indexPath) as! SelectionWithImageCell

                        cell.labelQuestion.text = item.Name
                        
                        cell.OptionGroup.forEach {$0.isHidden = true}
                        for (index, option) in item.Options.enumerated(){
                            
                            cell.OptionGroup[index].setTitle(option, for: .normal)
                            cell.OptionGroup[index].isHidden = false
                            
                            if let value = item.Value, cell.OptionGroup[index].title(for: .normal) == value {
                                cell.OptionGroup[index].isChecked = true
                            }
                        }

                        cell.delegate = self
                        cell.indexPath = indexPath
                        
                        if item.Key == "sac_structuralType" {
                            if item.Value == "Flat Roof" {
                                cell.imageView.image = UIImage(named: "Flat Roof")
                            } else if item.Value == "Ridge Frame" {
                                cell.imageView.image = UIImage(named: "Ridge Frame")
                            } else {
                                cell.imageView.image = UIImage(named: "Combined")
                            }
                        } else if item.Key == "sac_endThreeWebMemberType" {
                            cell.imageView.image = UIImage(named: "End Three Web Member Type")
                        } else {
                            cell.imageView.image = UIImage(named: "Image Placeholder")
                        }
                        
                        return cell
                    }
                    
                    
                    
            },
                { (ds, cv, kind, ip) in
                    let section = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Section", for: ip) as! CollectionReusableView
                    section.labelSectionName.text = "\(ds[ip.section].model)"
                    return section
            }
        )
    }
}

// MARK: - YMSPhotoPickerViewControllerDelegate
extension NewProjectReportViewController: YMSPhotoPickerViewControllerDelegate {
    
    func checkPermission() -> Bool {
        
        var ret = false
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized:
            ret = true
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({
                (newStatus) in
                if newStatus ==  PHAuthorizationStatus.authorized {
                    /* do stuff here */
                    ret = true
                }
            })
            print("It is not determined until now")
            
        case .restricted:
            // same same
            print("User do not have access to photo album.")
            
        case .denied:
            // same same
            print("User has denied the permission.")
        }
        
        return ret
    }

    func photoPickerViewControllerDidReceivePhotoAlbumAccessDenied(_ picker: YMSPhotoPickerViewController!) {
        let alertController = UIAlertController.init(title: "Allow photo album access?", message: "Need your permission to access photo albumbs", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
            UIApplication.shared.open(URL.init(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }
        alertController.addAction(dismissAction)
        alertController.addAction(settingsAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func photoPickerViewControllerDidReceiveCameraAccessDenied(_ picker: YMSPhotoPickerViewController!) {
        let alertController = UIAlertController.init(title: "Allow camera album access?", message: "Need your permission to take a photo", preferredStyle: .alert)
        let dismissAction = UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil)
        let settingsAction = UIAlertAction.init(title: "Settings", style: .default) { (action) in
            UIApplication.shared.open(URL.init(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }
        alertController.addAction(dismissAction)
        alertController.addAction(settingsAction)
        
        picker.present(alertController, animated: true, completion: nil)
    }
    
    func photoPickerViewController(_ picker: YMSPhotoPickerViewController!, didFinishPicking image: UIImage!) {
        picker.dismiss(animated: true) {
            
            guard let compressedImage = image.compressed(),
                let indexPath = self.collectionView.indexPathsForSelectedItems?.first
                else { return }
            
            let cell = self.collectionView.cellForItem(at: indexPath) as! ImageCell
            cell.collectionView.images?.append(compressedImage)

            let item = self.initialValue[indexPath.section].items[indexPath.item]
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                
                if let prjID = self.prjData.prjInformation.projectID {
                    DataStorageService.sharedDataStorageService.storeImages(prjID: prjID, name: item.Name, images: [compressedImage]) { (imageAttrs, error) in
                        if let err = error {
                            print("Error = \(err)")
                        }
                        
                        guard let imgAttrs = imageAttrs else { return }
                        let imgAttr = SiteAssessmentImageArrayStructure(key: item.Name, images: imgAttrs)
                        
                        if let index = self.prjData.prjImageArray.firstIndex(where: {$0.key == item.Name}) {
                            self.prjData.prjImageArray[index] = imgAttr
                        } else {
                            self.prjData.prjImageArray.append(imgAttr)
                        }
                        
                        self.initialValue[indexPath.section].items[indexPath.item].Value = "Yes"
                    }
                }
            }
        }
    }
    
    func photoPickerViewController(_ picker: YMSPhotoPickerViewController!, didFinishPickingImages photoAssets: [PHAsset]!) {
        picker.dismiss(animated: true) {
            let imageManager = PHImageManager.init()
            let options = PHImageRequestOptions.init()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            options.isSynchronous = true
            
            var imageArray: [UIImage] = []
            
            for asset: PHAsset in photoAssets
            {
                // let scale = UIScreen.main.scale
                // let targetSize = CGSize(width: (self.collectionView.bounds.width - 20*2) * scale, height: (self.collectionView.bounds.height - 20*2) * scale)
                let targetSize = CGSize(width: 84.0, height: 84.0)
                imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options, resultHandler: { (image, info) in
                    
                    if let compressedImage = image?.compressed() {
                        imageArray.append(compressedImage)
                    }
                })
            }
                        
            guard let indexPath = self.collectionView.indexPathsForSelectedItems?.first else { return }
            
            let cell = self.collectionView.cellForItem(at: indexPath) as! ImageCell
            
            cell.collectionView.images = imageArray
            
            let item = self.initialValue[indexPath.section].items[indexPath.item]
            
            DispatchQueue.main.async {
                cell.collectionView.reloadData()
                if let prjID = self.prjData.prjInformation.projectID {
                    DataStorageService.sharedDataStorageService.storeImages(prjID: prjID, name: item.Name, images: imageArray) {(imageAttrs, error) in
                        if let err = error {
                            print("Error = \(err)")
                        }
                        
                        guard let imgAttrs = imageAttrs else { return }
                        let imgAttr = SiteAssessmentImageArrayStructure(key: item.Name, images: imgAttrs)
                        
                        if let index = self.prjData.prjImageArray.firstIndex(where: {$0.key == item.Name}) {
                            self.prjData.prjImageArray[index] = imgAttr
                        } else {
                            self.prjData.prjImageArray.append(imgAttr)
                        }

                        self.initialValue[indexPath.section].items[indexPath.item].Value = "Yes"
                    }
                }
            }
            
        }
    }
}

extension NewProjectReportViewController: SelectionCellDelegate {
    func buttonDidClicked(button: MyCheckBox, indexPath: IndexPath) {
        
        guard let question = getQuestionByIndexPath(indexPath: indexPath),
            let value = button.title(for: .normal)
            else { return }
        
        switch question.QType {
        case .singleSelection:
            let cell = self.collectionView.cellForItem(at: indexPath) as! SingleSelectionCell
            cell.buttonGroup.forEach { $0.isChecked = false }
        case .selectionWithImage:
            let cell = self.collectionView.cellForItem(at: indexPath) as! SelectionWithImageCell
            cell.OptionGroup.forEach { $0.isChecked = false }
        default:
            return
        }
        
        button.isChecked = true
        initialValue[indexPath.section].items[indexPath.row].Value = value

        if question.Interdependence == "Yes" {
            let relatedQuestions = self.prjData.prjQuestionnaire[indexPath.section].Questions.enumerated().filter({$0.element.Dependent?.first?.key == question.Key && $0.element.Dependent?.first?.value != value})
            
            if let firstIndex = relatedQuestions.first?.offset, let lastIndex = relatedQuestions.last?.offset {
                let rangeExpression = firstIndex ... lastIndex
                
                self.initialValue[indexPath.section].items.enumerated().forEach { (index, element) in
                    prjData.prjQuestionnaire[indexPath.section].Questions[index].Value = element.Value
                }
                
                let eachSections = self.prjData.prjQuestionnaire.map { row -> EachSection in
                    return EachSection(model: row.Name, items: row.Questions)
                }
                
                self.initialValue = eachSections
                self.initialValue[indexPath.section].items.replaceSubrange(rangeExpression, with: [])
                
            }
        }
        sections.accept(initialValue)
    }
}

// MARK: UITextViewDelegate
extension NewProjectReportViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Notes: " {
            textView.text = ""
            
            textView.textColor = UIColor.black
        }
    }
     
    func textViewDidEndEditing(_ textView: UITextView) {
        print("textView end.")
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
        }
        
        return true
    }
}

// MARK: TableViewIndexDelegate, TableViewIndexDataSource
extension NewProjectReportViewController: TableViewIndexDelegate, TableViewIndexDataSource {
    func indexItems(for tableViewIndex: TableViewIndex) -> [UIView] {
        let uiViews = initialValue.enumerated().map { (offset, element) -> [UIView] in
            let items = element.items.enumerated().map({(arg) -> UIView in
                
                let (index, question) = arg
                let text = String("\(offset):\(index)")
                let label = StringItem(text: text)
                
                label.tintColor = ( question.Value != "" ) ? UIColor(named: "PSC_Green") : UIColor.lightGray
                return label
            })
            
            return items
        }
        
        return Array(uiViews.joined())
    }
    
    func updateIndexItems(indexPath: IndexPath, checked: Bool) {
        
        let text = String("\(indexPath.section):\(indexPath.row)")
        
        UIView.animate(withDuration: 0.25, animations: {
            if let item = self.tableViewIndex.items.filter({
                let label = $0 as! UILabel
                return label.text == text
            }).first {
                item.tintColor = checked ? UIColor(named: "PSC_Green") : UIColor.red
            } else {
                print("No such item.")
            }
        })
    }

    func mapIndexItemToSection(_ indexItem: IndexItem, index: Int) -> IndexPath? {
        guard let label             = indexItem as? UILabel,
            let text                = label.text,
            let stringSectionIndex  = text.split(separator: ":").first,
            let stringRowIndex      = text.split(separator: ":").last,
            let intSectionIndex     = Int(stringSectionIndex),
            let intRowIndex         = Int(stringRowIndex)
            else {
                return nil
        }
        
        var secIndex = 0
        var rowIndex = 0
        var locked = false
        _ = initialValue.compactMap({$0.items.count}).enumerated().reduce(0) { (sum, arg1) -> Int in
            
            let (offset, next) = arg1
            if sum + next > index, locked == false {
                secIndex = offset
                rowIndex = index - sum
                
                locked = true
            }
            
            return sum + next
        }
        print("index = \(index)")
        print("secIndex = \(secIndex), rowIndex = \(rowIndex)")
        print("intSectionIndex = \(intSectionIndex), intRowIndex = \(intRowIndex)")
        
        return IndexPath(row: intRowIndex, section: intSectionIndex)
    }
    
    func tableViewIndex(_ tableViewIndex: TableViewIndex, didSelect item: UIView, at index: Int) -> Bool {
        
        guard let indexPath    = mapIndexItemToSection(item, index: index),
            let collectionView = self.collectionView,
            let attrs          = collectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: indexPath)
            else {
                return false
        }
        
        var contentInset: UIEdgeInsets
        if #available(iOS 11.0, *) {
            contentInset = collectionView.adjustedContentInset
        } else {
            contentInset = collectionView.contentInset
        }
        let yOffset = min(attrs.frame.origin.y, collectionView.contentSize.height - collectionView.frame.height + contentInset.top)
        collectionView.contentOffset = CGPoint(x: 0, y: yOffset - contentInset.top)
        
        return true
    }
    
    fileprivate func updateIndexVisibility() {
        /*
        guard let visibleIndexes = tableView.indexPathsForVisibleRows else {
            return
        }
        for indexPath in visibleIndexes {
            if (dataSource.titleForHeaderInSection((indexPath as NSIndexPath).section)) != nil {
                continue
            }
            let cellFrame = view.convert(tableView.rectForRow(at: indexPath), to: nil)
            
            if view.convert(uncoveredTableViewFrame(), to: nil).intersects(cellFrame) {
                tableViewIndexController.setHidden(true, animated: true)
                return
            }
        }
        tableViewIndexController.setHidden(false, animated: true)
         */
    }
    
    fileprivate func updateHighlightedItems() {
        /*
        let frame = uncoveredTableViewFrame()
        var visibleSections = Set<Int>()
        for section in 0..<collectionView.numberOfSections {
            if (frame.intersects(collectionView.rect(forSection: section)) ||
                frame.intersects(collectionView.rectForHeader(inSection: section))) {
                visibleSections.insert(section)
            }
        }
        
        example.trackSelectedSections(visibleSections)
         */
    }
}

class BackgroundView : UIView {
    
    enum Alpha : CGFloat {
        case normal = 0.3
        case highlighted = 0.6
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = 6
        layer.masksToBounds = false
        backgroundColor = UIColor.lightGray.withAlphaComponent(Alpha.normal.rawValue)
        isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
