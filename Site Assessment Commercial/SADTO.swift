//
//  SADTO.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-29.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxDataSources

import MapKit

enum MapTypeOptions: UInt {
    case standard   = 0
    case satellite  = 1
    case hybrid     = 2
    
    var type: (index: Int, description: String) {
        switch self {
        case .standard:
            return (0, "Standard")
            
        case .satellite:
            return (1, "Satellite")
            
        case .hybrid:
            return (2, "Hybrid")
        }
    }
}

enum GroupingOptions: String {
    case none         = "None"
    case status       = "Status"
    case scheduleDate = "Schedule Date"
    case assignedTeam = "Assigned Team"
}

enum UploadStatus: String, Codable {
    case pending     = "Pending"
    case uploading   = "Uploading"
    case completed   = "Completed"
}

enum SiteAssessmentType: String, Codable {
    case SiteAssessmentNone        = "None"
    case SiteAssessmentResidential = "Residential"
    case SiteAssessmentCommercial  = "Commercial"
}

struct ProjectInformationStructure: Codable {
    var projectAddress: String!
    var projectID: String!
    var type: SiteAssessmentType!
    var status: UploadStatus!
    
    var scheduleDate: String?
    var assignedTeam: String!
    var assignedDate: String!
    var uploadedDate: String?
    
    var customerName: String?
    var email: String?
    var phoneNumber: String?
    
    private enum CodingKeys: String, CodingKey {
        case projectAddress = "sa_projectAddress"
        case projectID      = "sa_projectID"
        case type           = "sa_type"
        case status         = "sa_status"
        
        case scheduleDate   = "sa_scheduleTime"
        case assignedTeam   = "sa_assignedTeam"
        case assignedDate   = "sa_assignedTime"
        case uploadedDate   = "sa_uploadedTime"
        
        case customerName   = "sa_customerName"
        case email          = "sa_email"
        case phoneNumber    = "sa_phoneNumber"
    }

    init() {
        projectAddress = ""
        projectID      = ""
        type           = .SiteAssessmentNone
        status         = .pending

        scheduleDate   = ""
        assignedTeam   = ""
        assignedDate   = ""
        uploadedDate   = ""
        
        customerName   = ""
        email          = ""
        phoneNumber    = ""
    }
    
    init(from decoder: Decoder) throws {
        let values      = try decoder.container(keyedBy: CodingKeys.self)
        projectAddress  = try values.decode(String.self, forKey: .projectAddress)
        projectID       = try values.decode(String.self, forKey: .projectID)
        type            = try values.decode(SiteAssessmentType.self, forKey: .type)
        status          = try values.decode(UploadStatus.self, forKey: .status)

        scheduleDate    = try values.decode(String.self, forKey: .scheduleDate)
        assignedTeam    = try values.decode(String.self, forKey: .assignedTeam)
        assignedDate    = try values.decode(String.self, forKey: .assignedDate)
        uploadedDate    = try values.decode(String.self, forKey: .uploadedDate)

        customerName    = try values.decode(String.self, forKey: .customerName)
        email           = try values.decode(String.self, forKey: .email)
        phoneNumber     = try values.decode(String.self, forKey: .phoneNumber)
    }
    
    init(withZohoData data: [String: String]) {
        guard let prjAddr = data[CodingKeys.projectAddress.rawValue],
            let prjID = data[CodingKeys.projectID.rawValue],
            let type = data[CodingKeys.type.rawValue],
            let typeValue = SiteAssessmentType(rawValue: type),
            let assignedTeam = data[CodingKeys.assignedTeam.rawValue],
            let assignedDate = data[CodingKeys.assignedDate.rawValue]
            else {
                DataStorageService.shared.writeToLog("withZohoData failed.")
                print("withZohoData failed.")
                return
        }

        self.projectAddress = prjAddr
        self.projectID      = prjID
        
        self.type           = typeValue
        self.status         = .pending
        
        self.scheduleDate   = data[CodingKeys.scheduleDate.rawValue]
        
        self.assignedDate   = assignedDate

        self.assignedTeam   = assignedTeam
        self.uploadedDate   = ""
        
        self.customerName   = data[CodingKeys.customerName.rawValue]
        self.email          = data[CodingKeys.email.rawValue]
        self.phoneNumber    = data[CodingKeys.phoneNumber.rawValue]
    }
    
    func toDictionary() -> [String: String?] {
        
       return [
            "Project Address": projectAddress,
            "Project ID": projectID,
            "Type": type.rawValue,
            "Status": status.rawValue,
            "Schedule Time": scheduleDate,
            "Assigned Team": assignedTeam,
            "Assigned Time": assignedDate,
            "Uploaded Time": uploadedDate,
            
            "Customer Name": customerName,
            "Email": email,
            "Phone Number": phoneNumber
        ]
    }
}

struct ImageAttributes: Codable {
    var name: String
    var status: UploadStatus
    
    private enum CodingKeys: CodingKey {
        case name
        case status
    }
    
    init() {
        name = ""
        status = .pending
    }
    
    init(name: String, status: UploadStatus = .pending) {
        self.name = name
        self.status = status
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name    = try values.decode(String.self, forKey: .name)
        status  = try values.decode(UploadStatus.self, forKey: .status)
    }
}

struct CategoryImageArrayStructure: Codable {
    var name: String
    var count: Int
    var sections: [SectionImageArrayStructure] {
        didSet {
            count = sections.reduce(0, { (result, section) -> Int in
                return result + section.count
            })
        }
    }

    private enum CodingKeys: CodingKey {
        case name
        case sections
        case count
    }

    init() {
        name = ""
        sections = []
        count = 0
    }

    init(name: String, imageArray: [SectionImageArrayStructure]) {
        self.name = name
        self.count = 0
        self.sections = imageArray
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        sections = try values.decode([SectionImageArrayStructure].self, forKey: .sections)
        count = try values.decode(Int.self, forKey: .count)
    }
}

struct SectionImageArrayStructure: Codable {
    var name: String
    var count: Int
    var imageArrays: [ImageArrayStructure] {
        didSet {
            count = imageArrays.reduce(0, { (result, array) -> Int in
                return result + array.count
            })
        }
    }

    private enum CodingKeys: CodingKey {
        case name
        case imageArrays
        case count
    }

    init() {
        name = ""
        imageArrays = []
        count = 0
    }

    init(name: String, imageArrays: [ImageArrayStructure]) {
        self.name = name
        self.count = 0
        self.imageArrays = imageArrays
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        imageArrays = try values.decode([ImageArrayStructure].self, forKey: .imageArrays)
        count = try values.decode(Int.self, forKey: .count)
    }
}

struct ImageArrayStructure: Codable {
    var key: String
    var count: Int
    var images: [ImageAttributes]? {
        didSet {
            count = images?.count ?? 0
        }
    }

    private enum CodingKeys: CodingKey {
        case key
        case images
        case count
    }

    init() {
        key = ""
        images = []
        count = 0
    }

    init(key: String, images: [ImageAttributes]?) {
        self.key = key
        self.images = images
        self.count = images?.count ?? 0
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key        = try values.decode(String.self, forKey: .key)
        images     = try values.decode([ImageAttributes].self, forKey: .images)
        count      = try values.decode(Int.self, forKey: .count)
    }
}

struct SiteAssessmentDataStructure: Codable, Equatable {
    var prjInformation: ProjectInformationStructure
    var prjQuestionnaire: [SectionStructure]
    var prjImageArray: [CategoryImageArrayStructure]
    
    private enum CodingKeys: String, CodingKey {
        case prjInformation = "detail"
        case prjQuestionnaire = "questionnaire"
        case prjImageArray = "imageArray"
    }
    
    init() {
        prjInformation = ProjectInformationStructure()
        prjQuestionnaire = []
        prjImageArray = []
    }
    
    init(with info: ProjectInformationStructure, questions: [SectionStructure], array: [CategoryImageArrayStructure]) {
        prjInformation = info
        prjQuestionnaire = questions
        prjImageArray = array
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        prjInformation      = try values.decode(ProjectInformationStructure.self, forKey: .prjInformation)
        prjQuestionnaire    = try values.decode([SectionStructure].self, forKey: .prjQuestionnaire)
        prjImageArray       = try values.decode([CategoryImageArrayStructure].self, forKey: .prjImageArray)
    }
    
    init(withZohoData data: [String: String]) {
        prjInformation = ProjectInformationStructure(withZohoData: data)
        prjImageArray = []
        
        let bundle = Bundle.main
        let typeValue = prjInformation.type.rawValue
        guard let path = bundle.url(forResource: typeValue, withExtension: "plist") else { prjQuestionnaire = []
            return
        }
        
        let result = Result {try Data(contentsOf: path)}.flatMap { (data) -> Result<[SectionStructure], Error> in
            return Result {try PropertyListDecoder().decode([SectionStructure].self, from: data)}
        }
        
        switch result {
        case .success(let allData):
            prjQuestionnaire = allData
            
            allData.enumerated().forEach {(arg) in

                let (sectionNum, section) = arg
                section.Questions.enumerated().forEach({ (questionIndex, question) in
                    if let theData = data.first(where: { (key, _) -> Bool in
                        key == question.Key }) {
                        prjQuestionnaire[sectionNum].Questions[questionIndex].Value = theData.value
                    }
                })
            }
            
//            let allImageQuestions = allData.compactMap({$0.Questions}).joined().filter({$0.QType == .image})
//            let imageArray = allImageQuestions.compactMap({ImageArrayStructure(key: $0.Name, images: [])})

//            print("To-Do: //prjImageArray = imageArray")
            //prjImageArray = imageArray

        case .failure(let error):
            print("Decoder failed. Error = \(error)")
            prjQuestionnaire = []
        }
    }
    
    static func == (lhs: SiteAssessmentDataStructure, rhs: SiteAssessmentDataStructure) -> Bool {
        return lhs.prjInformation.projectID == rhs.prjInformation.projectID
    }
}

struct QuestionStructure: IdentifiableType, Codable, Equatable, Hashable {
    var identity: Int?
    
    var Name: String
    var Key: String
    var QType: NewProjectReportCellType
    var Options: [String]?
    var Default: String?
    var Image: String?
    var isHidden: String
    var Mandatory: String
    var Value: String?
    var Interdependence: String?
    var Dependent: [String: String]?
    
    private enum CodingKeys: String, CodingKey {
        case Name
        case Key
        case QType = "Type"
        case Options
        case Default
        case Image
        case isHidden
        case Mandatory
        case Value
        case Interdependence
        case Dependent
    }
    
    static func == (lhs: QuestionStructure, rhs: QuestionStructure) -> Bool {
        return lhs.Name == rhs.Name && lhs.Key == rhs.Key
    }
    
    func hash(into: Int) {
        
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        Name        = try values.decode(String.self, forKey: .Name)
        Key         = try values.decode(String.self, forKey: .Key)
        QType       = try values.decode(NewProjectReportCellType.self, forKey: .QType)
        Options     = try values.decode([String].self, forKey: .Options)
        Default     = try values.decode(String.self, forKey: .Default)
        Image       = try values.decode(String.self, forKey: .Image)
        isHidden    = try values.decode(String.self, forKey: .isHidden)
        Mandatory   = try values.decode(String.self, forKey: .Mandatory)
        Interdependence = try values.decode(String.self, forKey: .Interdependence)
        Dependent  = try values.decode([String: String].self, forKey: .Dependent)
        Value       = try values.decode(String.self, forKey: .Value)
        identity    = 0
    }
    
    init(question: QuestionStructure) {
        self.Name        = question.Name
        self.Key         = question.Key
        self.QType       = question.QType
        self.Options     = question.Options
        self.Default     = question.Default
        self.isHidden    = question.isHidden
        self.Mandatory   = question.Mandatory
        self.Image       = question.Image
        self.Interdependence = question.Interdependence
        self.Dependent   = question.Dependent
        self.Value       = question.Value
        self.identity    = question.identity
    }
    
    init() {
        Name        = ""
        Key         = ""
        QType       = .inputs
        Options     = nil
        Default     = nil
        isHidden    = "Yes"
        Mandatory   = "No"
        Image       = nil
        Interdependence = nil
        Dependent   = nil
        Value       = nil
        identity    = nil
    }
    
}

struct SectionStructure: Codable {
    var Name: String
    var Questions: [QuestionStructure]

    init() {
        self.Name = ""
        self.Questions = []
    }
    
    private enum CodingKeys: String, CodingKey {
        case Name
        case Questions
    }
    
    init(name: String, questions: [QuestionStructure]) {
        self.Name = name
        self.Questions = questions
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        Name       = try values.decode(String.self, forKey: .Name)
        Questions  = try values.decode([QuestionStructure].self, forKey: .Questions)
    }
}

struct QuestionnaireConfigsWrapper: Codable {
    var QuestionaireConfigs: [SectionStructure]
}
