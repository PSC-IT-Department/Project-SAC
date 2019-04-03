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

class SettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    typealias SettingsSection = AnimatableSectionModel<String, String>
    private var sections = BehaviorRelay(value: [SettingsSection]())
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupViewModel()
        setupDataSource()
        setupCellTapHandling()
        setupDelegate()
    }
}

extension SettingsViewController {

    private func setupView() {
        self.title = "Settings"
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = UIColor(white: 0.667, alpha: 0.2)
        
        // Auto Layout
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 42.0
        
        // https://stackoverflow.com/questions/28733936/change-color-of-back-button-in-navigation-bar @Tiep Vu Van
        self.navigationController?.navigationBar.tintColor = UIColor(named: "PSC_Blue")
        self.setBackground()

    }
    
    private func setupViewModel() {
        let settingsSections: [SettingsSection] = [
            SettingsSection(model: "Preferences", items: ["Grouping by", "Map Type"]),
            SettingsSection(model: "Integration", items: ["Google", "Zoho CRM"]),
            SettingsSection(model: "", items: ["Report a bug?", "About this App"])
        ]

        self.sections.accept(settingsSections)
    }
    
    private func setupDataSource() {
        let (configureCell, titleForSection) = self.tableViewDataSourceUI()
    
        let dataSource = RxTableViewSectionedReloadDataSource<SettingsSection>(
            configureCell: configureCell,
            titleForHeaderInSection: titleForSection
        )
    
        self.sections.asObservable()
        .bind(to: tableView.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
    }
    
    private func setupCellTapHandling() {
        tableView
            .rx
            .itemSelected
            .subscribe(onNext:  { [weak self] value in
                if let indexPath = self?.tableView.indexPathForSelectedRow {
                    self?.tableView.deselectRow(at: indexPath, animated: true)
                    
                    switch (indexPath.section, indexPath.row) {
                    // Grouping By
                    case (0, 0):
                        let popupDialog = PopupDialog(title: "Grouping By", message: nil, transitionStyle: .zoomIn)
                        
                        let statusButton = DefaultButton(title: GroupingOptions.status.rawValue) {
                            DataStorageService.sharedDataStorageService.storeGroupingOption(option: .status)
                            self?.setupViewModel()
                        }
                        
                        let scheduleDateButton = DefaultButton(title: GroupingOptions.scheduleDate.rawValue) {
                            DataStorageService.sharedDataStorageService.storeGroupingOption(option: .scheduleDate)
                            self?.setupViewModel()
                        }
                        
                        let cancelAction = CancelButton(title: "Cancel", action: nil)
                        popupDialog.addButtons([statusButton, scheduleDateButton, cancelAction])
 
                        self?.present(popupDialog, animated: true, completion: nil)
                        
                    // Map Type
                    case (0, 1):
                        let popupDialog = PopupDialog(title: "Map Type", message: nil, transitionStyle: .zoomIn)
                        
                        let standardButton = DefaultButton(title: "Standard") {
                            DataStorageService.sharedDataStorageService.storeMapTypeOption(option: .standard)
                            self?.setupViewModel()
                        }
                        
                        let satelliteButton = DefaultButton(title: "Satellite") {
                            DataStorageService.sharedDataStorageService.storeMapTypeOption(option: .satellite)
                            self?.setupViewModel()
                        }
                        
                        let hybridButton = DefaultButton(title: "Hybrid") {
                            DataStorageService.sharedDataStorageService.storeMapTypeOption(option: .hybrid)
                            self?.setupViewModel()
                        }
                        
                        let cancelAction = CancelButton(title: "Cancel", action: nil)
                        popupDialog.addButtons([standardButton, satelliteButton, hybridButton, cancelAction])
 
                        self?.present(popupDialog, animated: true, completion: nil)

                    // Google
                    case (1, 0):
                        let vc = GoogleAccessViewController.instantiateFromStoryBoard()
                        self?.navigationController?.pushViewController(vc, animated: true)
                    
                    // Report a bug?
                    case (2, 0):
                        print("Report a bug")
                        self?.sendLog()
                        
                    // About this App
                    case (2, 1):
                        let vc = AboutViewController.instantiateFromStoryBoard()
                        self?.navigationController?.pushViewController(vc, animated: true)
                        
                    default:
                        return
                    }
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
            return ({ (_, tv, ip, i) in
                let cell = tv.dequeueReusableCell(withIdentifier: "SettingsCell") as! SettingsCell
                cell.labelKey.text = i
                cell.labelValue.text = nil
                cell.imageIcon.image = nil
                
                switch (ip.section, ip.row) {
                    
                // Grouping by
                case (0, 0):
                    cell.accessoryType = .none
                    
                    let option = DataStorageService.sharedDataStorageService.retrieveGroupingOption()
                    cell.labelValue.text = option.rawValue
                    
                // Map Type
                case (0, 1):
                    cell.accessoryType = .none
                    
                    let option = DataStorageService.sharedDataStorageService.retrieveMapTypeOption()
                    cell.labelValue.text = option.type.description
                    
                // Google
                case (1, 0):
                    if let userEmail = GoogleService.sharedGoogleService.retrieveGoogleUserEmail() {
                        cell.accessoryType = .checkmark
                        
                        let text = i + " - \(userEmail)"
                        cell.labelKey.text = text
                    }
                    cell.imageIcon.image = UIImage(named: "icons8-google-48")
                    
                // Report a Bug?
                case (2, 0):
                    cell.accessoryType = .detailButton
                    
                // About this App
                case (2, 1):
                    cell.accessoryType = .disclosureIndicator

                default:
                    cell.accessoryType = .none
                }
                return cell
            }, { (ds, section) -> String? in
                return ds[section].model
            }
            )
    }
}

// Mark: UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    
    // https://github.com/RxSwiftCommunity/RxDataSources/issues/91
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clear
        
        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16.0)
        header.textLabel?.textColor = UIColor.black
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func sendLog() {
        if !MFMailComposeViewController.canSendMail() {
            print("Mail services are not available")
            return
        }
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        
        composeVC.setToRecipients(["it@polaronsolar.com"])
        composeVC.setSubject("[Log]")
        composeVC.setMessageBody("Hello from California!", isHTML: false)
        
        if let data = DataStorageService.sharedDataStorageService.getLog() {
            composeVC.addAttachmentData(data, mimeType: "text/plain", fileName: "log")
        }
        
        self.present(composeVC, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
