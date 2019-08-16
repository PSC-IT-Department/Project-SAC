//
//  ContentTableViewController.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-07-24.
//  Copyright © 2019 chyapp.com. All rights reserved.
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

typealias ContentSection = AnimatableSectionModel<String, QuestionStructure>

class ContentTableViewController: UIViewController {

    var upperViewController: ContainerViewController?

    @IBOutlet weak var tableView: UITableView!

    private var disposeBag = DisposeBag()
    private var sections = BehaviorRelay(value: [ContentSection]())

    var sectionData: SectionStructure!
    
    private var sectionMissing: Int = -1 {
        didSet {
            if sectionMissing == 0 {
                upperViewController?.sectionReadyToReview(section: sectionData.Name, numberOfQuestions: 1)
            }
        }
    }
    
    static let id = "ContentTableViewController"
    
    private let MSCellID     = "TvMultipleSelectionCell"
    private let InputsCellID = "TvInputsCell"
    private let NotesCellID  = "TvNotesCell"
    private let SWIOCellID   = "TvSelectionsWithImageOtherCell"
    private let TTCellID     = "TvTrussTypeCell"
    private let ImageCellID  = "TvImageCell"
    private let IGCellID     = "ImageGalleryCell"
    
    var initialValue: [ContentSection]! = [] {
        didSet {
            let count = initialValue.reduce(0) { (result, section) -> Int in

                let questionCount = section.items.filter({
                    $0.isHidden == "No" && ($0.Value == nil || $0.Value == "")}).count
                return result + questionCount
            }

            sectionMissing = count
        }
    }
    
    var prjImageArray: [ImageArrayStructure]! = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableViewCell()
        setupViewModel()
        setupDataSource()
        setupCellTapHandling()

        // Auto Layout
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 42.0
        
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 44.0
        
        tableView.backgroundColor = UIColor.clear
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        prjImageArray = DataStorageService.shared.retrieveCurrentProjectData().prjImageArray
    }
    
    static func instantiateFromStoryBoard(section: SectionStructure) -> ContentTableViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: id) as! ContentTableViewController
    
        viewController.sectionData = section
        
        return viewController
    }
    
    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        guard let tableViewLayoutMargin = tableViewLayoutMargin else { return }
        
        tableView.layoutMargins = tableViewLayoutMargin
    }
    
    @available(iOS 11.0, *)
    private var tableViewLayoutMargin: UIEdgeInsets? {
        guard let superview = parent?.view else {
            return nil
        }
        
        let defaultTableContentInsetLeft: CGFloat = 16
        return UIEdgeInsets(
            top: 0,
            left: superview.safeAreaInsets.left + defaultTableContentInsetLeft,
            bottom: 0,
            right: 0
        )
    }

    deinit {
        print("ContentTableViewController deinit")
    }
}

extension ContentTableViewController {
    func setupTableViewCell() {
        
        let nibMSCell = UINib(nibName: MSCellID, bundle: nil)
        tableView.register(nibMSCell, forCellReuseIdentifier: MSCellID)
        
        let nibInputsCell = UINib(nibName: InputsCellID, bundle: nil)
        tableView.register(nibInputsCell, forCellReuseIdentifier: InputsCellID)
        
        let nibNotesCell = UINib(nibName: NotesCellID, bundle: nil)
        tableView.register(nibNotesCell, forCellReuseIdentifier: NotesCellID)
        
        let nibSWIOCell = UINib(nibName: SWIOCellID, bundle: nil)
        tableView.register(nibSWIOCell, forCellReuseIdentifier: SWIOCellID)
        
        let nibTTCell = UINib(nibName: TTCellID, bundle: nil)
        tableView.register(nibTTCell, forCellReuseIdentifier: TTCellID)
        
        let nibImageCell = UINib(nibName: ImageCellID, bundle: nil)
        tableView.register(nibImageCell, forCellReuseIdentifier: ImageCellID)
    }
    
    private func tableViewDataSourceUI() -> (
        RxTableViewSectionedReloadDataSource<ContentSection>.ConfigureCell,
        RxTableViewSectionedReloadDataSource<ContentSection>.TitleForHeaderInSection
        ) {
            return ({[unowned self] (_, tv, ip, item) in
                switch item.QType {
                case .image:
                    let cellIdentifier = CellIdentifier<TvImageCell>(reusableIdentifier: self.ImageCellID)
                    let cell = tv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)

                    let nib = UINib(nibName: self.IGCellID, bundle: nil)
                    cell.collectionView.register(nib, forCellWithReuseIdentifier: self.IGCellID)
                    
                    cell.setupCell(question: item)
                    
                    if let index = self.prjImageArray.firstIndex(where: {$0.key == item.Name}),
                        let imageAttrs = cell.imageAttrs {
                        self.prjImageArray[index].images = imageAttrs
                    }

                    /*
                    if (cell.collectionView.images.count >= 2) {
//                        self.updateValue(indexPath: ip, value: "Yes")
                    }
                     */
                    return cell
                    
                case .notes:
                    let cellIdentifier = CellIdentifier<TvNotesCell>(reusableIdentifier: self.NotesCellID)
                    let cell = tv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)

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
                    let cellIdentifier = CellIdentifier<TvMultipleSelectionCell>(reusableIdentifier: self.MSCellID)
                    let cell = tv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)
                    
                    cell.delegate = self
                    cell.indexPath = ip
                    cell.setupCell(with: item)
                    
                    return cell
                    
                case .inputs:
                    let cellIdentifier = CellIdentifier<TvInputsCell>(reusableIdentifier: self.InputsCellID)
                    let cell = tv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)
                    
                    cell.setupCell(question: item)
                    
                    cell.imageField
                        .rx
                        .tapGesture()
                        .when(.recognized)
                        .subscribe({ [unowned self] (_) in
                            self.presentImageViewController(imageName: item.Image)
                        })
                        .disposed(by: cell.disposeBag)
                    
                    return cell
                    
                case .selection:
                    
                    let cellIdentifier = CellIdentifier<TvSelectionCell>(reusableIdentifier: self.SWIOCellID)
                    let cell = tv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)
                    
                    cell.delegate = self
                    cell.indexPath = ip
                    
                    cell.setupCell(question: item)
                    
                    cell.imageField
                        .rx
                        .tapGesture()
                        .when(.recognized)
                        .subscribe({ [unowned self] _ in
                            self.presentImageViewController(imageName: item.Image)
                        })
                        .disposed(by: cell.disposeBag)
                 
                    return cell
                    
                case .trussType:
                    let cellIdentifier = CellIdentifier<TvTrussTypeCell>(reusableIdentifier: self.TTCellID)
                    let cell = tv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)
                    
                    cell.textField.isUserInteractionEnabled = false
                    cell.imageTrussType
                        .rx
                        .tapGesture()
                        .when(.recognized)
                        .subscribe({ [unowned self] (_) in
                            self.presentImageViewController(imageName: item.Image)
                        })
                        .disposed(by: cell.disposeBag)
                    
                    let imgAttrs = self.prjImageArray.first(where: {$0.key == item.Name})?.images
                    
                    cell.setupCell(question: item, imageAttrs: imgAttrs)
                    
                    return cell
                }
            }, { (ds, section) -> String? in
                return ds[section].model
            }
            )
    }
    
    private func setupDataSource() {
        let (configureCell, titleForSection) = tableViewDataSourceUI()
        
        let dataSource = RxTableViewSectionedReloadDataSource<ContentSection>(
            configureCell: configureCell,
            titleForHeaderInSection: titleForSection
        )
        
        sections.asObservable()
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    fileprivate func loadData() -> [ContentSection] {
        var arr: [ContentSection] = []

        guard let firstContent = sectionData.Questions.first else {
            return arr
        }

        var count = 1
        let secName = sectionData.Name

        var items: [QuestionStructure] = []
        if secName == "ROOF & SHINGLE" || secName == "TRUSS & RAFTER" || secName == "BREAKER PANEL",
            let question = sectionData.Questions.first {
            let model = question.Name
            let firstSection = ContentSection(model: model, items: [firstContent])
            
            arr.append(firstSection)

            if let value = question.Value,
                let intValue = Int(value),
                let firstOption = question.Options?.first,
                let intFirst = Int(firstOption),
                intValue > intFirst {

                count = intValue
            }

            items = Array(sectionData.Questions.dropFirst().filter({$0.isHidden == "No"}))
        } else {
            items = Array(sectionData.Questions.filter({$0.isHidden == "No"}))
        }

        let repeatedItems = Array(repeating: items, count: count).flatMap({$0})

        let model = sectionData.Name
        let questionsSection = ContentSection(model: model, items: repeatedItems)

        arr.append(questionsSection)

        return arr
    }
    
    func setupViewModel() {
        initialValue = loadData()
        sections.accept(initialValue)
    }
    
    private func presentImageViewController(imageName: String?) {
        if let photoName = imageName, photoName != "" {
            if let vc = ImageViewController.instantiateFromStoryBoard(imageName: photoName) {
                vc.photoName = photoName
                present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func getQuestionByIndexPath(indexPath: IndexPath) -> QuestionStructure? {
        return initialValue[indexPath.section].items[indexPath.row]
    }
    
    func reloadData() {
        sections.accept(initialValue)
    }
    
    func addQuestions(indexPath: IndexPath, value: String?) {
    }
    
    func getData() -> [ContentSection] {
        return initialValue
    }

    func setupCellTapHandling() {
        tableView
            .rx
            .itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let item = self?.getQuestionByIndexPath(indexPath: indexPath) else { return }
                
                switch item.QType {
                case .image:
                    if self?.checkPermission() == true {
                        let pickerViewController = YMSPhotoPickerViewController()
                        pickerViewController.numberOfPhotoToSelect = 30
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
                            self?.addQuestions(indexPath: indexPath, value: values)
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
    
    func updateValue(indexPath: IndexPath, value: String?) {
        initialValue[indexPath.section].items[indexPath.row].Value = value
    }
}

extension ContentTableViewController: UITableViewDelegate {
    func setupDelegate() {
        tableView
            .rx
            .setDelegate(self)
            .disposed(by: disposeBag)
    }
    
    // https://github.com/RxSwiftCommunity/RxDataSources/issues/91
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clear
        
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16.0)
            header.textLabel?.textColor = UIColor.black
            header.accessibilityIdentifier = "MainTableViewHeader"
        }
    }
}

extension ContentTableViewController: SelectionCellDelegate {
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
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self]_ in
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
            guard let cell = tableView.cellForRow(at: indexPath) as? TvSelectionCell else { return }
            cell.optionGroup.forEach { $0.isChecked = false }
            if value == "Other" {
                let alertViewController = UIAlertController(title: "Other", message: nil, preferredStyle: .alert)
                alertViewController.addTextField { (textField) in
                    textField.placeholder = "Other"
                    textField.returnKeyType = .done
                }
                
                let confirmAction = UIAlertAction(title: "Confirm", style: .default) {[weak self] (_) in
                    if let textField = alertViewController.textFields?.first,
                        let text = textField.text {
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

        if question.Interdependence == "Yes" {
            showQuestionsBasedOnDependency(key: question.Key, indexPath: indexPath, newValue: value)
        }
        updateValue(indexPath: indexPath, value: value)
        reloadData()
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

    private func loadOriginalData() -> [ContentSection] {
        guard let data = sectionData else { return [] }

        let originalData = ContentSection(model: data.Name, items: data.Questions)

        return [originalData]
    }
    
    private func showQuestionsBasedOnDependency(key: String, indexPath: IndexPath, newValue: String) {
        guard let question = getQuestionByIndexPath(indexPath: indexPath) else { return }
        guard var data = initialValue else { return }

        let secCount = data.count
        if question.Key == "sa_numberOfRoofShingle" || question.Key == "sa_numberOfTrussRafter" || question.Key == "sa_numberOfBreakerPanels" {
            if let storedValue = question.Value,
                let intValue = Int(storedValue) {
                
                if intValue > secCount - 1 {
                    guard let relatedSections = data.last else { return }
                    let repeatedSections = Array(repeating: relatedSections, count: intValue - secCount + 1).enumerated().compactMap { (arg0) -> ContentSection in
                        
                        let (offset, element) = arg0
                        
                        var model = element.model
                        if let lastIndex = relatedSections.model.last, lastIndex.isNumber {
                            model = element.model.replacingOccurrences(of: "-1", with: "-2")
                        } else {
                            model = element.model + "-\(offset + 1)"
                        }
                        
                        let items = element.items.compactMap({ (question) -> QuestionStructure in
                            var q = question
                            q.Value = ""
                            return q
                        })
                        let section = ContentSection(model: model, items: items)
                        return section
                    }
                    
                    data += repeatedSections
                } else {
                    let newInitalValue = Array(initialValue.dropLast(abs(intValue - secCount + 1)))
                    data = newInitalValue
                }
            }

            initialValue = data
            return
        }

        let plainData = loadOriginalData()
        var questions = plainData[0].items.filter({!($0.Name.contains("#"))})

        let relatedQuestions = questions.filter({$0.Dependent?.first?.key == key})
        let (matchedQuestions, notMatchedQuestions) = relatedQuestions.stablePartition { question in
            question.Dependent?.first?.value == newValue
        }

        let newIndices = matchedQuestions.compactMap({questions.firstIndex(of: $0)})
        newIndices.forEach { questions[$0].isHidden = "No" }

        let oldIndices = notMatchedQuestions.compactMap({questions.firstIndex(of: $0)})
        oldIndices.forEach { questions[$0].isHidden = "Yes" }

        let answeredQuestions = data[indexPath.section].items.filter({$0.isHidden == "No" && ($0.Value != "" || $0.Value != nil) })
        answeredQuestions.forEach { (question) in
            if let index = questions.firstIndex(where: {$0.Name == question.Name}) {
                questions[index].Value = question.Value
            }
        }

        let showedQuestions = questions.filter({$0.isHidden == "No"})

        initialValue[indexPath.section].items = showedQuestions
    }
}

// MARK: - YMSPhotoPickerViewControllerDelegate
extension ContentTableViewController: YMSPhotoPickerViewControllerDelegate {
    
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
                let indexPath = self?.tableView.indexPathForSelectedRow,
                let item = self?.getQuestionByIndexPath(indexPath: indexPath),
                let prjID = DataStorageService.shared.currentProjectID
                else { return }
            
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
                
                DataStorageService.shared.storeImages (
                    prjID: prjID,
                    name: item.Name,
                    images: [compressedImage]) {[weak self] (imageAttrs, error) in
                        if let err = error {
                            print("Error = \(err)")
                        }
                        
                        guard let imgAttrs = imageAttrs else { return }
                        let imgAttr = ImageArrayStructure(key: item.Name, images: imgAttrs)
                        
                        if let index = self?.prjImageArray.firstIndex(where: {$0.key == item.Name}) {
                            self?.prjImageArray[index] = imgAttr
                        } else {
                            self?.prjImageArray.append(imgAttr)
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
            
            guard let indexPath = self?.tableView.indexPathForSelectedRow,
                let item = self?.getQuestionByIndexPath(indexPath: indexPath),
                let prjID = DataStorageService.shared.currentProjectID
                else {
                    print("No indexPath")
                    return
            }
            
            DispatchQueue.main.async {
                DataStorageService.shared.storeImages (
                    prjID: prjID,
                    name: item.Name,
                    images: imageArray) { [weak self] (imageAttrs, error) in
                        if let err = error {
                            print("Error = \(err)")
                        }
                        
                        guard let imgAttrs = imageAttrs else { return }
                        let imgAttr = ImageArrayStructure(key: item.Name, images: imgAttrs)
                        
                        if let index = self?.prjImageArray.firstIndex(where: {$0.key == item.Name}) {
                            self?.prjImageArray[index] = imgAttr
                        } else {
                            self?.prjImageArray.append(imgAttr)
                        }
                        
                        self?.updateValue(indexPath: indexPath, value: "Yes")
                        self?.reloadData()
                }
            }
        }
    }
}
