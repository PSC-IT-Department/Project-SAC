//
//  SettingsViewController.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-23.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import UIKit
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
        setupCell()
        setupCellTapHandling()
        setupDelegate()
    }
}

extension SettingsViewController {

    /*
    private func showSkeleton() {
        self.view.showAnimatedGradientSkeleton()
    }
    
    private func hideSkeleton() {
        self.view.hideSkeleton()
    }
     */
    
    private func setupView() {
        self.title = "Settings"
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = UIColor(white: 0.667, alpha: 0.2)
        
        // https://stackoverflow.com/questions/28733936/change-color-of-back-button-in-navigation-bar @Tiep Vu Van
        self.navigationController?.navigationBar.tintColor = UIColor(named: "PSC_Blue")
        self.setBackground()

    }
    
    private func setupViewModel() {
        let settingsSections: [SettingsSection] = [
            SettingsSection(model: "Preferences", items: ["Grouping by", "Map Type"]),
            SettingsSection(model: "Integration", items: ["Google", "Zoho CRM"])
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
    
    private func setupCell() {
        
    }
    
    private func setupCellTapHandling() {
        tableView
            .rx
            .itemSelected
            .subscribe(onNext:  { value in
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: indexPath, animated: true)
                    
                    switch (indexPath.section, indexPath.row) {
                    // Grouping By
                    case (0, 0):
                        let popupDialog = PopupDialog(title: "Grouping By", message: nil, transitionStyle: .zoomIn)
                        
                        let statusButton = DefaultButton(title: GroupingOptions.status.rawValue) {
                            DataStorageService.sharedDataStorageService.storeGroupingOption(option: .status)
                            self.setupViewModel()
                        }
                        
                        let scheduleDateButton = DefaultButton(title: GroupingOptions.scheduleDate.rawValue) {
                            DataStorageService.sharedDataStorageService.storeGroupingOption(option: .scheduleDate)
                            self.setupViewModel()
                        }
                        
                        let cancelAction = CancelButton(title: "Cancel", action: nil)
                        popupDialog.addButtons([statusButton, scheduleDateButton, cancelAction])
 
                        self.present(popupDialog, animated: true, completion: nil)
                        
                    // Map Type
                    case (0, 1):
                        let popupDialog = PopupDialog(title: "Map Type", message: nil, transitionStyle: .zoomIn)
                        
                        let standardButton = DefaultButton(title: "Standard") {
                            DataStorageService.sharedDataStorageService.storeMapTypeOption(option: .standard)
                            self.setupViewModel()
                        }
                        
                        let satelliteButton = DefaultButton(title: "Satellite") {
                            DataStorageService.sharedDataStorageService.storeMapTypeOption(option: .satellite)
                            self.setupViewModel()
                        }
                        
                        let hybridButton = DefaultButton(title: "Hybrid") {
                            DataStorageService.sharedDataStorageService.storeMapTypeOption(option: .hybrid)
                            self.setupViewModel()
                        }
                        
                        let cancelAction = CancelButton(title: "Cancel", action: nil)
                        popupDialog.addButtons([standardButton, satelliteButton, hybridButton, cancelAction])
 
                        self.present(popupDialog, animated: true, completion: nil)

                    // Google
                    case (1, 0):
                        let vc = GoogleAccessViewController.instantiateFromStoryBoard(withTitle: "Google")
                        self.navigationController?.pushViewController(vc, animated: true)
                    
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
