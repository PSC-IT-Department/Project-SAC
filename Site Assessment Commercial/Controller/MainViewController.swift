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
import NotificationBannerSwift

struct SiteAssessmentProjectInformationStructure: Codable {
    var projectAddress  : String
    var projectID       : String
    var scheduleDate    : String
    
    init() {
        self.projectAddress = ""
        self.projectID = ""
        self.scheduleDate = ""
    }
}

enum ImageAttributesStatus: String, Codable {
    case pending     = "PENDING"
    case uploading   = "UPLOADING"
    case completed   = "COMPLETED"
    case failed      = "FAILED"
}

struct ImageAttributes: Codable {
    var name: String
    var path: String
    var status: ImageAttributesStatus
    
    private enum CodingKeys: CodingKey {
        case name
        case path
        case status
    }
    
    init() {
        self.name = ""
        self.path = ""
        self.status = .pending
    }
    
    init(name: String, path: String, status: ImageAttributesStatus = .pending) {
        self.name = name
        self.path = path
        self.status = status
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name    = try values.decode(String.self, forKey: .name)
        path    = try values.decode(String.self, forKey: .path)
        status  = try values.decode(ImageAttributesStatus.self, forKey: .status)
    }
}

struct SiteAssessmentImageArrayStructure: Codable {
    var key: String
    var images: [ImageAttributes]
    
    private enum CodingKeys: CodingKey {
        case key
        case images
    }

    init() {
        self.key = ""
        self.images = []
    }
    
    init(key: String, images: [ImageAttributes]) {
        self.key = key
        self.images = images
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key        = try values.decode(String.self, forKey: .key)
        images     = try values.decode([ImageAttributes].self, forKey: .images)
    }
    
}

struct SiteAssessmentDataStructure: Codable, Equatable {
    
    var prjInformation: [String: String]
    var prjQuestionnaire: [QuestionaireConfigs_SectionsWrapper]
    var prjImageArray: [SiteAssessmentImageArrayStructure]

    private enum CodingKeys: String, CodingKey {
        case prjInformation = "detail"
        case prjQuestionnaire = "questionnaire"
        case prjImageArray = "imageArray"
    }
    
    init() {
        self.prjInformation = [:]
        self.prjQuestionnaire = []
        self.prjImageArray = []
    }

    init(withProjectInformation info: [String: String], withProjectQuestionnaire questionnaire: [QuestionaireConfigs_SectionsWrapper], withProjectImageArray array: [SiteAssessmentImageArrayStructure]) {
        self.prjInformation = info
        self.prjQuestionnaire = questionnaire
        self.prjImageArray = array
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        prjInformation      = try values.decode([String: String].self, forKey: .prjInformation)
        prjQuestionnaire    = try values.decode([QuestionaireConfigs_SectionsWrapper].self, forKey: .prjQuestionnaire)
        prjImageArray       = try values.decode([SiteAssessmentImageArrayStructure].self, forKey: .prjImageArray)
    }
    
    init(withZohoData data: [String: String]) {
        
        self.prjInformation = [:]
        
        if let prjAddr = data["sac_projectAddress"], let prjID = data["sac_projectID"], let status = data["sac_status"] {
            self.prjInformation.updateValue(prjAddr, forKey: "Project Address")
            self.prjInformation.updateValue(prjID, forKey: "Project ID")
            self.prjInformation.updateValue(status, forKey: "Status")
        }
        
        self.prjQuestionnaire = []
        self.prjImageArray = []
    }
    
    mutating func configureQuestionnaire(withConfigFileName fileName: String) {
        if let path = Bundle.main.url(forResource: fileName, withExtension: "plist") {
            if let plistData = try? Data(contentsOf: path) {
                let decoder = PropertyListDecoder()
                if let decodedData = try? decoder.decode([QuestionaireConfigs_SectionsWrapper].self, from: plistData) {
                    self.prjQuestionnaire = decodedData
                    return
                }
            }
        }
        
        self.prjQuestionnaire = []
    }
    
    static func == (lhs: SiteAssessmentDataStructure, rhs: SiteAssessmentDataStructure) -> Bool {
        return lhs.prjInformation["Project Address"] == rhs.prjInformation["Project Address"] && lhs.prjInformation["Project ID"] == rhs.prjInformation["Project ID"]
    }
}

class MainViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var labelCurrentUser: UILabel!
    @IBOutlet weak var tableView: UITableView!

    private let refreshControl = UIRefreshControl()

    private let disposeBag = DisposeBag()

    private var prjList: [SiteAssessmentDataStructure] = []

    // private var observableViewModel: BehaviorRelay<[MainViewModel]>!
    private var observableViewModel = BehaviorRelay(value: [MainViewModel]())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
        setupView()
        setupCurrentUser()
        setupViewModel()
        setupCellConfiguration()
        setupCellTapHandling()
        setupCellGestures()
        setupNotificationCenter()
        setupRefreshControl()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)

        setupCurrentUser()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        if self.refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)
    }
}

extension MainViewController {
    

    private func loadData() {
        prjList = DataStorageService.sharedDataStorageService.retrieveProjectList()
    }
    
    func combineProjectList(zohoPrjList: [[String: String]]) {
        
        let prjList = zohoPrjList.filter{prj in prj["sac_status"] == "Pending" && !self.prjList.contains(where: {$0.prjInformation["Project ID"] == prj["sac_projectID"]})}.compactMap {SiteAssessmentDataStructure(withZohoData: $0)}
        
        self.prjList.append(contentsOf: prjList)
        
        self.prjList.forEach{DataStorageService.sharedDataStorageService.storeData(withData: $0, onCompleted: nil)}
        
    }
    
    private func setupView() {
        self.title = "Project List"
        self.view.backgroundColor = UIColor.white
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
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
    }
    
    private func refreshDataManually() {
        
        self.refreshControl.beginRefreshing()
        self.fetchZohoData { (success) in
            if success {
                print("refreshDataManually success.")
            } else {
                print("refreshDataManually failed.")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
        // Fetch Weather Data
        self.fetchZohoData { (success) in
            
        }
    }
    
    private func fetchZohoData(onCompleted: ((Bool) -> ())?) {
        ZohoService.sharedZohoService.getProjectList { (projectListFromZoho) in
            DispatchQueue.main.async {
                guard let zohoPrjList = projectListFromZoho else {
                    print("Offline mode")
                    onCompleted?(false)
                    return
                }
                
                self.combineProjectList(zohoPrjList: zohoPrjList)
                self.setupViewModel()
                self.refreshControl.endRefreshing()
                
                onCompleted?(true)
            }
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
        labelCurrentUser.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.shortcutToGoogleSignIn(_:))))
    }
    
    @objc func shortcutToGoogleSignIn(_ sender: UITapGestureRecognizer) {
        print("Jump to Google signin view controller.")
        let viewController = ThirdPartyAccessViewController.instantiateFromStoryBoard(withTitle: "Google")
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func setupViewModel() {
        let viewModel = prjList.map { (prjData) -> MainViewModel in
            let info = prjData.prjInformation.filter({ (key, value) -> Bool in
                return (key == "Project Address" || key == "Status")
            })
            
            return MainViewModel(status: info["Status"]!, projectAddress: info["Project Address"]!)
        }
        
        observableViewModel.accept(viewModel)
    }
    
    private func setupCellConfiguration() {
        observableViewModel
            .bind(to: tableView.rx.items(cellIdentifier: "MainCell", cellType: MainCell.self)) {
                    row, data, cell in
                cell.configureWithData(data: data)
            }
            .disposed(by: disposeBag)
    }
    
    private func setupCellTapHandling() {
        tableView
            .rx
            .modelSelected(MainViewModel.self)
            .subscribe(onNext: { _ in
                if let selectedRowIndexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: selectedRowIndexPath, animated: true)

                    let viewController = ProjectInformationViewController.instantiateFromStoryBoard(withProjectData: self.prjList[selectedRowIndexPath.row])

                    self.navigationController?.pushViewController(viewController, animated: true)
                }
                
            })
            .disposed(by: disposeBag)
    }
    
    private func setupCellGestures() {
        tableView
            .rx
            .itemDeleted
            .subscribe {
                 print($0)
            }
            .disposed(by: disposeBag)
    }
    
    private func setupNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveComplete(_: )), name: .didReceiveComplete, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveProcessing(_: )), name: .didReceiveProcessing, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveError(_: )), name: .didReceiveError, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveWarning(_: )), name: .didReceiveWarning, object: nil)
    }
    
}

extension MainViewController: NotificationBannerDelegate {
    
    @objc func onDidReceiveComplete(_ msg: Notification) {
        guard let msg = msg.object as? String else {
            print("onDidReceiveComplete - Invalid message.")
            return
        }
        
        let prjID = msg
        var title = msg
        if let index = prjList.firstIndex(where: {$0.prjInformation["Project ID"] == prjID}) {
            title = "File(s) uploaded successfully."

            let status = "Completed"
            prjList[index].prjInformation["Status"] = status
            setupViewModel()
            
            let indexPath = IndexPath(row: index, section: 0)
            let cell = tableView.cellForRow(at: indexPath) as! MainCell
            cell.stopAnimation(withStatus: status)
        } else {
            if msg == "Online Mode", NetworkService.sharedNetworkService.reachabilityStatus == .connected {
                self.refreshDataManually()
            }
        }
        
        showBanner(title: title, style: .success)
    }
    
    @objc func onDidReceiveProcessing(_ msg: Notification) {
        guard let msg = msg.object as? String else {
            print("onDidReceiveProcessing - Invalid message.")
            return
        }
        
        let prjID = msg
        var title = msg
        if let index = prjList.firstIndex(where: {$0.prjInformation["Project ID"] == prjID}) {
            title = "Processing..."

            let indexPath = IndexPath(row: index, section: 0)
            let cell = tableView.cellForRow(at: indexPath) as! MainCell
            
            cell.startAnimation()
        }
        
        showBanner(title: title, style: .info)
    }
    
    @objc func onDidReceiveError(_ msg: Notification) {
        guard let msg = msg.object as? String else {
            print("onDidReceiveError - Invalid message.")
            return
        }
        
        let prjID = msg
        var title = msg
        if let index = prjList.firstIndex(where: {$0.prjInformation["Project ID"] == prjID}) {
            title = "Errors encountered while uploading."

            let status = "Pending"
            prjList[index].prjInformation["Status"] = status
            setupViewModel()
            
            let indexPath = IndexPath(row: index, section: 0)
            let cell = tableView.cellForRow(at: indexPath) as! MainCell
            cell.stopAnimation(withStatus: status)
        }
        
        showBanner(title: title, style: .danger)
    }
    
    @objc func onDidReceiveWarning(_ msg: Notification) {
        guard let msg = msg.object as? String else {
            print("onDidReceiveWarning - Invalid message.")
            return
        }
        
        /*
        let prjID = msg
        var title = msg
        if let index = prjList.firstIndex(where: {$0.prjInformation["Project ID"] == prjID}) {
            print("onDidReceiveWarning - Index = \(index)")
        }
         */
        
        showBanner(title: msg, style: .danger)
    }

    func showBanner(title: String, style: BannerStyle) {
        let banner = StatusBarNotificationBanner(title: title, style: style)
        banner.delegate = self
        banner.show(queuePosition: .front, bannerPosition: .top)
    }

    internal func notificationBannerWillAppear(_ banner: BaseNotificationBanner) {
        print("[NotificationBannerDelegate] Banner will appear")
    }
    
    internal func notificationBannerDidAppear(_ banner: BaseNotificationBanner) {
        print("[NotificationBannerDelegate] Banner did appear")
    }
    
    internal func notificationBannerWillDisappear(_ banner: BaseNotificationBanner) {
        print("[NotificationBannerDelegate] Banner will disappear")
    }
    
    internal func notificationBannerDidDisappear(_ banner: BaseNotificationBanner) {
        print("[NotificationBannerDelegate] Banner did disappear")
    }
}
