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
        
        self.title = "Settings"
        
        let items = Observable.just(
            ["Google Drive", "Zoho CRM"]
        )
        
        items
            .bind(to: tableView.rx.items(cellIdentifier: "SettingsCell", cellType: SettingsCell.self)) { (row, element, cell) in
                
                cell.label.text = element
            }
            .disposed(by: disposeBag)
        
        tableView.rx
            .itemSelected
            .subscribe(onNext:  { value in
                if let selectedRowIndexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: selectedRowIndexPath, animated: true)
                    
                    print("Item Selected.")
                }
            })
            .disposed(by: disposeBag)
    }
}
