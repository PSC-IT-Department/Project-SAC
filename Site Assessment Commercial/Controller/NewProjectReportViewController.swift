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
import RxGesture

import Photos

import YangMingShan
import SwifterSwift
import MYTableViewIndex
import PopupDialog
import NotificationBannerSwift

enum ReviewButtonStatus: String {
    case review = "Save & Review"
    case save   = "Save"
}

/*
class NewProjectReportViewController: UIViewController {
    
    typealias EachSection = AnimatableSectionModel<String, QuestionStructure>

    @IBOutlet weak var reviewButton: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    static let id = "NewProjectReportViewController"
    private let sectionID = "Section"
    
    private let MSCellID     = "MultipleSelectionCell"
    private let InputsCellID = "InputsCell"
    private let NotesCellID  = "NotesCell"
    private let SWIOCellID   = "SelectionsWithImageOtherCell"
    private let TTCellID     = "TrussTypeCell"
    private let ImageCellID  = "ImageCell"
    private let IGCellID     = "ImageGalleryCell"
    
    fileprivate var tableViewIndexController: TableViewIndexController!
    fileprivate(set) var tableViewIndex: TableViewIndex!

    private var prjData: SiteAssessmentDataStructure!
    
    private var totalMissing: Int = -1 {
        didSet {
            if totalMissing == 0 {
                setupReviewButton(status: .review)
            }
        }
    }
    
    private var sections = BehaviorRelay(value: [EachSection]())
    
    private let disposeBag = DisposeBag()
    
    private var initialValue: [EachSection]! {
        didSet {
            let count = initialValue.reduce(0) { (result, question) -> Int in
                let questionCount = question.items.filter({
                    $0.Mandatory == "Yes" && ($0.Value == nil || $0.Value == "")}).count
                return result + questionCount
            }
            
            totalMissing = count
        }
    }
    
    static func instantiateFromStoryBoard() -> NewProjectReportViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: id) as? NewProjectReportViewController
        viewController?.prjData = DataStorageService.shared.retrieveCurrentProjectData()
        
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
        setupDelegate()
        setupReviewButton(status: .save)
        setupReviewButtonTapHandling()
    }
}

extension NewProjectReportViewController {
    func setupView() {
        title = "Questionnaire"
        // https://stackoverflow.com/questions/28733936/change-color-of-back-button-in-navigation-bar @Tiep Vu Van
        navigationController?.navigationBar.tintColor = UIColor(named: "PSC_Blue")
        setBackground()
    }
    
    func setupCollectionViewCell() {
        
        let nibMSCell = UINib(nibName: MSCellID, bundle: nil)
        collectionView.register(nibMSCell, forCellWithReuseIdentifier: MSCellID)
        
        let nibInputsCell = UINib(nibName: InputsCellID, bundle: nil)
        collectionView.register(nibInputsCell, forCellWithReuseIdentifier: InputsCellID)
        
        let nibNotesCell = UINib(nibName: NotesCellID, bundle: nil)
        collectionView.register(nibNotesCell, forCellWithReuseIdentifier: NotesCellID)

        let nibSWIOCell = UINib(nibName: SWIOCellID, bundle: nil)
        collectionView.register(nibSWIOCell, forCellWithReuseIdentifier: SWIOCellID)

        let nibTTCell = UINib(nibName: TTCellID, bundle: nil)
        collectionView.register(nibTTCell, forCellWithReuseIdentifier: TTCellID)

        let nibImageCell = UINib(nibName: ImageCellID, bundle: nil)
        collectionView.register(nibImageCell, forCellWithReuseIdentifier: ImageCellID)
    }
    
    func setupDataSource() {
        initialValue = loadData()
        
        let (configureCollectionViewCell, configureSupplementaryView) = collectionViewDataSourceUI()
        
        let cvReloadDataSource = RxCollectionViewSectionedReloadDataSource (
            configureCell: configureCollectionViewCell,
            configureSupplementaryView: configureSupplementaryView
        )
        
        sections
            .asObservable()
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
            let application = UIApplication.shared
            
            switch application.userInterfaceLayoutDirection {
            case .rightToLeft:
                frame.origin = CGPoint(x: frame.origin.x + 3, y: frame.origin.y)
            default:
                frame.origin = CGPoint(x: frame.origin.x - 3, y: frame.origin.y)
            }
            
            tableIndex.frame = frame
        }
        
        tableViewIndexController.tableViewIndex.delegate = self
        tableViewIndexController.tableViewIndex.dataSource = self
        tableViewIndexController.tableViewIndex.font = UIFont.systemFont(ofSize: 10.0)
        tableViewIndex = tableViewIndexController.tableViewIndex
    }
    
    func addQuestions(indexPath: IndexPath, value: String) {
        
        guard let question = getQuestionByIndexPath(indexPath: indexPath) else { return }
        guard let data = prjData else { return }
        let secNum = indexPath.section
        let questions = data.prjQuestionnaire[secNum].questions
        let relatedQuestions = questions.filter({$0.Dependent?.first?.key == question.Key})
        
        let relatedIndices = relatedQuestions.compactMap({questions.firstIndex(of: $0)})
        
        guard let count = Int(value),
            let option = question.Options?.first
            else { return }
        
        let range = option.split(separator: "-").compactMap({Int($0.trimmingCharacters(in: .whitespaces))})
        
        guard range.count == 2,
            let first = range.first,
            let last = range.last,
            (first ... last).contains(count)
            else { return }
        
        let repeatQuestions = Array(repeating: relatedQuestions, count: count)
        let array = repeatQuestions.enumerated().compactMap { (offset, element) -> [QuestionStructure] in
            
            var e = element
            if offset > 0 {
                e = e.compactMap({ question -> QuestionStructure in
                    var q = question
                    
                    q.Key.append("_\(offset)")
                    q.Name.append("_\(offset)")
                    
                    return q
                })
            }
            
            return e
            }.joined()
        
        guard let firstIndex = relatedIndices.first,
            let lastIndex = relatedIndices.last
            else { return }
        
        initialValue[indexPath.section].items.replaceSubrange(firstIndex ... lastIndex, with: array)
        
        reloadData()
        reloadIndexItems()
    }
    
    func setupCellTapHandling() {
        collectionView
            .rx
            .itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let item = self?.getQuestionByIndexPath(indexPath: indexPath) else { return }
                
                switch item.QType {
                    
                case .image:
                    if self?.checkPermission() == true {
                        let pickerViewController = YMSPhotoPickerViewController()
                        pickerViewController.numberOfPhotoToSelect = 9
                        
                        self?.yms_presentCustomAlbumPhotoView(pickerViewController, delegate: self)
                        
                    } else {
                        let title = item.Name
                        let message = "No permission to access, please allow in settings."
                        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                        
                        let confirmAction = UIAlertAction(title: "Confrim", style: .default, handler: nil)
                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                        
                        alertController.addAction(confirmAction)
                        alertController.addAction(cancelAction)
                        
                        self?.present(alertController, animated: true, completion: nil)
                    }
                    
                case .inputs:
                    guard let options = item.Options else { return }

                    let alertController = UIAlertController(title: item.Name, message: nil, preferredStyle: .alert)
                    
                    for option in options {
                        alertController.addTextField(configurationHandler: { textField in
                            textField.placeholder  = option
                            textField.keyboardType = .numberPad
                            
                            // Fix for UIButtonBarStackView constraints problem
                            // https://openradar.appspot.com/32355534
                            
                            textField.autocorrectionType = .no
                            textField.inputAssistantItem.leadingBarButtonGroups = []
                            textField.inputAssistantItem.trailingBarButtonGroups = []
                            
                            textField.returnKeyType = (option == options.last) ? .done : .next
                        })
                    }
                    
                    let confirmAction = UIAlertAction(title: "Confirm", style: .default) { _ in
                        let texts = alertController.textFields?.compactMap({ (textField) -> String? in
                            if let text = textField.text {
                                let charSet = CharacterSet(charactersIn: text)
                                return CharacterSet.decimalDigits.isSuperset(of: charSet) ? text: nil
                            } else {
                                return nil
                            }
                        })
                        
                        guard texts?.count == alertController.textFields?.count else { return }
                        
                        let values = texts?.joined(separator: " x ")
                        
                        self?.updateValue(indexPath: indexPath, value: values)
                        
                        if item.Interdependence == "Yes" {
                            //                                self?.addQuestions(indexPath: indexPath, value: values)
                        }
                        
                        self?.reloadData()
                    }
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    
                    alertController.addAction(confirmAction)
                    alertController.addAction(cancelAction)
                    self?.present(alertController, animated: true, completion: nil)
                    
                case .trussType:
                    guard let option = item.Options?.first else { return }
                    let alertController = UIAlertController(title: item.Name, message: nil, preferredStyle: .alert)
                    
                    alertController.addTextField(configurationHandler: { (textField) in
                        textField.placeholder = option
                        textField.keyboardType = .default
                        textField.returnKeyType = .done
                    })
                    
                    let confirmAction = UIAlertAction(title: "Confirm", style: .default, handler: { _ in
                        guard let value = alertController.textFields?.first?.text else { return }
                        
                        self?.updateValue(indexPath: indexPath, value: value)
                        self?.reloadData()
                    })
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    
                    alertController.addAction(confirmAction)
                    alertController.addAction(cancelAction)
                    self?.present(alertController, animated: true, completion: nil)
                    
                default:
                    return
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
                    var data = self?.prjData,
                    let totalMissing = self?.totalMissing
                    else { return }
                
                data.prjQuestionnaire = initialValue.compactMap { SectionStructure(name: $0.model, questions: $0.items)}
                
                DataStorageService.shared.storeCurrentProjectData(data: data)
                DataStorageService.shared.storeData(withData: data, onCompleted: nil)
                
                let banner = StatusBarNotificationBanner(title: "Project data saved successfully.", style: .success)
                banner.show()
                
                if totalMissing == 0 {
                    if let vc = ReviewViewController.instantiateFromStoryBoard(withProjectData: data) {
                        self?.navigationController?.pushViewController(vc, animated: true)
                    }
                } else {
                    let title = "Project data saved successfully."
                    let msg = "Complete the questionnaire to proceed to next step, still Missing: \(totalMissing)."
                    let popup = PopupDialog(title: title, message: msg)
                    
                    let confirmButton = PopupDialogButton(title: "OK", action: nil)
                    
                    popup.addButton(confirmButton)
                    
                    self?.present(popup, animated: true, completion: nil)
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
    
    func setupReviewButton(status: ReviewButtonStatus) {
        switch status {
        case .save:
            let title = ReviewButtonStatus.save.rawValue
            reviewButton.setTitle(title, for: .normal)
            reviewButton.backgroundColor = UIColor(named: "PSC_Blue")
            reviewButton.setTitleColor(UIColor.white, for: .normal)
        case .review:
            let title = ReviewButtonStatus.review.rawValue
            reviewButton.setTitle(title, for: .normal)
            reviewButton.backgroundColor = UIColor(named: "PSC_Green")
            reviewButton.setTitleColor(UIColor.white, for: .normal)
        }
    }
    
    func getQuestionByIndexPath(indexPath: IndexPath) -> QuestionStructure? {
        return initialValue[indexPath.section].items[indexPath.row]
    }
    
    func setupViewModel() {
        sections.accept(initialValue)
    }
    
    func updateValue(indexPath: IndexPath, value: String?) {
        
        initialValue[indexPath.section].items[indexPath.row].Value = value
        
        let checked = (value == nil || value == "") ? false : true
        updateIndexItems(indexPath: indexPath, checked: checked)
    }
    
    func reloadData() {
        sections.accept(initialValue)
    }
    
    func loadData() -> [EachSection] {
        let eachSections = prjData.prjQuestionnaire.compactMap { section -> EachSection in
            let questions = section.questions.filter({
                $0.Mandatory == "Yes" || ($0.Value != "" && $0.Value != nil)
            })
            return EachSection(model: section.name, items: questions)
        }
        
        return eachSections
    }
    
    func collectionViewDataSourceUI() -> (
        CollectionViewSectionedDataSource<EachSection>.ConfigureCell,
        CollectionViewSectionedDataSource<EachSection>.ConfigureSupplementaryView
        ) {
            return ({ [unowned self] (_, cv, ip, item) in
                    
                    switch item.QType {
                    case .image:
                        let cellIdentifier = CellIdentifier<ImageCell>(reusableIdentifier: self.ImageCellID)
                        let cell = cv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)
                        
                        let nib = UINib(nibName: self.IGCellID, bundle: nil)
                        cell.collectionView.register(nib, forCellWithReuseIdentifier: self.IGCellID)

                        cell.setupCell(question: item)
                        
                        if let index = self.prjData.prjImageArray.firstIndex(where: {$0.key == item.Name}),
                            let imageAttrs = cell.imageAttrs {
                            self.prjData.prjImageArray[index].images = imageAttrs
                        }
                        
                        if !(cell.collectionView.images.count >= 2) {
                            self.updateValue(indexPath: ip, value: "Yes")
                        }
                        return cell
                        
                    case .notes:
                        let cellIdentifier = CellIdentifier<NotesCell>(reusableIdentifier: self.NotesCellID)
                        let cell = cv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)
                        
                        cell.setupCell(question: item)
                        
                        cell.textView
                            .rx
                            .didBeginEditing
                            .subscribe(onNext: {
                                if let textView = cell.textView, textView.text == item.Default {
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
                                self?.updateValue(indexPath: ip, value: cell.textView.text)
                                cell.textView.resignFirstResponder()
                            })
                            .disposed(by: cell.disposeBag)
                    
                        return cell
                        
                    case .multipleSelection:
                        let cellIdentifier = CellIdentifier<MultipleSelectionCell>(reusableIdentifier: self.MSCellID)
                        let cell = cv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)

                        cell.delegate = self
                        cell.indexPath = ip
                        cell.setupCell(with: item)
                        return cell
                        
                    case .inputs:
                        let cellIdentifier = CellIdentifier<InputsCell>(reusableIdentifier: self.InputsCellID)
                        let cell = cv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)

                        cell.setupCell(question: item)
                        
                        cell.imageView
                            .rx
                            .tapGesture()
                            .when(.recognized)
                            .subscribe(onNext: { [unowned self] (_) in
                                self.presentImageViewController(imageName: item.Image)
                           })
                            .disposed(by: cell.disposeBag)
                        
                        return cell
                        
                    case .selection:
                        let cellIdentifier = CellIdentifier<SelectionCell>(reusableIdentifier: self.SWIOCellID)
                        let cell = cv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)
                        
                        cell.delegate = self
                        cell.indexPath = ip
                        
                        cell.setupCell(question: item)

                        cell.imageView
                            .rx
                            .tapGesture()
                            .when(.recognized)
                            .subscribe(onNext: { [weak self] _ in
                                self?.presentImageViewController(imageName: item.Image)
                            })
                            .disposed(by: cell.disposeBag)
                        
                        return cell
                        
                    case .trussType:
                        let cellIdentifier = CellIdentifier<TrussTypeCell>(reusableIdentifier: self.TTCellID)
                        let cell = cv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)
                        
                        let imgAttrs = self.prjData.prjImageArray.first(where: {$0.key == item.Name})?.images

                        cell.setupCell(question: item, imageAttrs: imgAttrs)

                        cell.textField.isUserInteractionEnabled = false
                        cell.imageView
                            .rx
                            .tapGesture()
                            .when(.recognized)
                            .subscribe(onNext: { [weak self] (_) in
                                self?.presentImageViewController(imageName: item.Image)
                            })
                            .disposed(by: cell.disposeBag)
                        
                        return cell
                    }
                    
            }, { [unowned self] (ds, cv, kind, ip) in
                let section = cv.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: self.sectionID,
                    for: ip
                    // swiftlint:disable:next force_cast
                    ) as! CollectionReusableView
                
                section.labelSectionName.text = "\(ds[ip.section].model)"
                return section
            }
        )
    }
    
    private func presentImageViewController(imageName: String?) {
        if let photoName = imageName, photoName != "" {
            if let vc = ImageViewController.instantiateFromStoryBoard(imageName: photoName) {
                vc.photoName = photoName
                present(vc, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension NewProjectReportViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
        ) -> CGSize {
        
        let width = collectionView.bounds.width
        var height = CGFloat(50)
        
        if let item = getQuestionByIndexPath(indexPath: indexPath) {
            switch item.QType {
            case .image, .notes:
                height = CGFloat(400)
            case .multipleSelection:
                height = CGFloat(140)
            case .inputs, .selection:
                height = CGFloat(190)
            case .trussType:
                height = CGFloat(400)
            }
        }
        
        return CGSize(width: width, height: height)
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
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
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
        let title = "Allow photo album access?"
        let msg = "Need your permission to access photo albumbs"
        
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) in
            let application = UIApplication.shared
            let settingsURL = UIApplication.openSettingsURLString
            
            if let url = URL(string: settingsURL) {
                application.open(url, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(dismissAction)
        alertController.addAction(settingsAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func photoPickerViewControllerDidReceiveCameraAccessDenied(_ picker: YMSPhotoPickerViewController!) {
        let title = "Allow camera album access?"
        let msg = "Need your permission to take a photo"
        
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) in
            let application = UIApplication.shared
            let settingsURL = UIApplication.openSettingsURLString
            
            if let url = URL(string: settingsURL) {
                application.open(url, options: [:], completionHandler: nil)
            }
        }
        
        alertController.addAction(dismissAction)
        alertController.addAction(settingsAction)
        
        picker.present(alertController, animated: true, completion: nil)
    }
    
    func photoPickerViewController(_ picker: YMSPhotoPickerViewController!, didFinishPicking image: UIImage!) {
        picker.dismiss(animated: true) { [weak self] in
            
            guard let compressedImage = image.compressed(quality: 1.0),
                let indexPath = self?.collectionView.indexPathsForSelectedItems?.first,
                let item = self?.getQuestionByIndexPath(indexPath: indexPath),
                let prjID = self?.prjData.prjInformation.projectID
                else { return }
            
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
                
                DataStorageService.shared.storeImages(
                prjID: prjID,
                name: item.Name,
                images: [compressedImage]) { (imageAttrs, error) in
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
                }
            }
        }
    }
    
    func photoPickerViewController(
        _ picker: YMSPhotoPickerViewController!,
        didFinishPickingImages photoAssets: [PHAsset]!) {
        picker.dismiss(animated: true) { [weak self] in
            let imageManager = PHImageManager.init()
            let options = PHImageRequestOptions.init()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            options.isSynchronous = true
            
            var imageArray: [UIImage] = []
            
            for asset: PHAsset in photoAssets {
                let targetSize = CGSize(width: 84.0, height: 84.0)
                imageManager.requestImage(
                    for: asset,
                    targetSize: targetSize,
                    contentMode: .aspectFill,
                    options: options,
                    resultHandler: { (image, _) in
                    
                    if let compressedImage = image?.compressed(quality: 1.0) {
                        imageArray.append(compressedImage)
                    }
                })
            }
                        
            guard let indexPath = self?.collectionView.indexPathsForSelectedItems?.first,
                let item = self?.getQuestionByIndexPath(indexPath: indexPath),
                let prjID = self?.prjData.prjInformation.projectID
                else { return }
            
            DispatchQueue.main.async {
                DataStorageService.shared.storeImages(
                prjID: prjID,
                name: item.Name,
                images: imageArray) {(imageAttrs, error) in
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
                    self?.reloadData()
                }
            }
        }
    }
}

extension NewProjectReportViewController: SelectionCellDelegate {
    func buttonDidClicked(button: MyCheckBox, indexPath: IndexPath) {
        
        guard let question = getQuestionByIndexPath(indexPath: indexPath),
            var value = button.title(for: .normal)
            else { return }
        
        switch question.QType {
        case .multipleSelection:
            button.isChecked = !button.isChecked
            if value == "Other" {
                let alertViewController = UIAlertController(title: "Other", message: nil, preferredStyle: .alert)
                alertViewController.addTextField { (textField) in
                    textField.placeholder = "Other"
                    textField.returnKeyType = .done
                }
                
                let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak self] (_) in
                    if let textField = alertViewController.textFields?.first, let text = textField.text {
                        button.setTitle(text, for: .normal)
                        
                        if var values = question.Value?.split(separator: ",").compactMap({String($0)}) {
                            if let index = values.firstIndex(of: text) {
                                values.remove(at: index)
                            } else {
                                values.append(text)
                            }
                            value = values.joined(separator: ",")
                            self?.updateValue(indexPath: indexPath, value: value)
                        }
                    }
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                    button.isChecked = false
                    self?.updateValue(indexPath: indexPath, value: nil)
                    return
                }
                
                alertViewController.addAction(confirmAction)
                alertViewController.addAction(cancelAction)
                
                present(alertViewController, animated: true, completion: nil)
            }
            
            if var values = question.Value?.split(separator: ",").compactMap({String($0)}) {
                if let index = values.firstIndex(of: value) {
                    values.remove(at: index)
                } else {
                    values.append(value)
                }
                value = values.joined(separator: ",")
            }

        case .selection:
            guard let cell = collectionView.cellForItem(at: indexPath) as? SelectionCell else { return }
            cell.optionGroup.forEach { $0.isChecked = false }
            if value == "Other" {
                let alertViewController = UIAlertController(title: "Other", message: nil, preferredStyle: .alert)
                alertViewController.addTextField { (textField) in
                    textField.placeholder = "Other"
                    textField.returnKeyType = .done
                }
                
                let confirmAction = UIAlertAction(title: "Confirm", style: .default) {[weak self] (_) in
                    if let textField = alertViewController.textFields?.first, let text = textField.text {
                        value = text
                        button.setTitle(value, for: .normal)
                        self?.updateValue(indexPath: indexPath, value: value)
                        self?.reloadData()

                    }
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {[weak self] (_) in
                    button.isChecked = false
                    self?.updateValue(indexPath: indexPath, value: nil)
                    return
                }
                
                alertViewController.addAction(confirmAction)
                alertViewController.addAction(cancelAction)

                present(alertViewController, animated: true, completion: nil)
            }
 
        default:
            break
        }
        
        updateValue(indexPath: indexPath, value: value)
        reloadData()

        if question.Interdependence == "Yes" {
            showQuestionsBasedOnDependency(key: question.Key, indexPath: indexPath, newValue: value)
        }
    }
    
    private func addToValue(value: String?) -> String {
        if let value = value {
            var values = value.split(separator: ",").compactMap({String($0)})
            
            if let index = values.firstIndex(of: value) {
                values.remove(at: index)
            } else {
                values.append(value)
            }
            return values.joined(separator: ",")
        }
        
        return ""
    }
    
    private func showOtherPopup(indexPath: IndexPath, onCompleted: ((String?) -> Void)?) {
        let alertViewController = UIAlertController(title: "Other", message: nil, preferredStyle: .alert)
        alertViewController.addTextField { (textField) in
            textField.placeholder = "Other"
            textField.returnKeyType = .done
        }
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
            if let textField = alertViewController.textFields?.first, let text = textField.text {
                onCompleted?(text)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            onCompleted?(nil)
        }
        
        alertViewController.addAction(confirmAction)
        alertViewController.addAction(cancelAction)
        
        present(alertViewController, animated: true, completion: nil)
    }
    
    private func showQuestionsBasedOnDependency(key: String, indexPath: IndexPath, newValue: String) {
        
        guard var data = prjData else { return }
        
        if data.prjQuestionnaire[indexPath.section].questions[indexPath.row].Value == newValue { return }

        let secNum = indexPath.section
        let questions = data.prjQuestionnaire[secNum].questions
        let relatedQuestions = questions.filter({$0.Dependent?.first?.key == key})
        
        let (matchedQuestions, notMatchedQuestions) = relatedQuestions.stablePartition { question in
            question.Dependent?.first?.value == newValue
        }
        
        let newIndices = matchedQuestions.compactMap({questions.firstIndex(of: $0)})
        // Set the mantadory field of questions that matches the option to Yes
        newIndices.forEach { [weak self] (index) in
            let indexPath = IndexPath(row: index, section: secNum)
            var q = questions[index]
            
            q.Mandatory = "Yes"
            self?.updateQuestion(indexPath: indexPath, question: q)
            
            data.prjQuestionnaire[indexPath.section].questions[indexPath.row].Mandatory = "Yes"
        }
        
        let oldIndices = notMatchedQuestions.compactMap({questions.firstIndex(of: $0)})
        oldIndices.forEach { [weak self] (index) in
            let indexPath = IndexPath(row: index, section: secNum)
            var q = questions[index]
            
            q.Mandatory = "No"
            self?.updateQuestion(indexPath: indexPath, question: q)
            data.prjQuestionnaire[indexPath.section].questions[indexPath.row].Mandatory = "No"
        }
                
        let answeredQuestions = initialValue.map({$0.items}).joined().filter({ $0.Value != nil && $0.Value != "" })
        
        answeredQuestions.forEach {[weak self] (question) in
            self?.prjData.prjQuestionnaire.enumerated().forEach({ (offset, element) in
                if let row = element.questions.firstIndex(where: {$0.Name == question.Name && $0.Mandatory == "Yes"}) {
                    let indexPath = IndexPath(row: row, section: offset)
                    self?.prjData.prjQuestionnaire[indexPath.section].questions[indexPath.row].Value = question.Value
                }
            })
        }
        
        initialValue = loadData()
        
        reloadData()
        reloadIndexItems()
        
    }
    
    private func updateQuestion(indexPath: IndexPath, question: QuestionStructure) {
        prjData.prjQuestionnaire[indexPath.section].questions[indexPath.row] = question
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
                label.tintColor = ( question.Value != "" ) ? UIColor(named: "PSC_Blue") : UIColor.lightGray
                return label
            })
            
            return items
        }
        
        return Array(uiViews.joined())
    }
    
    func reloadIndexItems() {
        tableViewIndexController.tableViewIndex.reloadData()
    }
    
    func updateIndexItems(indexPath: IndexPath, checked: Bool) {
        
        let text = String("\(indexPath.section):\(indexPath.row)")
        
        guard let indexItem = tableViewIndex.items.first(where: { view in
            guard let label = view as? UILabel else {return false}
            return label.text == text
        }) else { return }
        
        UIView.animate(withDuration: 0.25, animations: {
            indexItem.tintColor = checked ? UIColor(named: "PSC_Blue") : UIColor.lightGray
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
        
        return IndexPath(row: intRowIndex, section: intSectionIndex)
    }
    
    func tableViewIndex(_ tableViewIndex: TableViewIndex, didSelect item: UIView, at index: Int) -> Bool {
        
        let kind = UICollectionView.elementKindSectionHeader
        guard let indexPath    = mapIndexItemToSection(item, index: index),
            let collectionView = collectionView,
            let attrs          = collectionView.layoutAttributesForSupplementaryElement(ofKind: kind, at: indexPath)
            else {
                return false
        }
        
        var contentInset: UIEdgeInsets
        
        if #available(iOS 11.0, *) {
            contentInset = collectionView.adjustedContentInset
        } else {
            contentInset = collectionView.contentInset
        }
        
        let x = attrs.frame.origin.y
        let y = collectionView.contentSize.height - collectionView.frame.height + contentInset.top
        
        let yOffset = min(x, y)
        collectionView.contentOffset = CGPoint(x: 0, y: yOffset - contentInset.top)
        
        return true
    }
}

 */
