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

class SettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
        
        let items = Observable.just(
            (0..<20).map { "\($0)" }
        )
        
        items
            .bind(to: tableView.rx.items(cellIdentifier: "SettingsCell", cellType: SettingsCell.self)) { (row, element, cell) in
                
                cell.label.text = "\(element) @ row \(row)"
            }
            .disposed(by: disposeBag)
        /*
        tableView.rx
            .modelSelected(String.self)
            .subscribe(onNext:  { value in
                print("Hello, World!")
            })
            .disposed(by: disposeBag)
        
        tableView.rx
            .itemAccessoryButtonTapped
            .subscribe(onNext: { indexPath in
                print("hello, World!")
            })
            .disposed(by: disposeBag)
        */
    }
}
