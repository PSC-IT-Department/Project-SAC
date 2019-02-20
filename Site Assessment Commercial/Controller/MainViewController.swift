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

class MainViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var labelCurrentUser: UILabel!
    @IBOutlet weak var tableView: UITableView!

    var allMightyData: [SADTO]!
    var observableViewModel: Observable<[MainViewModel]>!
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Project List"
        self.view.backgroundColor = UIColor.white
        
        loadData()
        setupCurrentUser()
        setupViewModel()
        setupCellConfiguration()
        setupCellTapHandling()
        setupCellGestures()

    }
}

extension MainViewController {
    
    private func loadData() {
        allMightyData = DataStorageService.sharedDataStorageService.retrieveData()
    }
    
    private func setupCurrentUser() {
        
        if let user = UserDefaults.standard.object(forKey: "GoogleAccount") as? GIDGoogleUser {
        // if let user = GIDSignIn.sharedInstance()?.currentUser {
            labelCurrentUser.text = "Signed in as \(String(describing: user.profile.email))."
            labelCurrentUser.isUserInteractionEnabled = false
        } else {
            let attributedText = NSAttributedString(string: "Please sign in.", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
            labelCurrentUser.attributedText = attributedText
            
            labelCurrentUser.isUserInteractionEnabled = true
            labelCurrentUser.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.jumpToGoogleSignIn(_:))))
        
        }
    }
    
    @objc func jumpToGoogleSignIn(_ sender: UITapGestureRecognizer) {
        print("Jump to Google signin view controller.")
    }
    
    private func setupViewModel() {
        let viewModel:[MainViewModel] = allMightyData.map{data in
            return MainViewModel(status: data.status, projectAddress: data.projectAddress)
        }
        
        observableViewModel = Observable.of(viewModel)
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
            .subscribe(onNext: {
                rowData in
                if let selectedRowIndexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: selectedRowIndexPath, animated: true)

                    let vc = ProjectInformationViewController.instantiateFromStoryBoard(withTitle: rowData.projectAddress)

                    self.navigationController?.pushViewController(vc, animated: true)
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
}
