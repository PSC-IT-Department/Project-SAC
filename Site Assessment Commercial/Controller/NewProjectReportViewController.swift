//
//  NewProjectReportViewController.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-23.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

typealias NumberSection = AnimatableSectionModel<String, Int>
typealias EachSection = AnimatableSectionModel<String, QuestionaireConfigs_QuestionsWrapper>

struct QuestionaireConfigs_QuestionsWrapper: IdentifiableType, Codable, Equatable, Hashable {
    var identity: Int

    var Name: String
    var Key: String
    var QType: NewProjectReportCellType
    var Options: [String]
    var Default: String
    var Mandatory: String
    
    private enum CodingKeys: String, CodingKey {
        case Name
        case Key
        case QType = "Type"
        case Options
        case Default
        case Mandatory
    }
    
    static func == (lhs: QuestionaireConfigs_QuestionsWrapper, rhs: QuestionaireConfigs_QuestionsWrapper) -> Bool {
        return lhs.Name == rhs.Name
    }
    
    var hashValue: Int {
        return self.Name.hashValue
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        Name        = try values.decode(String.self, forKey: .Name)
        Key         = try values.decode(String.self, forKey: .Key)
        QType       = try values.decode(NewProjectReportCellType.self, forKey: .QType)
        Options     = try values.decode([String].self, forKey: .Options)
        Default     = try values.decode(String.self, forKey: .Default)
        Mandatory   = try values.decode(String.self, forKey: .Mandatory)
        identity    = 0
    }
}

struct QuestionaireConfigs_SectionsWrapper: Codable {
    var Name: String
    var Questions: [QuestionaireConfigs_QuestionsWrapper]
}

struct QuestionnaireConfigsWrapper: Codable {
    var QuestionaireConfigs: [QuestionaireConfigs_SectionsWrapper]
}

class NewProjectReportViewController: UIViewController, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var sections = BehaviorRelay(value: [EachSection]())
    
    let disposeBag = DisposeBag()
    
    var initialValue: [EachSection]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialValue = loadData()
        
        let (configureCollectionViewCell, configureSupplementaryView) = NewProjectReportViewController.collectionViewDataSourceUI()

        let cvReloadDataSource = RxCollectionViewSectionedReloadDataSource (
            configureCell: configureCollectionViewCell,
            configureSupplementaryView: configureSupplementaryView
        )
        
        if let value = initialValue {
            self.sections.accept(value)

            self.sections.asObservable()
                .bind(to: collectionView.rx.items(dataSource: cvReloadDataSource))
                .disposed(by: disposeBag)
        }
        
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)

    }
    
    func loadData()->[EachSection]? {
        guard let path = Bundle.main.url(forResource: "QuestionnaireConfigs", withExtension: "plist") else {
            print("QuestionnaireConfigs file cannot find.")
            return nil
        }
        
        if let plistData = try? Data(contentsOf: path) {
            do {
                let decoder = PropertyListDecoder()
                
                let allData = try decoder.decode([QuestionaireConfigs_SectionsWrapper].self, from: plistData)
                
                return allData.map { row in
                  return EachSection(model: row.Name, items: row.Questions)
                }
            } catch {
                print(error)
                return nil
            }
        }
        
        return nil
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = collectionView.bounds.width
        var height = CGFloat(50)
        
        let section = indexPath.section
        
        let type = initialValue![section].items[indexPath.item].QType
        switch type {
        case .ar, .image, .notes:
            height = CGFloat(400)
        case .singleSelection:
            height = CGFloat(95)
        default:
            height = CGFloat(50)
        }
        
        return CGSize(width: width, height: height)
    }
    
}

extension NewProjectReportViewController {
    static func collectionViewDataSourceUI() -> (
        CollectionViewSectionedDataSource<EachSection>.ConfigureCell,
        CollectionViewSectionedDataSource<EachSection>.ConfigureSupplementaryView
        ) {
            return (
                { (_, cv, ip, i) in
                    switch i.QType {
                    case .image:
                        let cell = cv.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: ip) as! ImageCell
                        cell.labelKey.text = i.Name
                        return cell
                        
                    case .ar:
                        let cell = cv.dequeueReusableCell(withReuseIdentifier: "ARCell", for: ip) as! ARCell
                        cell.labelKey.text = i.Name
                        return cell
                        
                    case .notes:
                        let cell = cv.dequeueReusableCell(withReuseIdentifier: "NotesCell", for: ip) as! NotesCell
                        cell.labelKey.text = i.Name
                        return cell
                        
                    case .singleInput:
                        let cell = cv.dequeueReusableCell(withReuseIdentifier: "SingleInputCell", for: ip) as! SingleInputCell
                        cell.labelKey.text = i.Name
                        return cell
                        
                    case .singleSelection:
                        let cell = cv.dequeueReusableCell(withReuseIdentifier: "SingleSelectionCell", for: ip) as! SingleSelectionCell
                        cell.labelKey.text = i.Name
                        
                        for btnIdx in 1001...1004 {
                            if let button = cell.viewWithTag(btnIdx) as? UIButton {
                                button.isHidden = true
                            }
                        }
                        _ = i.Options.enumerated().map { (idx, option) in
                            if let button = cell.viewWithTag(1000+idx+1) as? UIButton {
                                button.setTitle(option, for: .normal)
                                button.isHidden = false
                            }
                        }
                        
                        // cell.imageviewReference.image = UIImage(s)
                        cell.imageviewReference.isHidden = true
                    
                        return cell
                        
                    case .threeInputs:
                        let cell = cv.dequeueReusableCell(withReuseIdentifier: "ThreeInputsCell", for: ip) as! ThreeInputsCell
                        cell.labelKey.text = i.Name
                        return cell
                        
                    case .twoInputs:
                        let cell = cv.dequeueReusableCell(withReuseIdentifier: "TwoInputsCell", for: ip) as! TwoInputsCell
                        cell.labelKey.text = i.Name
                        return cell
                        
                    }
                    
            },
                { (ds, cv, kind, ip) in
                    let section = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Section", for: ip) as! CollectionReusableView
                    section.labelSectionName.text = "\(ds[ip.section].model)"
                    return section
            }
        )
    }
}
