//
//  MainViewController.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-23.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import UIKit
import Reachability
import RxSwift
import RxCocoa
import RxDataSources
import RxReachability

import GoogleSignIn
import GoogleAPIClientForREST

import NotificationBannerSwift
import PopupDialog

import UserNotifications

typealias MainSection = AnimatableSectionModel<String, MainViewModel>

fileprivate extension Selector {
    static let refreshData = #selector(MainViewController.refreshData)
    static let shortcutToGoogleSignIn = #selector(MainViewController.shortcutToGoogleSignIn)
}

class MainViewController: UIViewController {
    
    @IBOutlet weak var titleButton: UIButton!
    @IBOutlet weak var labelCurrentUser: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var barButtonFilter: UIBarButtonItem!
    
    private let refreshControl = UIRefreshControl()

    private let disposeBag = DisposeBag()

    private var prjList: [SiteAssessmentDataStructure]!

    private var sections = BehaviorRelay(value: [MainSection]())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
        setupView()

        setupUserNotification()
        setupDataSource()
        setupViewModel()
        setupGoogleSignIn()
        setupCurrentUser()
        setupCellTapHandling()
        setupRefreshControl()
        setupDelegate()
        
        setupButtonTitleTapHandling()
        setupBarButtonFilterTapHandling()
        
        setBadgeIndicator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNotificationCenter()

        setupCurrentUser()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.refreshControl.isRefreshing { self.refreshControl.endRefreshing() }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension MainViewController {
    
    private func loadData() {
        
        let type = DataStorageService.shared.retrieveTypeOption()
        if let prjList = DataStorageService.shared.retrieveProjectList(type: type) {
            self.prjList = prjList
        }
    }
    
    func combineProjectList(zohoPrjList: [[String: String]]) {
        
        let prjIDs = prjList.compactMap({$0.prjInformation.projectID})
        
        let pendingProjects = zohoPrjList.filter { prj in
            let keyStatus    = ZohoKeywords.status.rawValue
            let valueStatus  = UploadStatus.pending.rawValue
            let keyProjectID = ZohoKeywords.projectID.rawValue
            
            return prj[keyStatus] == valueStatus && !prjIDs.contains(where: {$0 == prj[keyProjectID]})
        }
        
        let newPrjList = pendingProjects.compactMap { SiteAssessmentDataStructure(withZohoData: $0) }
        
        self.prjList.append(contentsOf: newPrjList)
        
        DataStorageService.shared.updateLocalProject(prjList: self.prjList)
        newPrjList.forEach {DataStorageService.shared.storeData(withData: $0, onCompleted: nil)}
    }
    
    func reloadPrjList() {
        self.prjList = nil
        
        self.loadData()
        self.refreshDataManually()
    }
    
    private func setupView() {
        
        let title = DataStorageService.shared.retrieveTypeOption()
        self.navigationItem.titleView = titleButton
        titleButton.setTitle(title.rawValue, for: .normal)
        
        // Auto Layout
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 44.0
        
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension
        self.tableView.estimatedSectionHeaderHeight = 44.0
        
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.setBackground(false)
    }
    
    private func setupUserNotification() {
        let application = UIApplication.shared
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.badge, .alert, .sound]) { _, _ in }
        } else {
            let defaultSetting = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(defaultSetting)
        }
        application.registerForRemoteNotifications()
        
        application.applicationIconBadgeNumber = 1
    }
    
    private func setBadgeIndicator() {
        let application = UIApplication.shared
        
        let allPrjList = DataStorageService.shared.projectList
        
        if let count = allPrjList?.filter({ (saData) -> Bool in
            if let status = saData.prjInformation.status, status == .pending {
                return true
            } else {
                return false
            }
        }).count {
            application.applicationIconBadgeNumber = count
        }
    }
    
    private func setupDataSource() {
        let (configureCell, titleForSection) = tableViewDataSourceUI()
        
        let dataSource = RxTableViewSectionedReloadDataSource<MainSection>(
            configureCell: configureCell,
            titleForHeaderInSection: titleForSection
        )
        
        self.sections.asObservable()
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    private func setupGoogleSignIn() {
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().scopes = [kGTLRAuthScopeDrive, kGTLRAuthScopeCalendar]
        GIDSignIn.sharedInstance().shouldFetchBasicProfile = true
        GIDSignIn.sharedInstance().signInSilently()
    }

    private func setupButtonTitleTapHandling() {
        titleButton
            .rx
            .tap
            .subscribe(onNext: { [unowned self] (_) in
                let popup = PopupDialog(title: "Type", message: nil, transitionStyle: .bounceDown)
                
                let resButton = DefaultButton(title: SiteAssessmentType.SiteAssessmentResidential.rawValue) {
                    DataStorageService.shared.storeDefaultType(option: SiteAssessmentType.SiteAssessmentResidential)
                    self.titleButton.setTitle(SiteAssessmentType.SiteAssessmentResidential.rawValue, for: .normal)
                    
                    self.reloadPrjList()
                }
                
                let comButton = DefaultButton(title: SiteAssessmentType.SiteAssessmentCommercial.rawValue) {
                    DataStorageService.shared.storeDefaultType(option: SiteAssessmentType.SiteAssessmentCommercial)
                    
                    self.titleButton.setTitle(SiteAssessmentType.SiteAssessmentCommercial.rawValue, for: .normal)
                    
                    self.reloadPrjList()
                }
                
                popup.addButtons([resButton, comButton])
                
                self.present(popup, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupBarButtonFilterTapHandling() {
        barButtonFilter
            .rx
            .tap
            .subscribe(onNext: { [unowned self] (_) in
                let popup = PopupDialog(title: "Grouping By", message: nil, transitionStyle: .fadeIn)
                
                let statusButton = DefaultButton(title: GroupingOptions.status.rawValue) {
                    DataStorageService.shared.storeGroupingOption(option: .status)
                    
                    self.setupViewModel()
                }
                
                let scheduleDateButton = DefaultButton(title: GroupingOptions.scheduleDate.rawValue) {
                    DataStorageService.shared.storeGroupingOption(option: .scheduleDate)
                    
                    self.setupViewModel()
                }
                
                let cancelAction = CancelButton(title: "Cancel", action: nil)
                
                popup.addButtons([statusButton, scheduleDateButton, cancelAction])
                
                self.present(popup, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupRefreshControl() {
        // Add Refresh Control to Table View
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        
        refreshControl.tintColor = UIColor(red: 0.25, green: 0.72, blue: 0.85, alpha: 1.0)
        
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing please wait", attributes: attributes)
        
        // Configure Refresh Control
        refreshControl.addTarget(self, action: .refreshData, for: .valueChanged)
    }
    
    private func refreshDataManually(withDelay delay: Double = 1.0) {
        perform(.refreshData, with: nil, afterDelay: delay)
    }
    
    @objc func refreshData(_ sender: Any) {
        self.refreshControl.beginRefreshing()
        self.fetchZohoData { [weak self] success in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.refreshControl.endRefreshing()
            }
            if success {
                self?.setupViewModel()
            } else {
                print("Refresh data failed.")
            }
        }
    }
    
    private func fetchZohoData(onCompleted: ((Bool) -> Void)?) {
        guard let title = self.titleButton.title(for: .normal),
            let type = SiteAssessmentType(rawValue: title)
            else {
                onCompleted?(false)
                return
        }
        
        ZohoService.shared.getProjectList(type: type) { [weak self] (projectListFromZoho) in
            guard let zohoPrjList = projectListFromZoho else {
                print("Fetch Zoho data failed.")
                onCompleted?(false)
                return
            }
            
            self?.combineProjectList(zohoPrjList: zohoPrjList)
            onCompleted?(true)
        }
    }
    
    private func setupCurrentUser() {
        if let userEmail = GoogleService.shared.getEmail() {
            labelCurrentUser.text = "Signed in as \(userEmail)."
        } else {
            let text = "Please sign in."
            let underlineStyle = NSUnderlineStyle.single.rawValue
            let attributedText = NSAttributedString(string: text, attributes: [.underlineStyle: underlineStyle])
            labelCurrentUser.attributedText = attributedText
        }
        
        labelCurrentUser.isUserInteractionEnabled = true
        labelCurrentUser.addGestureRecognizer(UITapGestureRecognizer(target: self, action: .shortcutToGoogleSignIn))
    }
    
    @objc func shortcutToGoogleSignIn(_ sender: UITapGestureRecognizer) {
        if let viewController = GoogleAccessViewController.instantiateFromStoryBoard() {
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    private func setGrouping(option: GroupingOptions) {
        switch option {
        case .status, .none:
            DataStorageService.shared.storeGroupingOption(option: .status)
 
        case .assignedTeam:
            DataStorageService.shared.storeGroupingOption(option: .assignedTeam)

        case .scheduleDate:
            DataStorageService.shared.storeGroupingOption(option: .scheduleDate)
        }
    }
    
    private func setupViewModel() {

        let option = DataStorageService.shared.retrieveGroupingOption()
    
        var dictionary : [(key: String, value: [SiteAssessmentDataStructure])]!
                
        switch option {
        case .status, .none:
            let dict = Dictionary(grouping: prjList, by: {$0.prjInformation.status.rawValue}).sorted {$0.key < $1.key}
            
            dictionary = dict
        
        case .assignedTeam:
            let dict = Dictionary(grouping: prjList, by: {$0.prjInformation.assignedTeam}).sorted {$0.key < $1.key}
            
            dictionary = dict

        case .scheduleDate:
            let dict = Dictionary(grouping: prjList, by: {$0.prjInformation.scheduleDate}).sorted { (p1, p2) -> Bool in
                
                if let k1 = p1.key, let k2 = p2.key {
                    return k1 < k2
                } else {
                    return true
                }
            }
            
            let newDict = dict.compactMap { (key, value) -> (String, [SiteAssessmentDataStructure]) in
                if let k = key {
                    return (k, value)
                } else {
                    return ("", value)
                }
            }
            
            dictionary = newDict
        }
        
        let sections = dictionary.map { (key, value) -> MainSection in
            let model = key
            let items = value.compactMap({ prjData -> MainViewModel? in
                if let key = prjData.prjInformation.status, let value = prjData.prjInformation.projectAddress {
                    let viewModel = MainViewModel(status: key, projectAddress: value)
                    return viewModel
                } else {
                    return nil
                }
            })
            
            return MainSection(model: model, items: items)
        }
        self.sections.accept(sections)
    }
    
    private func setupCellTapHandling() {
        tableView
            .rx
            .itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
                guard let cell = self?.tableView.cellForRow(at: indexPath) as? MainCell else { return }

                if let text = cell.labelProjectAddress.text,
                    let prjData = self?.prjList.first(where: {$0.prjInformation.projectAddress == text}) {
                    DataStorageService.shared.setCurrentProject(projectID: prjData.prjInformation.projectID)
                    
                    if let viewController = ProjectInformationViewController.instantiateFromStoryBoard() {
                        self?.navigationController?.pushViewController(viewController, animated: true)
                    }
                }
            })
            .disposed(by: disposeBag)
    }
}

fileprivate extension Selector {
    static let onDidGetCompleteMsg     = #selector(MainViewController.onDidGetCompleteMsg)
    static let onDidGetProcessingMsg   = #selector(MainViewController.onDidGetProcessingMsg)
    static let onDidGetErrorMsg        = #selector(MainViewController.onDidGetErrorMsg)
    static let onDidGetWarningMsg      = #selector(MainViewController.onDidGetWarningMsg)
    static let onDidGetReachabilityMsg = #selector(MainViewController.onDidGetReachabilityMsg)
}

extension MainViewController: NotificationBannerDelegate {
    
    private func setupNotificationCenter() {
        let noticationCenter = NotificationCenter.default
        noticationCenter.addObserver(self, selector: .onDidGetCompleteMsg, name: .CompleteMsg, object: nil)
        
        noticationCenter.addObserver(self, selector: .onDidGetProcessingMsg, name: .ProcessingMsg, object: nil)
        
        noticationCenter.addObserver(self, selector: .onDidGetErrorMsg, name: .ErrorMsg, object: nil)
        
        noticationCenter.addObserver(self, selector: .onDidGetWarningMsg, name: .WarningMsg, object: nil)
        
        noticationCenter.addObserver(self, selector: .onDidGetReachabilityMsg, name: .ReachabilityMsg, object: nil)
    }
    
    @objc func onDidGetCompleteMsg(_ msg: Notification) {
        guard let prjID = msg.object as? String else {
            print("onDidReceiveComplete - Invalid message.")
            return
        }
        
        if let index = prjList.firstIndex(where: {$0.prjInformation.projectID == prjID}) {

            prjList[index].prjInformation.status = .completed
            
            let formatter = DateFormatter()
            formatter.dateFormat = "dd-MMM-yyyy"
            let dateString = formatter.string(from: Date())
            prjList[index].prjInformation.uploadedDate = dateString
            
            DataStorageService.shared.storeData(withData: prjList[index], onCompleted: nil)
            DataStorageService.shared.updateProject(prjData: prjList[index])
            setupViewModel()
        }
    }
    
    @objc func onDidGetProcessingMsg(_ msg: Notification) {
        guard let prjID = msg.object as? String else {
            print("onDidReceiveProcessing - Invalid message.")
            return
        }
        
        if let index = prjList.firstIndex(where: {$0.prjInformation.projectID == prjID}) {
            prjList[index].prjInformation.status = .uploading
            setupViewModel()
        }
        
    }
    
    @objc func onDidGetErrorMsg(_ msg: Notification) {
        guard let prjID = msg.object as? String else {
            print("onDidReceiveError - Invalid message.")
            return
        }
        
        if let index = prjList.firstIndex(where: {$0.prjInformation.projectID == prjID}) {
            prjList[index].prjInformation.status = .pending
            setupViewModel()
        }
    }
    
    @objc func onDidGetWarningMsg(_ msg: Notification) {
    }
    
    @objc func onDidGetReachabilityMsg(_ msg: Notification) {
        guard let msg = msg.object as? String else {
            print("onDidReceiveReachabilityMsg - Invalid message.")
            return
        }
        
        var style: BannerStyle = .none
        if msg == "Online Mode", NetworkService.shared.reachabilityStatus == .connected {
            style = .info
            self.refreshDataManually(withDelay: 0.0)
        } else if msg == "Offline Mode", NetworkService.shared.reachabilityStatus == .disconnected {
            style = .warning
        }
        
        showBanner(title: msg, style: style)

    }

    private func showBanner(title: String, style: BannerStyle) {
        let banner = StatusBarNotificationBanner(title: title, style: style)
        banner.delegate = self
        banner.show(queuePosition: .front, bannerPosition: .top)
    }

    internal func notificationBannerWillAppear(_ banner: BaseNotificationBanner) {
    }
    
    internal func notificationBannerDidAppear(_ banner: BaseNotificationBanner) {
    }
    
    internal func notificationBannerWillDisappear(_ banner: BaseNotificationBanner) {
    }
    
    internal func notificationBannerDidDisappear(_ banner: BaseNotificationBanner) {
    }
}

extension MainViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let err = error {
            showBanner(title: "Google SignIn Failed. Error: \(err.localizedDescription)", style: .danger)
            return
        } else {
            guard let email = user.profile.email else { return }
            DataStorageService.shared.writeToLog("User Email is \(email)")
            GoogleService.shared.storeGoogleAccountInformation(signIn: signIn)
        }
    }
}

extension MainViewController {
    func tableViewDataSourceUI() -> (
        TableViewSectionedDataSource<MainSection>.ConfigureCell,
        TableViewSectionedDataSource<MainSection>.TitleForHeaderInSection
        ) {
            return ({ (_, tv, ip, i) in
                let cell = tv.dequeueReusableCell(withClass: MainCell.self, for: ip)
                cell.configureWithData(data: i)
                return cell
                
            }, { (ds, section) -> String? in
                return ds[section].model
            }
        )
    }
}

extension MainViewController: UITableViewDelegate {
    
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
