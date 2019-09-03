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
    
    static let id = "ReviewViewController"
    private let cellID = "ReviewCell"
    
    private var prjData: SiteAssessmentDataStructure!
    
    var observableViewModel: Observable<[ReviewViewModel]>!

    private let disposeBag = DisposeBag()
    
    static func instantiateFromStoryBoard(withProjectData data: SiteAssessmentDataStructure) -> ReviewViewController? {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier:
            id) as? ReviewViewController
        
        viewController?.prjData = data

        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupTableView()
        setupViewModel()
        setupCell()
        setupButton()
    }

    @IBAction func buttonSaveDidClicked(_ sender: Any) {
        
        guard let prjID = prjData.prjInformation.projectID,
            let prjData = prjData
            else {
                print("buttonSaveDidClicked prjId or prjData is empty")
                return
        }

        guard NetworkService.shared.reachabilityStatus == .connected else {
            let msgObject = "Offline Mode. File(s) saved sucessfully, will be uploaded later."
            LoadingIndicatorView.hide()
            NotificationCenter.default.post(name: .WarningMsg, object: msgObject)
            navigationController?.popToRootViewController(animated: true)
            return
        }
        
        LoadingIndicatorView.show("Processing...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {[weak self,
                                                                weak zohoService = ZohoService.shared,
            weak googleService = GoogleService.shared] in
            zohoService?.setRemoteToUploading(projectID: prjID) { success in
                print("success = \(success)")
                if success {
                    print("ZohoService.sharedZohoService.setRemoteToUploading successfully.")
                    NotificationCenter.default.post(name: .ProcessingMsg, object: prjID)
                    googleService?.uploadProject(with: prjData) { (success, error) in
                        if let err = error {
                            print("GoogleService.sharedGoogleService.uploadProject failed. Error=\(err)")
                            NotificationCenter.default.post(name: .ErrorMsg, object: err)
                        }
                        
                        if success {
                            print("GoogleService.sharedGoogleService.uploadProject successfully.")
                            zohoService?.uploadProject(withData: prjData) { (success) in
                                if success {
                                    print("ZohoService.sharedZohoService.uploadProject successfully.")
                                    NotificationCenter.default.post(name: .CompleteMsg, object: prjID)
                                } else {
                                    print("ZohoService.sharedZohoService.uploadProject failed.")
                                    NotificationCenter.default.post(name: .ErrorMsg, object: nil)
                                }
                            }
                        }
                    }
                } else {
                    print("ZohoService.sharedZohoService.setRemoteToUploading failed.")
                    NotificationCenter.default.post(name: .ErrorMsg, object: nil)
                }
            }
            LoadingIndicatorView.hide()
            self?.navigationController?.popToRootViewController(animated: true)
        }
    }

    deinit {
        print("ReviewViewController deinit")
    }
}

extension ReviewViewController {
    
    private func setupView() {
        title = "Review"
        setBackground()

        // https://stackoverflow.com/questions/28733936/change-color-of-back-button-in-navigation-bar @Tiep Vu Van
        navigationController?.navigationBar.tintColor = UIColor(named: "PSC_Blue")
    }

    private func setupTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44.0
    }

    private func setupViewModel() {
        var viewModel = [
            ReviewViewModel(key: "Project Address", value: prjData.prjInformation.projectAddress),
            ReviewViewModel(key: "Status", value: prjData.prjInformation.status.rawValue),
            ReviewViewModel(key: "Type", value: prjData.prjInformation.type.rawValue),
            ReviewViewModel(key: "Schedule Date", value: prjData.prjInformation.scheduleDate),
            ReviewViewModel(key: "Assigned Date", value: prjData.prjInformation.assignedDate),
            ReviewViewModel(key: "Uploaded Date", value: prjData.prjInformation.uploadedDate)
        ]

        let allQuestions = prjData.prjQuestionnaire.compactMap({$0.Questions}).joined()
        
        let questionsViewModel = allQuestions.compactMap({ReviewViewModel(key: $0.Name, value: $0.Value)})
        
        viewModel.append(contentsOf: questionsViewModel)
        
        observableViewModel = Observable.of(viewModel)
    }

    private func setupCell() {
        observableViewModel
            .asObservable()
            .bind(to: tableView.rx.items(cellIdentifier: cellID, cellType: ReviewCell.self)) { (_, element, cell) in
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
