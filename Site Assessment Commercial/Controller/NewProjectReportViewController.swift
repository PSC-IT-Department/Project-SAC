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

typealias NumberSection = AnimatableSectionModel<String, Int>
typealias EachSection = AnimatableSectionModel<String, QuestionaireConfigs_QuestionsWrapper>

struct QuestionaireConfigs_QuestionsWrapper: IdentifiableType, Codable, Equatable, Hashable {
    var identity: Int
    
    var Name: String
    var Key: String
    var QType: NewProjectReportCellType
    var Options: [String?]
    var Default: String?
    var Mandatory: String
    var Value: String?
    var Dependancy: String?
    
    private enum CodingKeys: String, CodingKey {
        case Name
        case Key
        case QType = "Type"
        case Options
        case Default
        case Mandatory
        case Value
        case Dependancy
    }
    
    static func == (lhs: QuestionaireConfigs_QuestionsWrapper, rhs: QuestionaireConfigs_QuestionsWrapper) -> Bool {
        return lhs.Name == rhs.Name && lhs.Key == rhs.Key
    }
    
    var hashValue: Int {
        return self.Name.hashValue
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        Name        = try values.decode(String.self, forKey: .Name)
        Key         = try values.decode(String.self, forKey: .Key)
        QType       = try values.decode(NewProjectReportCellType.self, forKey: .QType)
        Options     = try values.decode([String].self, forKey: .Options)
        Default     = try values.decode(String.self, forKey: .Default)
        Mandatory   = try values.decode(String.self, forKey: .Mandatory)
        Dependancy  = try values.decode(String.self, forKey: .Dependancy)
        Value       = ""
        identity    = 0
    }
    
    init(question: QuestionaireConfigs_QuestionsWrapper) {
        self.Name = question.Name
        self.Key         = question.Key
        self.QType       = question.QType
        self.Options     = question.Options
        self.Default     = question.Default
        self.Mandatory   = question.Mandatory
        self.Dependancy  = question.Dependancy
        self.Value       = question.Value
        self.identity    = question.identity
    }
    
}

struct QuestionaireConfigs_SectionsWrapper: Codable {
    var Name: String
    var Questions: [QuestionaireConfigs_QuestionsWrapper]
    
    init() {
        self.Name = ""
        self.Questions = []
    }
    
    init(name: String, questions: [QuestionaireConfigs_QuestionsWrapper]) {
        self.Name = name
        self.Questions = questions
    }
    
    init(withZohoData data: [String: String]) {
        self.Name = ""
        self.Questions = []
    }

}

struct QuestionnaireConfigsWrapper: Codable {
    var QuestionaireConfigs: [QuestionaireConfigs_SectionsWrapper]
}

class NewProjectReportViewController: UIViewController, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var reviewButton: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var prjData = SiteAssessmentDataStructure()
    
    var sections = BehaviorRelay(value: [EachSection]())
    
    var answerSheet: [[Bool]] = [[], [], []]
    
    let disposeBag = DisposeBag()
    
    var initialValue: [EachSection]!
    
    var images: [UIImage] = []
    
    var imagesDictionary: [String: NSArray]? = [:]
    
    var totalAnswerCount: Int {
        get {
            return answerSheet.reduce(0) { (result, row) -> Int in
                return result + row.count
            }
        }
    }
    
    var totalMissingAnwerCount: Int {
        get {
            return answerSheet.reduce(0) { (result, row) -> Int in
                return result + row.filter({ (item) -> Bool in
                    return !item
                }).count
            }
        }
    }
    
    static func instantiateFromStoryBoard(withProjectData data: SiteAssessmentDataStructure) -> NewProjectReportViewController {
        let viewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "NewProjectReportViewController") as! NewProjectReportViewController
        viewController.prjData = data
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Questionaire"
        
        initialValue = loadData()
        
        let (configureCollectionViewCell, configureSupplementaryView) = NewProjectReportViewController.collectionViewDataSourceUI()
        
        let cvReloadDataSource = RxCollectionViewSectionedReloadDataSource (
            configureCell: configureCollectionViewCell,
            configureSupplementaryView: configureSupplementaryView
        )
        
        setupAnswerSheet()
        setupReviewButton()
        
        self.sections.accept(initialValue)
        
        self.sections.asObservable()
            .bind(to: collectionView.rx.items(dataSource: cvReloadDataSource))
            .disposed(by: disposeBag)
        
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
                                
                                if item.Dependancy == "Yes" {
                                    let section = self?.initialValue[indexPath.section]
                                    let relatedSections = section?.items.filter({ (eachItem) -> Bool in
                                        return eachItem.Dependancy == item.Key
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
                                    
                                    self?.answerSheet[indexPath.section].replaceSubrange(rangeExpression, with: Array(repeating: false, count: newSections!.count))
                                    
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
                            var value = ""
                            if let textFields = alertController.textFields {
                                textFields.forEach({ (textField) in
                                    let textValue = cell.viewWithTag(textField.tag) as! UITextField
                                    if let text = textField.text {
                                        textValue.text = textField.text
                                        value.append(contentsOf: "\(text),")
                                    }
                                })
                            }
                            
                            value.removeLast()
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
                            var value = ""
                            if let textFields = alertController.textFields {
                                textFields.forEach({ (textField) in
                                    let textValue = cell.viewWithTag(textField.tag) as! UITextField
                                    if let text = textField.text {
                                        textValue.text = textField.text
                                        value.append(contentsOf: "\(text),")
                                    }
                                })
                            }
                            
                            value.removeLast()
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
                        print("Do something.")
                    }
                }
            })
            .disposed(by: disposeBag)
        
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
    }
    
    func setupReviewButton() {
        if totalMissingAnwerCount > 0 {
            reviewButton.backgroundColor = UIColor.red
            reviewButton.setTitleColor(UIColor.white, for: .normal)
            reviewButton.setTitle("Missing (\(totalMissingAnwerCount))", for: .normal)
        } else {
            reviewButton.setTitle("Review", for: .normal)
        }
    }
    
    func setupAnswerSheet() {
        for i in 0 ..< initialValue.count {
            answerSheet[i] = Array(repeating: false, count: initialValue[i].items.count)
        }
    }
    
    func updateData() {
        
        // Review Button
        setupReviewButton()
        
        // Update Data Source
        sections.accept(self.initialValue)
        
    }
    
    func checkPermission() -> Bool {
        
        var ret = false
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized:
            print("Access is granted by user")
            ret = true
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({
                (newStatus) in
                print("status is \(newStatus)")
                if newStatus ==  PHAuthorizationStatus.authorized {
                    /* do stuff here */
                    print("success")
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
    
    func loadData()->[EachSection] {
        guard let path = Bundle.main.url(forResource: "QuestionnaireConfigs", withExtension: "plist") else {
            print("QuestionnaireConfigs file cannot find.")
            return []
        }
        
        if let plistData = try? Data(contentsOf: path) {
            do {
                let decoder = PropertyListDecoder()
                
                let allData = try decoder.decode([QuestionaireConfigs_SectionsWrapper].self, from: plistData)
                
                self.prjData.prjQuestionnaire = allData
                
                return allData.map { row in
                    return EachSection(model: row.Name, items: row.Questions)
                }
            } catch let error as NSError {
                print(error)
                return []
            }
        }
        
        return []
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = collectionView.bounds.width
        var height = CGFloat(50)
        
        let section = indexPath.section
        
        let type = initialValue[section].items[indexPath.item].QType
        
        switch type {
        case .ar, .image, .notes:
            height = CGFloat(400)
        case .singleSelection:
            height = CGFloat(95)
        default:
            height = CGFloat(50)
        }
    
        return CGSize(width: width, height: height)
    }
    
    @IBAction func buttonReviewDidClicked(_ sender: UIButton) {
        
        // prjData.prjQuestionnaire = self.initialValue.map { return QuestionaireConfigs_SectionsWrapper(name: $0.model, questions: $0.items)}
        
        
        DataStorageService.sharedDataStorageService.storeCurrentProjectData(data: prjData)
        
        let vc = ReviewViewController.instantiateFromStoryBoard(withProjectData: prjData)
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension NewProjectReportViewController {
    static func collectionViewDataSourceUI() -> (
        CollectionViewSectionedDataSource<EachSection>.ConfigureCell,
        CollectionViewSectionedDataSource<EachSection>.ConfigureSupplementaryView
        ) {
            return (
                { (_, collectionView, indexPath, item) in
                    switch item.QType {
                    case .image:
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
                        cell.labelKey.text = item.Name
                        cell.setupCell(question: item)
                        return cell
                        
                    case .ar:
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ARCell", for: indexPath) as! ARCell
                        cell.labelKey.text = item.Name
                        return cell
                        
                    case .notes:
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NotesCell", for: indexPath) as! NotesCell
                        cell.labelKey.text = item.Name
                        cell.textviewNotes.text = item.Value
                        return cell
                        
                    case .singleInput:
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SingleInputCell", for: indexPath) as! SingleInputCell
                        cell.labelKey.text = item.Name
                        cell.textValue.text = item.Value
                        return cell
                        
                    case .singleSelection:
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SingleSelectionCell", for: indexPath) as! SingleSelectionCell
                        cell.labelKey.text = item.Name
                        
                        for (index, option) in item.Options.enumerated(){
                            cell.buttonGroup[index].setTitle(option, for: .normal)
                            cell.buttonGroup[index].isHidden = false
                        }
                        
                        cell.tapAction = { (button) in
                            cell.buttonGroup.forEach { $0.isChecked = false }
                            button.isChecked = true
                        }
                        
                        // cell.imageviewReference.isHidden = true
                        
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

extension NewProjectReportViewController: YMSPhotoPickerViewControllerDelegate {
    // MARK: - YMSPhotoPickerViewControllerDelegate
    
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
            
            if let compressedImage = image.compressed() {
                
                self.images = [compressedImage]
                
                if let indexPath = self.collectionView.indexPathsForSelectedItems?.first {
                    let item = self.initialValue[indexPath.section].items[indexPath.item]
                    
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        
                        let prjID = self.prjData.prjInformation["Project ID"]
                        DataStorageService.sharedDataStorageService.storeImages(prjID: prjID!, name: item.Name, images: self.images) { (imageAttrs, error) in
                            // Save to SiteAssessemnt Sheet
                        }
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
                let scale = UIScreen.main.scale
                let targetSize = CGSize(width: (self.collectionView.bounds.width - 20*2) * scale, height: (self.collectionView.bounds.height - 20*2) * scale)
                imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options, resultHandler: { (image, info) in
                    
                    if let compressedImage = image?.compressed() {
                        imageArray.append(compressedImage)
                    }
                })
            }
            
            self.images = imageArray
            
            if let indexPath = self.collectionView.indexPathsForSelectedItems?.first {
                let cell = self.collectionView.cellForItem(at: indexPath) as! ImageCell
                
                cell.collectionView.images = imageArray
                
                let item = self.initialValue[indexPath.section].items[indexPath.item]
                
                DispatchQueue.main.async {
                    cell.collectionView.reloadData()
                    let prjID = self.prjData.prjInformation["Project ID"]
                    DataStorageService.sharedDataStorageService.storeImages(prjID: prjID!, name: item.Name, images: self.images) {(imageAttrs, error) in
                        if let err = error {
                            // Send notification
                            print("Error = \(err)")
                            return
                        }
                        
                        if let imgAttrs = imageAttrs {
                            let imgAttr = SiteAssessmentImageArrayStructure(key: item.Name, images: imgAttrs)
                            
                            if let index = self.prjData.prjImageArray.firstIndex(where: {$0.key == item.Name}) {
                                self.prjData.prjImageArray[index] = imgAttr
                            } else {
                                self.prjData.prjImageArray.append(imgAttr)
                            }
                        }
                    }
                }
            }
        }
    }
}
