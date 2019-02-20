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
    
    private enum CodingKeys: String, CodingKey {
        case Name
        case Key
        case QType = "Type"
        case Options
        case Default
        case Mandatory
        case Value
    }
    
    static func == (lhs: QuestionaireConfigs_QuestionsWrapper, rhs: QuestionaireConfigs_QuestionsWrapper) -> Bool {
        return lhs.Name == rhs.Name
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
        Value       = ""
        identity    = 0
    }
}

struct QuestionaireConfigs_SectionsWrapper: Codable {
    var Name: String
    var Questions: [QuestionaireConfigs_QuestionsWrapper]
}

struct QuestionnaireConfigsWrapper: Codable {
    var QuestionaireConfigs: [QuestionaireConfigs_SectionsWrapper]
}

class NewProjectReportViewController: UIViewController, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var reviewButton: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var sections = BehaviorRelay(value: [EachSection]())
    
    let disposeBag = DisposeBag()
    
    var initialValue: [EachSection]!
        
    var images: NSArray! = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
                
        initialValue = loadData()
        
//        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).estimatedItemSize = UICollectionViewFlowLayout.automaticSize
//        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInsetReference = .fromLayoutMargins

        let (configureCollectionViewCell, configureSupplementaryView) = NewProjectReportViewController.collectionViewDataSourceUI()

        let cvReloadDataSource = RxCollectionViewSectionedReloadDataSource (
            configureCell: configureCollectionViewCell,
            configureSupplementaryView: configureSupplementaryView
        )
        
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
                    
                        /*
                    case .singleSelection:
                        let cell = self?.collectionView.cellForItem(at: indexPath) as! SingleSelectionCell
                        
                        cell.buttonGroup.forEach({ (button) in
                            if button.isChecked, let text = button.title(for: .normal) {
                                self?.answerDictionary.updateValue(text, forKey: item.Key)
                                
//                                print(self?.answerDictionary)
                            }
                        })
                         */

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

                                DataStorageService.sharedDataStorageService.writeToAnswerDictionary(value: text, key: item.Key)
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
                            DataStorageService.sharedDataStorageService.writeToAnswerDictionary(value: value, key: item.Key)
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
                            DataStorageService.sharedDataStorageService.writeToAnswerDictionary(value: value, key: item.Key)
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
        
        setupReviewButton()

        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
    }
    
    func setupReviewButton() {
        let totalMissing = initialValue.reduce(0) { (result, section) -> Int in
            return result + section.items.count
        }
        
        print("totalMissing = \(totalMissing)")
        
        reviewButton.setTitleColor(UIColor.red, for: .normal)
        reviewButton.setTitle("Missing \(totalMissing)", for: .normal)
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
    
    /*
    func actionHandler(alert: UIAlertAction){
        if let indexPath = collectionView.indexPathsForSelectedItems?.first {
            self.initialValue![indexPath.section].items[indexPath.item].Value = alert.title!
            
            let question = self.initialValue![indexPath.section].items[indexPath.item]
            
            switch question.QType {
            case .singleSelection:
                let cell = self.collectionView.cellForItem(at: indexPath) as! SingleSelectionCell
                cell.buttonGroup.forEach {
                    $0.isChecked = false
                        
                    if let title = $0.title(for: .normal), title == alert.title {
                        $0.isChecked = true
                    }
                }
                
            case .singleInput:
                print("singleInput")
                
            default:
                print("do something in default")
            }

        }
    }
     */
    
    func loadData()->[EachSection] {
        guard let path = Bundle.main.url(forResource: "QuestionnaireConfigs", withExtension: "plist") else {
            print("QuestionnaireConfigs file cannot find.")
            return []
        }
        
        if let plistData = try? Data(contentsOf: path) {
            do {
                let decoder = PropertyListDecoder()
                
                let allData = try decoder.decode([QuestionaireConfigs_SectionsWrapper].self, from: plistData)
                
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
    
}

extension NewProjectReportViewController {
    static func collectionViewDataSourceUI() -> (
        CollectionViewSectionedDataSource<EachSection>.ConfigureCell,
        CollectionViewSectionedDataSource<EachSection>.ConfigureSupplementaryView
        ) {
            return (
                { (_, cv, ip, i) in
                    switch i.QType {
                    case .image:
                        let cell = cv.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: ip) as! ImageCell
                        cell.labelKey.text = i.Name
                        return cell
                        
                    case .ar:
                        let cell = cv.dequeueReusableCell(withReuseIdentifier: "ARCell", for: ip) as! ARCell
                        cell.labelKey.text = i.Name
                        return cell
                        
                    case .notes:
                        let cell = cv.dequeueReusableCell(withReuseIdentifier: "NotesCell", for: ip) as! NotesCell
                        cell.labelKey.text = i.Name
                        return cell
                        
                    case .singleInput:
                        let cell = cv.dequeueReusableCell(withReuseIdentifier: "SingleInputCell", for: ip) as! SingleInputCell
                        cell.labelKey.text = i.Name
                        return cell
                        
                    case .singleSelection:
                        let cell = cv.dequeueReusableCell(withReuseIdentifier: "SingleSelectionCell", for: ip) as! SingleSelectionCell
                        cell.labelKey.text = i.Name
                        
                        for (index, option) in i.Options.enumerated(){
                            cell.buttonGroup[index].setTitle(option, for: .normal)
                            cell.buttonGroup[index].isHidden = false
                        }
                        
                        cell.tapAction = { (button) in
                            cell.buttonGroup.forEach {
                                $0.isChecked = false
                            }
                            
                            button.isChecked = true
                            
                            let value = button.title(for: .normal)!
                            DataStorageService.sharedDataStorageService.writeToAnswerDictionary(value: value, key: i.Key)
                        }
                    
                        cell.imageviewReference.isHidden = true
                    
                        return cell
                        
                    case .threeInputs:
                        let cell = cv.dequeueReusableCell(withReuseIdentifier: "ThreeInputsCell", for: ip) as! ThreeInputsCell
                        cell.labelKey.text = i.Name
                        return cell
                        
                    case .twoInputs:
                        let cell = cv.dequeueReusableCell(withReuseIdentifier: "TwoInputsCell", for: ip) as! TwoInputsCell
                        cell.labelKey.text = i.Name
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
        
        // The access denied of camera is always happened on picker, present alert on it to follow the view hierarchy
        picker.present(alertController, animated: true, completion: nil)
    }
    
    func photoPickerViewController(_ picker: YMSPhotoPickerViewController!, didFinishPicking image: UIImage!) {
        picker.dismiss(animated: true) {

            let compressedImage = UIImage.resizeImage(image)
            self.images = [compressedImage]
            
            if let indexPath = self.collectionView.indexPathsForSelectedItems?.first {
                let item = self.initialValue[indexPath.section].items[indexPath.item]
                DataStorageService.sharedDataStorageService.writeToAnswerDictionary(value: "Yes", key: item.Key)
            }
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
//                SaveToCustomAlbum.shared.save(image: image)
            }
            
        }
    }
    
    func photoPickerViewController(_ picker: YMSPhotoPickerViewController!, didFinishPickingImages photoAssets: [PHAsset]!) {
        picker.dismiss(animated: true) {
            let imageManager = PHImageManager.init()
            let options = PHImageRequestOptions.init()
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            options.isSynchronous = false
            
            let mutableImages: NSMutableArray! = []
            
            for asset: PHAsset in photoAssets
            {
                let scale = UIScreen.main.scale
                let targetSize = CGSize(width: (self.collectionView.bounds.width - 20*2) * scale, height: (self.collectionView.bounds.height - 20*2) * scale)
                imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options, resultHandler: { (image, info) in
                    
                    let compressedImage = UIImage.resizeImage(image!)
                    mutableImages.add(compressedImage)
                })
            }
            
            self.images = mutableImages.copy() as? NSArray
            
            if let indexPath = self.collectionView.indexPathsForSelectedItems?.first {
                let cell = self.collectionView.cellForItem(at: indexPath) as! ImageCell
                    
                cell.collectionView.images = mutableImages.copy() as? NSArray
                
                let item = self.initialValue[indexPath.section].items[indexPath.item]
                
                DataStorageService.sharedDataStorageService.writeToAnswerDictionary(value: "Yes", key: item.Key)

                DispatchQueue.main.async {
                    cell.collectionView.reloadData()
                    
//                    SaveToCustomAlbum.saveImages(self.images)
                }
            }
        }
    }
}

/*
extension NewProjectReportViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // calculate text height
        
        let cell = self.collectionView.cellForItem(at: (self.collectionView.indexPathsForSelectedItems?.first)!) as! NotesCell
        
        let constraintRect = CGSize(width: textView.frame.width,
                                    height: .greatestFiniteMagnitude)
        
        let boundingBox = cell.textviewNotes.text.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [.font: textView.font!],
                                            context: nil)
        let height = ceil(boundingBox.height)
        
        // textViewHeightConstraint - your height constraint outlet from IB
        if height > cell.textViewNotesHeight.constant {
            cell.textViewNotesHeight.constant = height
            
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
}
*/

