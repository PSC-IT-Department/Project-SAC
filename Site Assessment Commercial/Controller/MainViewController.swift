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

typealias MainSection = AnimatableSectionModel<String, MainViewModel>

fileprivate extension Selector {
    static let refreshData = #selector(MainViewController.refreshData)
    static let shortcutToGoogleSignIn = #selector(MainViewController.shortcutToGoogleSignIn)
}

class MainViewController: UIViewController {
    
    @IBOutlet weak var buttonTitle: UIButton!
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
        setupDataSource()
        setupGoogleSignIn()
        setupCurrentUser()
        setupCellTapHandling()
        setupRefreshControl()
        setupNotificationCenter()
        setupDelegate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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
    
    @IBAction func buttonTitleDidClicked(_ sender: Any) {
        let popup = PopupDialog(title: "Type", message: nil, transitionStyle: .bounceDown)
        
        let resButton = DefaultButton(title: SiteAssessmentType.SiteAssessmentResidential.rawValue) {
            print("residential ")
            DataStorageService.sharedDataStorageService.storeDefaultType(option: SiteAssessmentType.SiteAssessmentResidential)
            self.buttonTitle.setTitle(SiteAssessmentType.SiteAssessmentResidential.rawValue, for: .normal)
            
            self.reloadPrjList()
        }
        
        let comButton = DefaultButton(title: SiteAssessmentType.SiteAssessmentCommercial.rawValue) {
            print("commercial ")
            DataStorageService.sharedDataStorageService.storeDefaultType(option: SiteAssessmentType.SiteAssessmentCommercial)
            
            self.buttonTitle.setTitle(SiteAssessmentType.SiteAssessmentCommercial.rawValue, for: .normal)

            self.reloadPrjList()
        }
        
        popup.addButtons([resButton, comButton])
        
        self.present(popup, animated: true, completion: nil)
    }
    
    @IBAction func barButtonFilterDidClicked(_ sender: Any) {
        let popup = PopupDialog(title: "Grouping By", message: nil, transitionStyle: .fadeIn)
        
        let statusButton = DefaultButton(title: GroupingOptions.status.rawValue) {
            DataStorageService.sharedDataStorageService.storeGroupingOption(option: .status)
            
            self.setupViewModel()
        }
        
        let scheduleDateButton = DefaultButton(title: GroupingOptions.scheduleDate.rawValue) {
            DataStorageService.sharedDataStorageService.storeGroupingOption(option: .scheduleDate)
            
            self.setupViewModel()

        }
    
        let cancelAction = CancelButton(title: "Cancel", action: nil)
        
        popup.addButtons([statusButton, scheduleDateButton, cancelAction])
        
        self.present(popup, animated: true, completion: nil)
    }
}

extension MainViewController {
    
    private func loadData() {
        
        if let typeValue = buttonTitle.title(for: .normal), let prjList = DataStorageService.sharedDataStorageService.retrieveProjectList(type: typeValue) {
            self.prjList = prjList
        }
    }
    
    func combineProjectList(zohoPrjList: [[String: String]]) {
        
        let newPrjList = zohoPrjList.filter{prj in prj["sa_status"] == UploadStatus.pending.rawValue && !self.prjList.contains(where: {$0.prjInformation.projectID == prj["sa_projectID"]})}.compactMap { SiteAssessmentDataStructure(withZohoData: $0) }
        
        self.prjList.append(contentsOf: newPrjList)
        
        self.prjList.forEach{DataStorageService.sharedDataStorageService.storeData(withData: $0, onCompleted: nil)}
        
    }
    
    func reloadPrjList() {
        self.prjList = nil
        
        self.loadData()
        self.refreshDataManually()
    }
    
    private func setupView() {
        
        let title = DataStorageService.sharedDataStorageService.retrieveTypeOption()
        self.navigationItem.titleView = buttonTitle
        buttonTitle.setTitle(title.rawValue, for: .normal)
        
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.setBackground(false)
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
        GIDSignIn.sharedInstance().scopes = [kGTLRAuthScopeDrive]
        GIDSignIn.sharedInstance().shouldFetchBasicProfile = true
        GIDSignIn.sharedInstance().signInSilently()
    }

    private func setupRefreshControl() {
        // Add Refresh Control to Table View
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        
        refreshControl.tintColor = UIColor(red:0.25, green:0.72, blue:0.85, alpha:1.0)
        
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing please wait", attributes: attributes)
        
        // Configure Refresh Control
        refreshControl.addTarget(self, action: .refreshData, for: .valueChanged)
    }
    
    private func refreshDataManually() {
        perform(.refreshData, with: nil, afterDelay: 1)
    }
    
    @objc func refreshData(_ sender: Any) {
        self.refreshControl.beginRefreshing()
        self.fetchZohoData { success in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.refreshControl.endRefreshing()
            }
            if success {
                self.setupViewModel()
            } else {
                print("fetchZohoData failed.")
            }
        }
    }
    
    private func fetchZohoData(onCompleted: ((Bool) -> ())?) {
        guard let title = self.buttonTitle.title(for: .normal),
            let type = SiteAssessmentType(rawValue: title)
            else {
                onCompleted?(false)
                return
        }
        
        ZohoService.sharedZohoService.getProjectList(type: type) { (projectListFromZoho) in
            guard let zohoPrjList = projectListFromZoho else {
                print("fetchZohoData failed.")
                onCompleted?(false)
                return
            }
            
            self.combineProjectList(zohoPrjList: zohoPrjList)
            onCompleted?(true)
        }
    }
    
    private func setupCurrentUser() {
        if let userEmail = GoogleService.sharedGoogleService.retrieveGoogleUserEmail() {
            labelCurrentUser.text = "Signed in as \(userEmail)."
        } else {
            let attributedText = NSAttributedString(string: "Please sign in.", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
            labelCurrentUser.attributedText = attributedText
        }
        
        labelCurrentUser.isUserInteractionEnabled = true
        labelCurrentUser.addGestureRecognizer(UITapGestureRecognizer(target: self, action: .shortcutToGoogleSignIn))
    }
    
    @objc func shortcutToGoogleSignIn(_ sender: UITapGestureRecognizer) {
        let viewController = GoogleAccessViewController.instantiateFromStoryBoard(withTitle: "Google")
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func setGrouping(option: GroupingOptions) {
        switch option {
        case .status, .none:
            DataStorageService.sharedDataStorageService.storeGroupingOption(option: .status)
 
        case .assignedTeam:
            DataStorageService.sharedDataStorageService.storeGroupingOption(option: .assignedTeam)

        case .scheduleDate:
            DataStorageService.sharedDataStorageService.storeGroupingOption(option: .scheduleDate)
        }
    }
    
    private func setupViewModel() {

        let option = DataStorageService.sharedDataStorageService.retrieveGroupingOption()
    
        switch option {
        case .status, .none:
            let dictionary = Dictionary(grouping: prjList, by: {$0.prjInformation.status.rawValue})
            
            let sections = dictionary.map { (key, value) -> MainSection in
                let model = key
                let items = value.compactMap({MainViewModel(status: $0.prjInformation.status, projectAddress: $0.prjInformation.projectAddress)})

                return MainSection(model: model, items: items)
            }
            self.sections.accept(sections)
            
        case .assignedTeam:
            let dictionary = Dictionary(grouping: prjList, by: {$0.prjInformation.assignedTeam})
            
            let sections = dictionary.map { (key, value) -> MainSection in
                let model = key ?? ""
                let items = value.compactMap({MainViewModel(status: $0.prjInformation.status, projectAddress: $0.prjInformation.projectAddress)})
                
                
                return MainSection(model: model, items: items)
            }
            
            self.sections.accept(sections)

        case .scheduleDate:
            let dictionary = Dictionary(grouping: prjList, by: { $0.prjInformation.scheduleDate})
            
            let sections = dictionary.map { (key, value) -> MainSection in
                
                let model = key ?? ""
                let items = value.compactMap({MainViewModel(status: $0.prjInformation.status, projectAddress: $0.prjInformation.projectAddress)})

                return MainSection(model: model, items: items)
            }
            
            self.sections.accept(sections)
        }
    }
    
    private func setupCellTapHandling() {
        tableView
            .rx
            .itemSelected
            .subscribe(onNext: { _ in
                if let selectedRowIndexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: selectedRowIndexPath, animated: true)

                    let viewController = ProjectInformationViewController.instantiateFromStoryBoard(withProjectData: self.prjList[selectedRowIndexPath.row])

                    self.navigationController?.pushViewController(viewController, animated: true)
                }
                
            })
            .disposed(by: disposeBag)
    }

}

fileprivate extension Selector {
    static let onDidReceiveCompleteMsg     = #selector(MainViewController.onDidReceiveCompleteMsg)
    static let onDidReceiveProcessingMsg   = #selector(MainViewController.onDidReceiveProcessingMsg)
    static let onDidReceiveErrorMsg        = #selector(MainViewController.onDidReceiveErrorMsg)
    static let onDidReceiveWarningMsg      = #selector(MainViewController.onDidReceiveWarningMsg)
    static let onDidReceiveReachabilityMsg = #selector(MainViewController.onDidReceiveReachabilityMsg)
}

extension MainViewController: NotificationBannerDelegate {
    
    private func setupNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: .onDidReceiveCompleteMsg, name: .didReceiveCompleteMsg, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: .onDidReceiveProcessingMsg, name: .didReceiveProcessingMsg, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: .onDidReceiveErrorMsg, name: .didReceiveErrorMsg, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: .onDidReceiveWarningMsg, name: .didReceiveWarningMsg, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: .onDidReceiveReachabilityMsg, name: .didReceiveReachabilityMsg, object: nil)
    }
    
    @objc func onDidReceiveCompleteMsg(_ msg: Notification) {
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
            
            DataStorageService.sharedDataStorageService.storeData(withData: prjList[index], onCompleted: nil)
            setupViewModel()
        }
    }
    
    @objc func onDidReceiveProcessingMsg(_ msg: Notification) {
        guard let prjID = msg.object as? String else {
            print("onDidReceiveProcessing - Invalid message.")
            return
        }
        
        if let index = prjList.firstIndex(where: {$0.prjInformation.projectID == prjID}) {
            prjList[index].prjInformation.status = .uploading
            setupViewModel()
        }
        
    }
    
    @objc func onDidReceiveErrorMsg(_ msg: Notification) {
        guard let prjID = msg.object as? String else {
            print("onDidReceiveError - Invalid message.")
            return
        }
        
        if let index = prjList.firstIndex(where: {$0.prjInformation.projectID == prjID}) {
            prjList[index].prjInformation.status = .pending
            setupViewModel()
        }
    }
    
    @objc func onDidReceiveWarningMsg(_ msg: Notification) {
    }
    
    @objc func onDidReceiveReachabilityMsg(_ msg: Notification) {
        guard let msg = msg.object as? String else {
            print("onDidReceiveReachabilityMsg - Invalid message.")
            return
        }
        
        var style: BannerStyle = .none
        if msg == "Online Mode", NetworkService.sharedNetworkService.reachabilityStatus == .connected {
            style = .info
            self.refreshDataManually()
        } else if msg == "Offline Mode", NetworkService.sharedNetworkService.reachabilityStatus == .disconnected {
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
            GoogleService.sharedGoogleService.storeGoogleAccountInformation(signIn: signIn)
        }
    }
}

extension MainViewController {
    func tableViewDataSourceUI() -> (
        TableViewSectionedDataSource<MainSection>.ConfigureCell,
        TableViewSectionedDataSource<MainSection>.TitleForHeaderInSection
        ) {
            return (
                { (_, tv, ip, i) in
                    let cell = tv.dequeueReusableCell(withIdentifier: "MainCell", for: ip) as! MainCell
                    cell.configureWithData(data: i)
                    //cell.labelProjectAddress.text = i
                    return cell
            },
                { (ds, section) -> String? in
                    return ds[section].model
            })
    }
}

extension MainViewController: UITableViewDelegate {
    private func setupDelegate() {
        tableView
            .rx
            .setDelegate(self)
            .disposed(by: disposeBag)
    }

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
