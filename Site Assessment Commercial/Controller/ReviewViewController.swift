//
//  ReviewViewController.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-23.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

import NotificationBannerSwift

class ReviewViewController: UIViewController, UITableViewDelegate {
 
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    
    private var prjData: SiteAssessmentDataStructure!
    
    var observableViewModel: Observable<[ReviewViewModel]>!

    private let disposeBag = DisposeBag()
    
    static func instantiateFromStoryBoard(withProjectData data: SiteAssessmentDataStructure) -> ReviewViewController {
        let viewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier:
            "ReviewViewController") as! ReviewViewController
        
        viewController.prjData = data
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupViewModel()
        setupCell()
        setupButton()
    }
    
    @IBAction func buttonSaveDidClicked(_ sender: Any) {
        
        guard let prjID = prjData.prjInformation.projectID else {
            return
        }
        
        var msg: Notification.Name = .didReceiveErrorMsg
        var msgObject: Any = prjID

        LoadingIndicatorView.show("Processing...")
        
        if NetworkService.sharedNetworkService.reachabilityStatus == .connected {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {[weak self] in
                ZohoService.sharedZohoService.setRemoteToUploading(projectID: prjID) {success in
                    guard let strongSelf = self else { return }
                    print("success = \(success)")
                    if success {
                        print("ZohoService.sharedZohoService.setRemoteToUploading successfully.")
                        
                        NotificationCenter.default.post(name: .didReceiveProcessingMsg, object: msgObject)
                        
                        GoogleService.sharedGoogleService.uploadProject(withData: strongSelf.prjData) { (success, error) in
                            if let err = error {
                                print("GoogleService.sharedGoogleService.uploadProject failed. Error=\(err)")
                            }
                            
                            if success {
                                print("GoogleService.sharedGoogleService.uploadProject successfully.")
                                ZohoService.sharedZohoService.uploadProject(withData: strongSelf.prjData, onCompleted: { (success) in
                                    if success {
                                        print("ZohoService.sharedZohoService.uploadProject successfully.")
                                        NotificationCenter.default.post(name: .didReceiveCompleteMsg, object: msgObject)
                                    } else {
                                        print("ZohoService.sharedZohoService.uploadProject failed.")
                                    }
                                })
                            }
                        }
                    } else {
                        print("ZohoService.sharedZohoService.setRemoteToUploading failed.")
                    }
                }
                LoadingIndicatorView.hide()
                self?.navigationController?.popToRootViewController(animated: true)
            }
            
        } else {
            msg = .didReceiveWarningMsg
            msgObject = "Offline Mode. File(s) saved sucessfully, will be uploaded later."
            LoadingIndicatorView.hide()
            NotificationCenter.default.post(name: msg, object: msgObject)
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}

extension ReviewViewController {
    
    private func setupView() {
        self.title = "Review"
        self.setBackground()
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 42.0

        // https://stackoverflow.com/questions/28733936/change-color-of-back-button-in-navigation-bar @Tiep Vu Van
        self.navigationController?.navigationBar.tintColor = UIColor(named: "PSC_Blue")
    }

    private func setupViewModel() {
        var viewModel = [
            ReviewViewModel(key: "Project Address", value: prjData.prjInformation.projectAddress),
            ReviewViewModel(key: "Status",          value: prjData.prjInformation.status.rawValue),
            ReviewViewModel(key: "Type",            value: prjData.prjInformation.type.rawValue),
            ReviewViewModel(key: "Schedule Date",   value: prjData.prjInformation.scheduleDate),
            ReviewViewModel(key: "Assigned Date",   value: prjData.prjInformation.assignedDate),
            ReviewViewModel(key: "Uploaded Date",   value: prjData.prjInformation.uploadedDate)
        ]
        
        let questions = prjData.prjQuestionnaire.compactMap({$0.Questions}).joined().compactMap({ReviewViewModel(key: $0.Name, value: $0.Value)})
                
        viewModel.append(contentsOf: questions)
        
        observableViewModel = Observable.of(viewModel)
    }

    private func setupCell() {
        observableViewModel
            .asObservable()
            .bind(to: tableView.rx.items(cellIdentifier: "ReviewCell", cellType: ReviewCell.self)) { (row, element, cell) in
                cell.labelKey.text = element.key
                cell.labelValue.text = element.value
            }
            .disposed(by: disposeBag)
    }
    
    private func setupButton() {
        let status = prjData.prjInformation.status
        
        if status == .completed {
            saveButton.isUserInteractionEnabled = false
            saveButton.setTitle(UploadStatus.completed.rawValue, for: .normal)
            saveButton.backgroundColor = UIColor.gray
        }
    }
}
