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
        
        LoadingIndicatorView.show("Processing...")
        
        DataStorageService.sharedDataStorageService.storeData(withData: prjData) { [weak self] (success, error) in
            var msg: Notification.Name = .didReceiveErrorMsg
            var msgObject: Any = prjID

            if success {
                print("DataStorageService.sharedDataStorageService.storeData successfully")
                
                if NetworkService.sharedNetworkService.reachabilityStatus == .connected {
                    
                    LoadingIndicatorView.hide()
                    
                    self?.navigationController?.popToRootViewController(animated: true)

                    DispatchQueue.main.async {
                        ZohoService.sharedZohoService.setRemoteToUploading(projectID: prjID) { (success) in
                            if success, let prjData = self?.prjData {
                                print("ZohoService.sharedZohoService.setRemoteToUploading successfully.")
                                NotificationCenter.default.post(name: .didReceiveProcessingMsg, object: msgObject)
                                
                                GoogleService.sharedGoogleService.uploadProject(withData: prjData) { (success, error) in
                                    if let err = error {
                                        print("GoogleService.sharedGoogleService.uploadProject failed. Error=\(err)")
                                    }
                                    
                                    if success {
                                        print("GoogleService.sharedGoogleService.uploadProject successfully.")
                                        ZohoService.sharedZohoService.uploadProject(withData: prjData, onCompleted: { (success) in
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
                    }
                } else {
                    msg = .didReceiveWarningMsg
                    msgObject = "Offline Mode. File(s) saved sucessfully, will be uploaded later."
                    LoadingIndicatorView.hide()
                    NotificationCenter.default.post(name: msg, object: msgObject)
                    self?.navigationController?.popToRootViewController(animated: true)
                }
                
                /*DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    LoadingIndicatorView.hide()
                    
                    self.navigationController?.popToRootViewController(animated: true)
                    return
                } */
            } else {
                print("Store data failed. Error=\(error!)")
                DispatchQueue.main.async() {
                    LoadingIndicatorView.hide()
                    self?.navigationController?.popToRootViewController(animated: true)
                    NotificationCenter.default.post(name: msg, object: msgObject)
                    return
                }
            }
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
        var viewModel = prjData.prjInformation.toDictionary().map { (key, value) -> ReviewViewModel in
            return ReviewViewModel(key: key, value: value)
        }

        prjData.prjQuestionnaire.forEach { (section) in
            let questions = section.Questions.map { (question) -> ReviewViewModel in
                return ReviewViewModel(key: question.Name, value: question.Value)
            }
            
            viewModel.append(contentsOf: questions)
        }
        
        prjData.prjImageArray.forEach { (imageArray) in
            let images = imageArray.images.map { (imageAttr) -> ReviewViewModel in
                return ReviewViewModel(key: imageAttr.name, value: imageAttr.status.rawValue)
            }
            
            viewModel.append(contentsOf: images)
        }
        
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
