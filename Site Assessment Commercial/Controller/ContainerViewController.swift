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
    var prjData = DataStorageService.shared.retrieveCurrentProjectData()

    static let id = "ContainerViewController"

    var menuViewController: PagingMenuViewController!
    var contentViewController: PagingContentViewController!

    static var sizingCell = TitleLabelMenuViewCell(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

    private var totalMissingSections: [String: Bool] = [:] {
        didSet {
            let totalCount = totalMissingSections.dropLast().count
            let count = totalMissingSections.dropLast().filter({$0.value == true}).count
            totalMissing = totalCount - count
        }
    }

    private var totalMissing: Int = -1 {
        didSet {
            print("totalMissing = \(totalMissing)")
            if totalMissing == 0 {
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

        menuViewController.register(type: TitleLabelMenuViewCell.self, forCellWithReuseIdentifier: "identifier")
        menuViewController.registerFocusView(view: UnderlineFocusView())
        
        dataSource = makeDataSource()

        setupReviewButtonTapHandling()
    }
    
    private func makeDataSource() -> [(menu: String, content: UIViewController)] {
        var _totalMissingSections: [String: Bool] = [:]
        let _dataSource = prjData.prjQuestionnaire.compactMap({section -> (menu: String, content: UIViewController) in
            let title = section.Name
            let content = ContentTableViewController.instantiateFromStoryBoard(section: section.self)
            content.upperViewController = self

            _totalMissingSections.updateValue(false, forKey: section.Name)
            return (menu: title, content: content)
        })

        totalMissingSections = _totalMissingSections

        return _dataSource
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
    
    func sectionReadyToReview(section: String, numberOfQuestions: Int) {
        totalMissingSections.updateValue(true, forKey: section)
    }

    func setupPrjDataQuestionnaire(sections: [SectionStructure]) {

        let _prjData = prjData
        autoreleasepool {
            sections.forEach {[weak self] (section) in
                if let sectionIndex = _prjData.prjQuestionnaire.firstIndex(where: {$0.Name == section.Name}) {
                    self?.prjData.prjQuestionnaire[sectionIndex] = section
                }
            }
        }
    }

    func setupReviewButtonTapHandling() {
        reviewButton
            .rx
            .tap
            .subscribe(onNext: { [weak self] (_) in
                guard let allVc = self?.dataSource.compactMap({$0.content as? ContentTableViewController})
                    else { return }

                let allVcData = allVc.compactMap({$0.getData()})
                let allVcImages = allVc.compactMap({$0.getImages()})
                let _prjData = self?.prjData

                let data = allVcData.compactMap({ eachSection -> SectionStructure? in
                    let section = eachSection.flatMap({$0.items})
                    if let sectionName = eachSection.filter({!$0.model.contains("#") && !$0.model.contains("-")})
                                        .first?
                                        .model,
                        var returnedSection = _prjData?.prjQuestionnaire
                                                        .filter({$0.Name == sectionName})
                                                        .first {
                        let questionsSection = returnedSection.Questions
                                                .compactMap({ (question) -> QuestionStructure? in
                            var q = question
                            
                            let value = section.filter({$0.Name == question.Name})
                                                .compactMap({$0.Value})
                                                .joined(separator: ", ")
                            
                            q.Value = value
                            return q
                        })
                        
                        returnedSection.Questions = questionsSection
                        return returnedSection
                    } else {
                        return nil
                    }
                })

                self?.setupPrjDataQuestionnaire(sections: data)
                self?.prjData.prjImageArray = allVcImages

                guard let totalMissing = self?.totalMissing,
                    let newPrjData = self?.prjData
                    else { return }
                
                DataStorageService.shared.storeCurrentProjectData(data: newPrjData)
                DataStorageService.shared.storeData(withData: newPrjData, onCompleted: nil)
                
                let banner = StatusBarNotificationBanner(title: "Project data saved successfully.", style: .success)
                banner.show()

                //print("To-Do: if totalMissing >= 0 change to if totalMissing == 0")
                if totalMissing == 0 {
                    if let vc = ReviewViewController.instantiateFromStoryBoard(withProjectData: newPrjData) {
                        self?.navigationController?.pushViewController(vc, animated: true)
                    }
                } else {
                    let msgContent = allVcData.dropLast()
                                                .compactMap({ (content) -> [(modelName: String, items: [String])] in
                        return content.compactMap({ (section) -> (modelName: String, items: [String])? in
                            let model = section.model
                            let questions = section.items
                                                    .filter({($0.Value == nil || $0.Value == "") &&
                                                            $0.Mandatory == "Yes"})
                            if questions.isEmpty {
                                return nil
                            }
                            let questionNames = questions.compactMap({$0.Name})
                            return (modelName: model, items: questionNames)
                        })
                    }).first?.first

                    if let sectionName = msgContent?.modelName,
                        let firstQuestion = msgContent?.items.first {

                        let title = "Project data saved successfully."
                        let msg = "Complete the questionnaire to proceed to next step"
                            + ", still Missing: \(totalMissing) sections.\n"
                            + "Section: \(sectionName), question: \(firstQuestion)"
                        let popup = PopupDialog(title: title, message: msg)

                        let confirmButton = PopupDialogButton(title: "OK", action: nil)

                        popup.addButton(confirmButton)

                        self?.present(popup, animated: true, completion: nil)
                    }
                }
            })
            .disposed(by: disposeBag)
    }

    deinit {
        print("ContainerViewController deinit")
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
