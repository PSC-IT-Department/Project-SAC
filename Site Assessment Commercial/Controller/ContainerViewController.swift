//
//  ContainerViewController.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-07-24.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import UIKit

import RxCocoa
import RxSwift

import PagingKit
import NotificationBannerSwift
import PopupDialog

class ContainerViewController: UIViewController {
    let prjData = DataStorageService.shared.retrieveCurrentProjectData()
       
    static let id = "ContainerViewController"

    var menuViewController: PagingMenuViewController!
    var contentViewController: PagingContentViewController!

    static var sizingCell = TitleLabelMenuViewCell(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    
    private var totalMissing: Int = -1 {
        didSet {
            if self.totalMissing == 0 {
                setupReviewButton(status: .review)
            }
        }
    }

    var dataSource = [(menu: String, content: UIViewController)]() {
        didSet {
            menuViewController.reloadData()
            contentViewController.reloadData()
        }
    }
    
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var reviewButton: UIButton!
    
    static func instantiateFromStoryBoard() -> ContainerViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: id) as? ContainerViewController
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Questionnaire"

        menuViewController.register(type: TitleLabelMenuViewCell.self, forCellWithReuseIdentifier: "identifier")
        menuViewController.registerFocusView(view: UnderlineFocusView())
        
        dataSource = makeDataSource()
        
        setupReviewButtonTapHandling()
    }
    
    private func makeDataSource() -> [(menu: String, content: UIViewController)] {
        return prjData.prjQuestionnaire.compactMap({
            let title = $0.Name
            let content = ContentTableViewController.instantiateFromStoryBoard(section: $0.self)
            return (menu: title, content: content)
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PagingMenuViewController {
            menuViewController = vc
            menuViewController.dataSource = self
            menuViewController.delegate = self
        } else if let vc = segue.destination as? PagingContentViewController {
            contentViewController = vc
            contentViewController.dataSource = self
            contentViewController.delegate = self
        }
    }
    
    func setupReviewButton(status: ReviewButtonStatus) {
        switch status {
        case .save:
            let title = ReviewButtonStatus.save.rawValue
            reviewButton.setTitle(title, for: .normal)
            reviewButton.backgroundColor = UIColor(named: "PSC_Blue")
            reviewButton.setTitleColor(UIColor.white, for: .normal)
        case .review:
            let title = ReviewButtonStatus.review.rawValue
            reviewButton.setTitle(title, for: .normal)
            reviewButton.backgroundColor = UIColor(named: "PSC_Green")
            reviewButton.setTitleColor(UIColor.white, for: .normal)
        }
    }
    
    func setupReviewButtonTapHandling() {
        reviewButton
            .rx
            .tap
            .subscribe(onNext: { [weak self] (_) in
                guard let allVcData = self?.dataSource.compactMap({($0.content as? ContentTableViewController)?.getData()}) else { return }

                let data = allVcData.compactMap({ eachSection -> SectionStructure? in
                    
                    let section = eachSection.flatMap({$0.items})

                    if let sectionName = eachSection.filter({$0.model != "" && !$0.model.contains("-")}).first?.model,
                        var returnedSection = self?.prjData.prjQuestionnaire.filter({$0.Name == sectionName}).first

                        {
                            let questionsSection = returnedSection.Questions.compactMap({ (question) -> QuestionStructure? in
                                var q = question
                                
                                let value = section.filter({$0.Name == question.Name}).compactMap({$0.Value}).joined(separator: ", ")
                                
                                q.Value = value
                                return q
                            })
                            
                            returnedSection.Questions = questionsSection
                            return returnedSection
                    } else {
                        return nil
                    }
                })
                
                print("data = \(data)")
                
                guard let totalMissing = self?.totalMissing,
                    let newPrjData = self?.prjData
                    else { return }
                
                DataStorageService.shared.storeCurrentProjectData(data: newPrjData)
                DataStorageService.shared.storeData(withData: newPrjData, onCompleted: nil)
                
                let banner = StatusBarNotificationBanner(title: "Project data saved successfully.", style: .success)
                banner.show()
                
                if totalMissing == 0 {
                    if let vc = ReviewViewController.instantiateFromStoryBoard(withProjectData: newPrjData) {
                        self?.navigationController?.pushViewController(vc, animated: true)
                    }
                } else {
                    let title = "Project data saved successfully."
                    let msg = "Complete the questionnaire to proceed to next step, still Missing: \(totalMissing)."
                    let popup = PopupDialog(title: title, message: msg)
                    
                    let confirmButton = PopupDialogButton(title: "OK", action: nil)
                    
                    popup.addButton(confirmButton)
                    
                    self?.present(popup, animated: true, completion: nil)
                }
                
            })
            .disposed(by: disposeBag)
    }
}

extension ContainerViewController: PagingMenuViewControllerDataSource {
    func numberOfItemsForMenuViewController(viewController: PagingMenuViewController) -> Int {
        return dataSource.count
    }
    
    func menuViewController(viewController: PagingMenuViewController, widthForItemAt index: Int) -> CGFloat {
        ContainerViewController.sizingCell.titleLabel.text = dataSource[index].menu
        var referenceSize = UIView.layoutFittingCompressedSize
        referenceSize.height = viewController.view.bounds.height
        let size = ContainerViewController.sizingCell.systemLayoutSizeFitting(referenceSize)
        return size.width
    }
    
    func menuViewController(viewController: PagingMenuViewController, cellForItemAt index: Int) -> PagingMenuViewCell {
        let cell = viewController.dequeueReusableCell(withReuseIdentifier: "identifier",
                                                      for: index) as! TitleLabelMenuViewCell
        cell.titleLabel.text = dataSource[index].menu
        return cell
    }
}

extension ContainerViewController: PagingContentViewControllerDataSource {
    func numberOfItemsForContentViewController(viewController: PagingContentViewController) -> Int {
        return dataSource.count
    }
    
    func contentViewController(viewController: PagingContentViewController,
                               viewControllerAt index: Int) -> UIViewController {
        return dataSource[index].content
    }
}

extension ContainerViewController: PagingMenuViewControllerDelegate {
    func menuViewController(viewController: PagingMenuViewController,
                            didSelect page: Int, previousPage: Int) {
        contentViewController.scroll(to: page, animated: true)
    }
}

extension ContainerViewController: PagingContentViewControllerDelegate {
    func contentViewController(viewController: PagingContentViewController,
                               didManualScrollOn index: Int, percent: CGFloat) {
        menuViewController.scroll(index: index, percent: percent, animated: false)
    }
}
