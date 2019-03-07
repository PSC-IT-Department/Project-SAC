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

class ReviewViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var answerDictionary: [String: String] = [:]
    
    private var prjData = SiteAssessmentDataStructure()
    
    var observableViewModel: Observable<[ReviewViewModel]>!

    private let disposeBag = DisposeBag()
    
    var strLabel = UILabel()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    static func instantiateFromStoryBoard(withProjectData data: SiteAssessmentDataStructure) -> ReviewViewController {
        let viewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier:
            "ReviewViewController") as! ReviewViewController
        
        viewController.prjData = data
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
        setupView()
        setupViewModel()
        setupCell()
    }
    
    @IBAction func buttonSaveDidClicked(_ sender: Any) {
        LoadingIndicatorView.show("Processing...")
        DataStorageService.sharedDataStorageService.storeData(withData: self.prjData) { (success, error) in
            if let err = error {
                print("Store data failed. Error=\(err)")
                return
            }
            
            if success {
                
                if NetworkService.sharedNetworkService.reachabilityStatus == .connected {
                    guard let prjID = self.prjData.prjInformation["Project ID"] else {
                        return
                    }
                    
                    ZohoService.sharedZohoService.setRemoteToUploading(projectID: prjID) { (success) in
                        if success {
                            print("ZohoService.sharedZohoService.setRemoteToUploading successfully.")
                            NotificationCenter.default.post(name: .didReceiveProcessing, object: prjID)
                        } else {
                            print("ZohoService.sharedZohoService.setRemoteToUploading failed.")
                            NotificationCenter.default.post(name: .didReceiveError, object: prjID)
                        }
                    }
                    
                    GoogleService.sharedGoogleService.uploadProject(withData: self.prjData) { (success, error) in
                        if let err = error {
                            print("GoogleService.sharedGoogleService.uploadProject failed. Error=\(err)")
                            NotificationCenter.default.post(name: .didReceiveError, object: prjID)
                            return
                        }
                        
                        if success {
                            print("GoogleService.sharedGoogleService.uploadProject successfully.")
                            ZohoService.sharedZohoService.uploadProject(withData: self.prjData, onCompleted: { (success) in
                                if success {
                                    print("ZohoService.sharedZohoService.uploadProject successfully.")
                                    NotificationCenter.default.post(name: .didReceiveComplete, object: prjID)
                                } else {
                                    print("ZohoService.sharedZohoService.uploadProject failed.")
                                    NotificationCenter.default.post(name: .didReceiveError, object: prjID)
                                    return
                                }
                            })
                        }
                    }
                    
                } else {
                    NotificationCenter.default.post(name: .didReceiveWarning, object: "Offline Mode. File(s) saved sucessfully, will be uploaded later.")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    LoadingIndicatorView.hide()
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
}

extension ReviewViewController {
    
    private func loadData() {
    }
    
    private func setupViewModel() {
        let viewModel = prjData.prjInformation.map { (key, value) -> ReviewViewModel in
            return ReviewViewModel(key: key, value: value)
        }
        
        observableViewModel = Observable.of(viewModel)
    }

    private func setupView() {
        self.title = "Review"
    }
    
    private func setupCell() {
        observableViewModel.asObservable()
            .bind(to: tableView.rx.items(cellIdentifier: "ReviewCell", cellType: ReviewCell.self)) { (row, element, cell) in
                cell.labelKey.text = element.key
                cell.labelValue.text = element.value
            }
            .disposed(by: disposeBag)
    }
    
}
