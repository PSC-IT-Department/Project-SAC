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
    
    @IBAction func saveButtonDidClicked(_ sender: Any) {
        print("Save all selection and photos.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
