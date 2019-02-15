//
//  ProjectInformationViewController.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-23.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ProjectInformationViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    private var titleString: String!
    var data: [ProjectInformationViewModel]!
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = titleString
        self.view.backgroundColor = UIColor.white
        
        setupViewModel()
        setupCell()
    }

    static func instantiateFromStoryBoard(withTitle title: String) -> ProjectInformationViewController {
        let viewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "ProjectInformationViewController") as! ProjectInformationViewController
        viewController.titleString = title
        return viewController
    }
    
    private func setupViewModel()
    {
        
    }
    
    private func setupCell() {
        
        let observable = Observable.of(ProjectInformationViewModel.data)
        
        observable
            .bind(to: tableView.rx.items) { (tableView, row, data) in
                let cell = tableView.dequeueReusableCell(withIdentifier: "InformationCell", for: IndexPath(row: row, section: 0)) as! InformationCell

                cell.setupCell(viewModel: data)
                return cell
            }
            .disposed(by: disposeBag)
        
    }

}
