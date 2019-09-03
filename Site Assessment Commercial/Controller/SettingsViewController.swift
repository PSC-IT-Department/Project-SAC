//
//  SettingsViewController.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-23.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import UIKit
import MessageUI

import RxCocoa
import RxSwift
import RxDataSources

import GoogleSignIn
import PopupDialog

private typealias SettingsSection = AnimatableSectionModel<String, SettingsCellViewModel>

private struct SettingsCellViewModel: IdentifiableType, Equatable {
    static func == (lhs: SettingsCellViewModel, rhs: SettingsCellViewModel) -> Bool {
        return lhs.key == rhs.key
    }
    
    var identity: Int?
    
    let key: String
    let value: String?
    let iconName: String?
    let indicator: UITableViewCell.AccessoryType
    let action: (() -> Void)?
    
    init(key: String,
         value: String? = nil,
         iconName: String? = nil,
         indicator: UITableViewCell.AccessoryType = .none,
         action: (() -> Void)? = nil) {
        
        self.key = key
        self.value = value
        self.iconName = iconName
        self.indicator = indicator
        self.action = action
    }
}

class SettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private var disposeBag = DisposeBag()

    private var sections = BehaviorRelay(value: [SettingsSection]())
    
    fileprivate var cellViewModel: [[SettingsCellViewModel]] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupViewModel()
        setupDataSource()
        setupCellTapHandling()
        setupDelegate()
    }

    deinit {
        print("SettingsViewController deinit")
    }
}

extension SettingsViewController {

    private func setupView() {
        title = "Settings"
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.backgroundColor = UIColor(white: 0.667, alpha: 0.2)
        
        // Auto Layout
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 42.0
        
        // https://stackoverflow.com/questions/28733936/change-color-of-back-button-in-navigation-bar @Tiep Vu Van
        navigationController?.navigationBar.tintColor = UIColor(named: "PSC_Blue")
        setBackground()

    }
    
    private func setupViewModel() {
        
        let groupBy = DataStorageService.shared.retrieveGroupingOption()
        let mapType = DataStorageService.shared.retrieveMapTypeOption()
        
        let preferencesCellData = [
            SettingsCellViewModel(key: "Group By",
                                  value: groupBy.rawValue,
                                  action: {[unowned self] in
                                    let popup = self.setupGroupByPopup()
                                    self.present(popup, animated: true, completion: nil)}),
            SettingsCellViewModel(key: "Map Type",
                                  value: mapType.type.description,
                                  action: {[unowned self] in
                                    let popup = self.setupMapTypePopup()
                                    self.present(popup, animated: true, completion: nil)})
        ]
        
        var google = "Google"
        if let userEmail = GoogleService.shared.getEmail() {
            google.append(contentsOf: " - \(userEmail)")
        }
        
        let iconName = "icons8-google-48"
        let IntegrationCellData = [
            SettingsCellViewModel(key: google,
                                  iconName: iconName,
                                  indicator: .checkmark,
                                  action: {[weak self] in
                                    if let vc = GoogleAccessViewController.instantiateFromStoryBoard() {
                                        self?.navigationController?.pushViewController(vc, animated: true)
                                    }}),
            SettingsCellViewModel(key: "Zoho")
        ]
        
        let defaultCellData = [
            SettingsCellViewModel(key: "User Manual",
                                  indicator: .disclosureIndicator,
                                  action: {[weak self] in
                                    if let vc = UserManualViewController.instantiateFromStoryBoard() {
                                        self?.navigationController?.pushViewController(vc, animated: true)
                                    }}),
            SettingsCellViewModel(key: "Report a Bug?",
                                  indicator: .detailButton,
                                  action: {[weak self] in
                                    self?.sendLog()}),
            SettingsCellViewModel(key: "About this App",
                                  indicator: .disclosureIndicator,
                                  action: {[weak self] in
                                    if let vc = AboutViewController.instantiateFromStoryBoard() {
                                        self?.navigationController?.pushViewController(vc, animated: true)
                                    }}),
            SettingsCellViewModel(key: "Check Updates",
                                  indicator: .detailButton,
                                  action: {
                                    let bundle = Bundle.main
                                    if let myVer = bundle.infoDictionary?["CFBundleShortVersionString"] as? String,
                                        let url = URL(string: "https://polaronsolar.com/wp-content/uploads/sapp/index.html?cur=\(myVer)") {
                                        UIApplication.shared.open(url)
                                    }}),
            SettingsCellViewModel(key: "Clear Cache",
                                  action: {[weak self] in
                                    if let popupDialog = self?.setupClearCachePopup() {
                                        self?.present(popupDialog, animated: true, completion: nil)
                                    }
            })
        ]
        
        cellViewModel = [preferencesCellData, IntegrationCellData, defaultCellData]
        
        let settingsSections: [SettingsSection] = [
            SettingsSection(model: "Preferences", items: cellViewModel[0]),
            SettingsSection(model: "Integration", items: cellViewModel[1]),
            SettingsSection(model: "Default", items: cellViewModel[2])
        ]

        sections.accept(settingsSections)
    }
    
    private func setupDataSource() {
        let (configureCell, titleForSection) = tableViewDataSourceUI()
    
        let dataSource = RxTableViewSectionedReloadDataSource<SettingsSection>(
            configureCell: configureCell,
            titleForHeaderInSection: titleForSection
        )
    
        sections.asObservable()
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    private func setupCellTapHandling() {
        tableView
            .rx
            .itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                defer { self?.tableView.deselectRow(at: indexPath, animated: true) }
                let section = indexPath.section
                let row = indexPath.row
                guard let model = self?.cellViewModel[section][row] else { return }
                if let action = model.action {
                    action()
                }

            })
            .disposed(by: disposeBag)
    }
    
    private func setupDelegate() {
        tableView
            .rx
            .setDelegate(self)
            .disposed(by: disposeBag)
    }
    
    private func tableViewDataSourceUI() -> (
        RxTableViewSectionedReloadDataSource<SettingsSection>.ConfigureCell,
        RxTableViewSectionedReloadDataSource<SettingsSection>.TitleForHeaderInSection
        ) {
            return ({[unowned self] (_, tv, ip, i) in
                let cellId = "SettingsCell"
                let cellIdentifier = CellIdentifier<SettingsCell>(reusableIdentifier: cellId)
                let cell = tv.dequeueReusableCellWithIdentifier(identifier: cellIdentifier, forIndexPath: ip)
                let section = ip.section
                let row = ip.row
                
                let model = self.cellViewModel[section][row]

                cell.labelKey.text = model.key
                cell.labelValue.text = model.value
                cell.accessoryType = model.indicator
                
                if let iconName = model.iconName {
                    cell.imageIcon.image = UIImage(named: iconName)
                } else {
                    cell.imageIcon.image = nil
                }

                return cell
            }, { (ds, section) -> String? in
                return ds[section].model
            }
        )
    }
    
    func clearCache() {
        guard let dataStorageService = DataStorageService.shared,
            let homeDir = dataStorageService.homeDirectory
            else { return }

        let fileManager = FileManager.default

        /*
        let result = Result {try fileManager.removeItem(at: homeDir)}
        switch result {
        case .success:
            print("Success")
        case .failure(let error):
            print("Error = \(error)")
        }
         */
        
        guard let filePaths = try? fileManager.contentsOfDirectory(at: homeDir,
                                                                   includingPropertiesForKeys: nil,
                                                                   options: []) else { return }
        for filePath in filePaths {
            try? fileManager.removeItem(at: filePath)
        }
    }
    
    private func setupGroupByPopup() -> PopupDialog {
        let popupDialog = PopupDialog(title: "Group By", message: nil, transitionStyle: .zoomIn)
        
        let statusButton = DefaultButton(title: GroupingOptions.status.rawValue) {
            [weak self, weak dataStorageService = DataStorageService.shared] in
            dataStorageService?.storeGroupingOption(option: .status)
            self?.setupViewModel()
        }
        
        let scheduleDateButton = DefaultButton(title: GroupingOptions.scheduleDate.rawValue) {
            [weak self, weak dataStorageService = DataStorageService.shared] in
            dataStorageService?.storeGroupingOption(option: .scheduleDate)
            self?.setupViewModel()
        }
        
        let cancelAction = CancelButton(title: "Cancel", action: nil)
        
        popupDialog.addButtons([statusButton, scheduleDateButton, cancelAction])
        
        return popupDialog
    }
    
    private func setupMapTypePopup() -> PopupDialog {
        let popupDialog = PopupDialog(title: "Map Type", message: nil, transitionStyle: .zoomIn)
        
        let standardButton = DefaultButton(title: "Standard") {
            [weak self, weak dataStorageService = DataStorageService.shared] in
            dataStorageService?.storeMapTypeOption(option: .standard)
            self?.setupViewModel()
        }
        
        let satelliteButton = DefaultButton(title: "Satellite") {
            [weak self, weak dataStorageService = DataStorageService.shared] in
            dataStorageService?.storeMapTypeOption(option: .satellite)
            self?.setupViewModel()
        }
        
        let hybridButton = DefaultButton(title: "Hybrid") {
            [weak self, weak dataStorageService = DataStorageService.shared] in
            dataStorageService?.storeMapTypeOption(option: .hybrid)
            self?.setupViewModel()
        }
        
        let cancelAction = CancelButton(title: "Cancel", action: nil)
        
        popupDialog.addButtons([standardButton, satelliteButton, hybridButton, cancelAction])
        
        return popupDialog
    }
    
    private func setupClearCachePopup() -> PopupDialog {
        let title = "Clear Cache"
        let popupDialog = PopupDialog(title: title, message: nil, transitionStyle: .zoomIn)
        let confirmButton = DefaultButton(title: "Confirm") { [weak self] in
            self?.clearCache()
        }
        
        let cancelButton = CancelButton(title: "Cancel", action: nil)
        popupDialog.addButtons([confirmButton, cancelButton])
        
        return popupDialog
    }
}

// MARK: UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    
    // https://github.com/RxSwiftCommunity/RxDataSources/issues/91
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clear
        
        if let header: UITableViewHeaderFooterView = view as? UITableViewHeaderFooterView {
            header.textLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16.0)
            header.textLabel?.textColor = UIColor.black
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func sendLog() {
        if !MFMailComposeViewController.canSendMail() {
            print("Mail services are not available")
            
            let title = "Report a bug?"
            let msg = "Mail services are not available, the user’s device is not set up for the delivery of email."
            let alertVC = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            
            let confirmAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            alertVC.addAction(confirmAction)
            
            present(alertVC, animated: true, completion: nil)
            return
        }
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        
        let date = DateFormatter().string(from: Date())
        let email = GoogleService.shared.getEmail()
        
        composeVC.setToRecipients(["it@polaronsolar.com"])
        composeVC.setSubject("[Site Assessment] Report a Bug? - \(date) - \(email ?? "")")
        composeVC.setMessageBody("    ", isHTML: false)
        
        if let data = DataStorageService.shared.getLog() {
            composeVC.addAttachmentData(data, mimeType: "text/plain", fileName: "log")
        }
        
        present(composeVC, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
