//
//  NewProjectViewController.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-04-01.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

/*
import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import RxGesture

import Photos

import YangMingShan
import SwifterSwift
import MYTableViewIndex
import PopupDialog

class NewProjectViewController: UIViewController {
    
    typealias EachSection = AnimatableSectionModel<String, QuestionStructure>
    
    @IBOutlet weak var reviewButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var tableViewIndexController: TableViewIndexController!
    fileprivate(set) var tableViewIndex: TableViewIndex!
    
    private var prjData: SiteAssessmentDataStructure!
    
    private var totalMissing: Int = -1 {
        didSet {
            if self.totalMissing == 0 {
                setupReviewButton(status: .review)
            }
        }
    }
    
    private var sections = BehaviorRelay(value: [EachSection]())
    
    private let disposeBag = DisposeBag()
    
    private var initialValue: [EachSection]! {
        didSet {
            let count = initialValue.reduce(0) { (result, question) -> Int in
                return result + question.items.filter({$0.Mandatory == "Yes" && ($0.Value == nil || $0.Value == "")}).count
            }
            
            self.totalMissing = count
        }
    }
    
    static func instantiateFromStoryBoard(withProjectData data: SiteAssessmentDataStructure) -> NewProjectViewController {
        let viewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "NewProjectViewController") as! NewProjectViewController
        viewController.prjData = data
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupCollectionViewCell()
        setupDataSource()
        setupViewModel()
        setupIndexList()
        setupCellTapHandling()
        setupReviewButton(status: .save)
        setupReviewButtonTapHandling()
        
        tableView
            .rx
            .willDisplayCell
            .subscribe(onNext: { [unowned self] (cell, indexPath) in
                if let question = self.getQuestionByIndexPath(indexPath: indexPath), question.QType == .TrussType {
                    guard let cell = cell as? TrussTypeCell else { return }
                    
                    cell.collectionView.register(cellWithClass: ImageGalleryCell.self)
                    
                    cell.setupDataSource()
                }
            })
            .disposed(by: disposeBag)
    }
}

extension NewProjectViewController {
    func setupView() {
        self.title = "Questionnaire"
        // https://stackoverflow.com/questions/28733936/change-color-of-back-button-in-navigation-bar @Tiep Vu Van
        self.navigationController?.navigationBar.tintColor = UIColor(named: "PSC_Blue")
        self.setBackground()
    }
    
    func setupCollectionViewCell() {
        tableView.register(UINib(nibName: "MultipleSelectionCell"      , bundle: nil), forCellReuseIdentifier: "MultipleSelectionCell")
        tableView.register(UINib(nibName: "SelectionWithOtherCell"     , bundle: nil), forCellReuseIdentifier: "SelectionWithOtherCell")
        tableView.register(UINib(nibName: "ARCell"                     , bundle: nil), forCellReuseIdentifier: "ARCell")
        tableView.register(UINib(nibName: "InputsCell"                 , bundle: nil), forCellReuseIdentifier: "InputsCell")
        tableView.register(UINib(nibName: "NotesCell"                  , bundle: nil), forCellReuseIdentifier: "NotesCell")
        tableView.register(UINib(nibName: "SelectionWithImageOtherCell", bundle: nil), forCellReuseIdentifier: "SelectionsWithImageOtherCell")
        tableView.register(UINib(nibName: "TrussTypeCell"              , bundle: nil), forCellReuseIdentifier: "TrussTypeCell")
    }
    
    func setupDataSource() {
        initialValue = loadData()
        
        let (configureCell, titleForSection) = tableViewDataSourceUI()
        
        let cvReloadDataSource = RxTableViewSectionedReloadDataSource (
            configureCell: configureCell,
            titleForHeaderInSection: titleForSection
        )
        
        self.sections
            .asObservable()
            .bind(to: tableView.rx.items(dataSource: cvReloadDataSource))
            .disposed(by: disposeBag)
    }
    
    func setupIndexList() {
        let backgroundView = BackgroundView()
        
        tableViewIndexController = TableViewIndexController(scrollView: tableView)
        
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
        }
        
        tableViewIndexController.tableViewIndex.delegate = self
        tableViewIndexController.tableViewIndex.dataSource = self
        
        tableViewIndexController.tableViewIndex.font = UIFont.systemFont(ofSize: 10.0)
        
        tableViewIndex = tableViewIndexController.tableViewIndex
    }
    
    func addQuestions(indexPath: IndexPath, question: QuestionStructure) {
        let relatedQuestions = self.initialValue[indexPath.section].items.enumerated().filter({$0.element.Dependent?.first?.key == question.Key})
        
        guard let questionValue = question.Value,
            let count = Int(questionValue),
            let firstIndex = relatedQuestions.first?.offset,
            let lastIndex = relatedQuestions.last?.offset
            else { return }
        
        let array = Array(repeating: relatedQuestions, count: count).joined().enumerated().compactMap { (offset, element) -> QuestionStructure in
            
            var q = element.element
            q.Value = nil
            
            if offset > 0 {
                q.Key.append("_\(offset)")
                q.Name.append("_\(offset)")
            }
            
            return q
        }
        
        self.initialValue[indexPath.section].items.replaceSubrange(firstIndex ... lastIndex, with: array)
        
        setupViewModel()
    }
    
    func setupCellTapHandling() {
        tableView
            .rx
            .itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                if let item = self?.initialValue?[indexPath.section].items[indexPath.item] {
                    
                    switch item.QType {
                        
                    case .image:
                        if self?.checkPermission() == true {
                            let pickerViewController = YMSPhotoPickerViewController.init()
                            pickerViewController.numberOfPhotoToSelect = 9
                            
                            self?.yms_presentCustomAlbumPhotoView(pickerViewController, delegate: self)
                            
                        } else {
                            let alertController = UIAlertController(title: item.Name, message: "No permission to access, please allow in settings.", preferredStyle: .alert)
                            
                            let confirmAction = UIAlertAction(title: "Confrim", style: .default, handler: nil)
                            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                            
                            alertController.addAction(confirmAction)
                            alertController.addAction(cancelAction)
                            
                            self?.present(alertController, animated: true, completion: nil)
                        }
                        
                    case .inputs:
                        let alertController = UIAlertController(title: item.Name, message: nil, preferredStyle: .alert)
                        
                        guard let options = item.Options else { return }
                        
                        for option in options {
                            alertController.addTextField(configurationHandler: { textField in
                                textField.placeholder  = option
                                textField.keyboardType = .numberPad
                                textField.returnKeyType = (option == options.last) ? .done : .next
                            })
                        }
                        
                        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { _ in
                            guard let values = alertController.textFields?.compactMap({CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: $0.text ?? "")) ? $0.text : "" }).joined(separator: " x ") else { return }
                            
                            self?.updateValue(indexPath: indexPath, value: values)
                            self?.reloadData(indexPath: indexPath)
                        }
                        
                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                        
                        alertController.addAction(confirmAction)
                        alertController.addAction(cancelAction)
                        self?.present(alertController, animated: true, completion: nil)
                        
                    default:
                        return
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    func setupReviewButtonTapHandling() {
        reviewButton
            .rx
            .tap
            .subscribe(onNext: { [weak self] (_) in
                guard let initialValue = self?.initialValue,
                    let data = self?.prjData,
                    let totalMissing = self?.totalMissing
                    else { return }
                
                self?.prjData.prjQuestionnaire = initialValue.compactMap { return SectionStructure(name: $0.model, questions: $0.items)}
                
                DataStorageService.sharedDataStorageService.storeCurrentProjectData(data: data)
                
                if totalMissing == 0 {
                    let vc = ReviewViewController.instantiateFromStoryBoard(withProjectData: data)
                    self?.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let popup = PopupDialog(title: "Project data saved successfully.", message: "Complete the questionnaire to proceed to next step, still Missing: \(totalMissing).")
                    
                    let confirmButton = PopupDialogButton(title: "OK", action: nil)
                    
                    popup.addButton(confirmButton)
                    
                    self?.present(popup, animated: true, completion: nil)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func setupReviewButton(status: ReviewButtonStatus) {
        switch status {
        case .save:
            reviewButton.setTitle("Save", for: .normal)
            reviewButton.backgroundColor = UIColor(named: "PSC_Blue")
            reviewButton.setTitleColor(UIColor.white, for: .normal)
        case .review:
            reviewButton.setTitle("Review", for: .normal)
            reviewButton.backgroundColor = UIColor(named: "PSC_Green")
            reviewButton.setTitleColor(UIColor.white, for: .normal)
        }
    }
    
    func getQuestionByIndexPath(indexPath: IndexPath) -> QuestionStructure? {
        return initialValue[indexPath.section].items[indexPath.row]
    }
    
    func setupViewModel() {
        sections.accept(self.initialValue)
    }
    
    func updateValue(indexPath: IndexPath, value: String?) {
        initialValue[indexPath.section].items[indexPath.row].Value = value
        
        let checked = (value == nil || value == "") ? false : true
        updateIndexItems(indexPath: indexPath, checked: checked)
    }
    
    func reloadData(indexPath: IndexPath) {
        sections.accept(self.initialValue)
    }
    
    func loadData()->[EachSection] {
        
        DataStorageService.sharedDataStorageService.storeCurrentProjectData(data: prjData)
        
        let eachSections = self.prjData.prjQuestionnaire.compactMap { section -> EachSection in
            return EachSection(model: section.Name, items: section.Questions)
        }
        
        return eachSections
    }
    
    func tableViewDataSourceUI() -> (
        TableViewSectionedDataSource<EachSection>.ConfigureCell,
        TableViewSectionedDataSource<EachSection>.TitleForHeaderInSection
        ) {
            return (
                { (_, tv, indexPath, item) in
                    
                    switch item.QType {
                    case .image:
                        let cell = tv.dequeueReusableCell(withIdentifier: "ImageCell", for: indexPath) as! ImageCell
                        
                        let imgAttrs = self.prjData.prjImageArray.first(where: {$0.key == item.Name})?.images
                        cell.setupCell(question: item, imageAttrs: imgAttrs)
                        return cell
                        
                    case .ar:
                        let cell = tv.dequeueReusableCell(withIdentifier: "ARCell", for: indexPath) as! ARCell
                        cell.setupCell(with: item)
                        return cell
                        
                    case .notes:
                        let cell = tv.dequeueReusableCell(withIdentifier: "NotesCell", for: indexPath) as! NotesCell
                        
                        cell.setupCell(question: item)
                        
                        cell.textView
                            .rx
                            .didBeginEditing
                            .subscribe(onNext: {
                                if let textView = cell.textView, textView.text == "Notes: " {
                                    textView.text = ""
                                    textView.textColor = UIColor.black
                                }
                                
                            })
                            .disposed(by: cell.disposeBag)
                        
                        cell.textView
                            .rx
                            .didChange
                            .subscribe(onNext: {
                                if cell.textView.text.contains("\n") {
                                    cell.textView.resignFirstResponder()
                                }
                            })
                            .disposed(by: cell.disposeBag)
                        
                        cell.textView
                            .rx
                            .didEndEditing
                            .subscribe(onNext: { [weak self] (_) in
                                self?.updateValue(indexPath: indexPath, value: cell.textView.text)
                                cell.textView.resignFirstResponder()
                            })
                            .disposed(by: cell.disposeBag)
                        
                        return cell
                        
                    case .multipleSelection:
                        let cell = tv.dequeueReusableCell(withIdentifier: "MultipleSelectionCell", for: indexPath) as! MultipleSelectionCell
                        
                        cell.delegate = self
                        cell.indexPath = indexPath
                        cell.setupCell(with: item)
                        return cell
                        
                    case .inputs:
                        let cell = tv.dequeueReusableCell(withIdentifier: "InputsCell", for: indexPath) as! InputsCell
                        cell.setupCell(question: item)
                        
                        cell.imageView
                            .rx
                            .tapGesture()
                            .when(.recognized)
                            .subscribe(onNext: { _ in
                                if let photoName = item.Image, photoName != "" {
                                    let vc = ImageViewController.instantiateFromStoryBoard(withImageName: photoName)
                                    vc.photoName = photoName
                                    self.present(vc, animated: true, completion: nil)
                                }
                            })
                            .disposed(by: cell.disposeBag)
                        
                        return cell
                        
                    case .selectionsWithImageOther:
                        let cell = tv.dequeueReusableCell(withIdentifier: "SelectionsWithImageOtherCell", for: indexPath) as! SelectionsWithImageOtherCell
                        cell.delegate = self
                        cell.indexPath = indexPath
                        
                        cell.setupCell(question: item)
                        
                        cell.imageView
                            .rx
                            .tapGesture()
                            .when(.recognized)
                            .subscribe(onNext: { [weak self] _ in
                                if let photoName = item.Image, photoName != "" {
                                    let vc = ImageViewController.instantiateFromStoryBoard(withImageName: photoName)
                                    vc.photoName = photoName
                                    self?.present(vc, animated: true, completion: nil)
                                }
                            })
                            .disposed(by: cell.disposeBag)
                        
                        return cell
                        
                    case .TrussType:
                        let cell = tv.dequeueReusableCell(withIdentifier: "TrussTypeCell", for: indexPath) as! TrussTypeCell
                        
                        let imgAttrs = self.prjData.prjImageArray.first(where: {$0.key == item.Name})?.images
                        
                        cell.setupCell(question: item, imageAttrs: imgAttrs)
                        
                        /*
                         cell.collectionView
                         .rx
                         .setDelegate(self)
                         .disposed(by: cell.disposeBag)
                         
                         let dataSource = RxCollectionViewSectionedReloadDataSource<ImageGallerySection> (
                         configureCell: { (_, tv, indexPath, element) in
                         let imageGalleryCell = cell.collectionView.dequeueReusableCell(withReuseIdentifier: "ImageGalleryCell", for: indexPath) as! ImageGalleryCell
                         print("ImageGalleryCell")
                         //imageGalleryCell.imageView.image = cell.images?[indexPath.row]
                         return cell
                         },
                         configureSupplementaryView: { (ds, cv, kind, ip) in
                         let section = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Section", for: ip) as! CollectionReusableView
                         section.labelSectionName.text = "\(ds[ip.section].model)"
                         return section
                         }
                         )
                         
                         let data = [
                         ImageGallerySection(model: "section 1", items: ["Yes", "No"])
                         ]
                         
                         
                         cell.sections.accept(data)
                         
                         cell.sections
                         .asObservable()
                         .bind(to: cell.collectionView.rx.items(dataSource: dataSource))
                         .disposed(by: cell.disposeBag)
                         
                         cell.collectionView
                         .rx
                         .itemSelected
                         .subscribe(onNext: { [weak self] i in
                         print(#"Let me guess, it's .... It's \(String(describing: self?.generator.sections[i.section].items[i.item])), isn't it? Yeah, I've got it."#)
                         })
                         .disposed(by: cell.disposeBag)
                         */
                        return cell
                    }
                    
            },
                { (ds, section) -> String? in
                    return ds[section].model
            }
            )
    }
    
}

/*
// MARK: - UICollectionViewDelegateFlowLayout
extension NewProjectViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = collectionView.bounds.width
        var height = CGFloat(50)
        
        if let item = getQuestionByIndexPath(indexPath: indexPath) {
            switch item.QType {
            case .ar, .image, .notes:
                height = CGFloat(400)
            case .multipleSelection:
                height = CGFloat(140)
            case .inputs, .selectionsWithImageOther:
                height = CGFloat(190)
            case .TrussType:
                height = CGFloat(250)
            }
        }
        
        return CGSize(width: width, height: height)
    }
}
 */

// MARK: - YMSPhotoPickerViewControllerDelegate
extension NewProjectViewController: YMSPhotoPickerViewControllerDelegate {
    
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
            
        default:
            print("Unknown status")
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
                let indexPath = self.tableView.indexPathForSelectedRow,
                let item = self.getQuestionByIndexPath(indexPath: indexPath),
                let prjID = self.prjData.prjInformation.projectID
                else { return }
            
            let cell = self.tableView.cellForRow(at: indexPath) as! ImageCell
            cell.collectionView.images?.append(compressedImage)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                
                DataStorageService.sharedDataStorageService.storeImages(prjID: prjID, name: item.Name, images: [compressedImage]) { (imageAttrs, error) in
                    if let err = error {
                        print("Error = \(err)")
                    }
                    
                    guard let imgAttrs = imageAttrs else { return }
                    let imgAttr = ImageArrayStructure(key: item.Name, images: imgAttrs)
                    
                    if let index = self.prjData.prjImageArray.firstIndex(where: {$0.key == item.Name}) {
                        self.prjData.prjImageArray[index] = imgAttr
                    } else {
                        self.prjData.prjImageArray.append(imgAttr)
                    }
                    
                    self.updateValue(indexPath: indexPath, value: "Yes")
                }
            }
        }
    }
    
    func photoPickerViewController(_ picker: YMSPhotoPickerViewController!, didFinishPickingImages photoAssets: [PHAsset]!) {
        picker.dismiss(animated: true) { [weak self] in
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
            guard let indexPath = self?.tableView.indexPathForSelectedRow,
                let item = self?.getQuestionByIndexPath(indexPath: indexPath),
                let prjID = self?.prjData.prjInformation.projectID
                else { return }
            
            DispatchQueue.main.async {
                /*
                 let imageAttr = imageArray.enumerated().compactMap({ (offset, element) -> ImageAttributes in
                 return ImageAttributes(name: item.Name + "_\(offset)")
                 })
                 
                 let imgArr = ImageArrayStructure(key: item.Name, images: imageAttr)
                 
                 if let index = self?.prjData.prjImageArray.firstIndex(where: {$0.key == item.Name}) {
                 self?.prjData.prjImageArray[index] = imgArr
                 } else {
                 self?.prjData.prjImageArray.append(imgArr)
                 }
                 */
                DataStorageService.sharedDataStorageService.storeImages(prjID: prjID, name: item.Name, images: imageArray) {(imageAttrs, error) in
                    if let err = error {
                        print("Error = \(err)")
                    }
                    
                    guard let imgAttrs = imageAttrs else { return }
                    let imgAttr = ImageArrayStructure(key: item.Name, images: imgAttrs)
                    
                    if let index = self?.prjData.prjImageArray.firstIndex(where: {$0.key == item.Name}) {
                        self?.prjData.prjImageArray[index] = imgAttr
                    } else {
                        self?.prjData.prjImageArray.append(imgAttr)
                    }
                    
                    self?.updateValue(indexPath: indexPath, value: "Yes")
                    self?.reloadData(indexPath: indexPath)
                }
            }
        }
    }
}

extension NewProjectViewController: SelectionCellDelegate {
    func buttonDidClicked(button: MyCheckBox, indexPath: IndexPath) {
        
        guard let question = getQuestionByIndexPath(indexPath: indexPath),
            var value = button.title(for: .normal)
            else { return }
        
        switch question.QType {
        case .multipleSelection:
            if var values = question.Value?.split(separator: ",").compactMap({String($0)}) {
                if let index = values.firstIndex(of: value) {
                    values.remove(at: index)
                } else {
                    values.append(value)
                }
                value = values.joined(separator: ",")
            }
            
        case .selectionsWithImageOther:
            let cell = self.tableView.cellForRow(at: indexPath) as! SelectionsWithImageOtherCell
            cell.optionGroup.forEach { $0.isChecked = false }
            if value == "Other" {
                let alertViewController = UIAlertController(title: "Other", message: nil, preferredStyle: .alert)
                alertViewController.addTextField { (textField) in
                    textField.placeholder = "Other"
                }
                
                let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (action) in
                    if let textField = alertViewController.textFields?.first, let text = textField.text {
                        value = text
                        button.setTitle(value, for: .normal)
                        self.updateValue(indexPath: indexPath, value: value)
                    }
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                    button.isChecked = false
                    self.updateValue(indexPath: indexPath, value: nil)
                    return
                }
                
                alertViewController.addAction(confirmAction)
                alertViewController.addAction(cancelAction)
                
                self.present(alertViewController, animated: true, completion: nil)
            }
            
        default:
            break
        }
        
        button.isChecked = true
        self.updateValue(indexPath: indexPath, value: value)
        
        if question.Interdependence == "Yes" {
            let relatedQuestions = self.prjData.prjQuestionnaire[indexPath.section].Questions.enumerated().filter({$0.element.Dependent?.first?.key == question.Key && $0.element.Dependent?.first?.value != value})
            
            let array = self.initialValue.map({$0.items}).joined().filter({$0.Value != nil && $0.Value != ""})
            
            array.forEach { (question) in
                self.prjData.prjQuestionnaire.enumerated().forEach({ (offset, element) in
                    if let row = element.Questions.firstIndex(where: {$0.Name == question.Name}) {
                        self.prjData.prjQuestionnaire[offset].Questions[row].Value = question.Value
                    }
                })
            }
            
            let eachSections = self.prjData.prjQuestionnaire.map { EachSection(model: $0.Name, items: $0.Questions) }
            
            self.initialValue = eachSections
            
            if let firstIndex = relatedQuestions.first?.offset, let lastIndex = relatedQuestions.last?.offset {
                self.initialValue[indexPath.section].items.replaceSubrange(firstIndex ... lastIndex, with: [])
            }
            
            self.reloadData(indexPath: indexPath)
        }
    }
}

// MARK: TableViewIndexDelegate, TableViewIndexDataSource
extension NewProjectViewController: TableViewIndexDelegate, TableViewIndexDataSource {
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
        
        guard let indexItem = self.tableViewIndex.items.first(where: { view in
            let label = view as! UILabel
            return label.text == text
        }) else { return }
        
        UIView.animate(withDuration: 0.25, animations: {
            indexItem.tintColor = checked ? UIColor(named: "PSC_Green") : UIColor.lightGray
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
        
        /*
         print("index = \(index)")
         print("secIndex = \(secIndex), rowIndex = \(rowIndex)")
         print("intSectionIndex = \(intSectionIndex), intRowIndex = \(intRowIndex)")
         */
        
        return IndexPath(row: intRowIndex, section: intSectionIndex)
    }
    
    func tableViewIndex(_ tableViewIndex: TableViewIndex, didSelect item: UIView, at index: Int) -> Bool {
        let originalOffset = tableView.contentOffset
        
        guard let indexPath    = mapIndexItemToSection(item, index: index) else { return false }
        tableView.scrollToRow(at: indexPath, at: .top, animated: false)
 
        return tableView.contentOffset != originalOffset

        /*
        guard let indexPath    = mapIndexItemToSection(item, index: index),
            let tableView = self.tableView,
            let attrs          = tableView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: indexPath)
            else {
                return false
        }
        
        var contentInset: UIEdgeInsets
        
        if #available(iOS 11.0, *) {
            contentInset = tableView.adjustedContentInset
        } else {
            contentInset = tableView.contentInset
        }
        
        let yOffset = min(attrs.frame.origin.y, tableView.contentSize.height - tableView.frame.height + contentInset.top)
        tableView.contentOffset = CGPoint(x: 0, y: yOffset - contentInset.top)
        
        return true
         */
    }
    
    fileprivate func updateIndexVisibility() {
    }
    
    fileprivate func updateHighlightedItems() {
    }
}
*/
