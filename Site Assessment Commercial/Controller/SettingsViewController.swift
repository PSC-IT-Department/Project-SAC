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

import GoogleSignIn

class SettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        let items = Observable.just(
            ["Google", "Zoho CRM"]
        )
        
        items
            .bind(to: tableView.rx.items(cellIdentifier: "SettingsCell", cellType: SettingsCell.self)) { (row, element, cell) in
                
                switch row {
                case 0:
                    cell.label.text = element
                    if let userEmail = GoogleService.sharedGoogleService.retrieveGoogleUserEmail() {
                        cell.accessoryType = .checkmark
                        
                        cell.label.text?.append(" - \(userEmail)")
                    }
                default:
                    cell.label.text = element
                }
            }
            .disposed(by: disposeBag)
        
        tableView.rx
            .itemSelected
            .subscribe(onNext:  { value in
                if let selectedRowIndexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: selectedRowIndexPath, animated: true)
                    
                    switch selectedRowIndexPath.row {
                    // Google
                    case 0:
                        let vc = ThirdPartyAccessViewController.instantiateFromStoryBoard(withTitle: "Google") 
                        
                        self.navigationController?.pushViewController(vc, animated: true)
                    default:
                        print("Selected.")
                        
                    }
                }
            })
            .disposed(by: disposeBag)
    }
}

extension SettingsViewController {
    
    private func setupView() {
        self.title = "Settings"
    }
    
}
