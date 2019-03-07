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
    private var prjData = SiteAssessmentDataStructure()
    
    let disposeBag = DisposeBag()
    
    var observableViewModel: Observable<[ProjectInformationViewModel]>!

    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupView()
        setupViewModel()
        setupCell()
    }

    static func instantiateFromStoryBoard(withProjectData data: SiteAssessmentDataStructure) -> ProjectInformationViewController {
        let viewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "ProjectInformationViewController") as! ProjectInformationViewController
        viewController.prjData = data
        viewController.titleString = data.prjInformation["Project Address"]!
        
        return viewController
    }
    
    private func setupView() {
        self.title = titleString
        self.view.backgroundColor = UIColor.white
    }
    
    private func setupViewModel() {
        let viewModel = prjData.prjInformation.map { (key, value) -> ProjectInformationViewModel in
            return ProjectInformationViewModel(key: key, value: value)
        }

        observableViewModel = Observable.of(viewModel)
    }
    
    private func setupCell() {
        observableViewModel
            .bind(to: tableView.rx.items) { (tableView, row, data) in
                let cell = tableView.dequeueReusableCell(withIdentifier: "InformationCell", for: IndexPath(row: row, section: 0)) as! InformationCell

                cell.setupCell(viewModel: data)
                return cell
            }
            .disposed(by: disposeBag)
    }

    @IBAction func buttonStartDidClicked(_ sender: Any) {
        let viewController = NewProjectReportViewController.instantiateFromStoryBoard(withProjectData: prjData)
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}
