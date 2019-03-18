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

enum GroupingOptions: String {
    case none         = "None"
    case status       = "Status"
    case scheduleDate = "Schedule Date"
    case assignedTeam = "Assigned Team"
}

public struct SADTO: Codable, Equatable {
    
    // SYSTEM
    var projectAddress: String
    var projectID: String
    var status: String
    var scheduleDate: String?
    var assignedDate: String?
    var assignedTeam: String?
    
    // LAYOUT
    var copyOfStructuralLayout: String?
    var copyOfFloorPlan: String?
    var copyOfElectricalDrawing: String?
    
    // STRUCTURAL
    var structuralType: String?
    var areaOfPropertySite: String?
    var buildingHeight: String?
    var mainBeamSpacing: String?
    var openWebSteelJoistSpacing_OWSJ: String?
    var openWebSteelJoistSpacing_D: String?
    var heightofwebsteelJoist: String?
    var endThreeWebMemberType: String?
    var endThreeWebMemberTypeNotes: String?
    var sizeOfEndThreeWebMember: String?
    var sizeOfBottomChord: String?
    
    // REQUIRED STRUCTURAL PHOTOS
    var photos_mainBeam: String?
    var photos_openWebSteelJoist: String?
    var photos_bottomChord: String?
    var photos_webMember: String?
    
    // ELECTRICAL
    var electricalMeterRoomDimension: String?
    var service: String?
    var numberOfService: String?
 
    var service1_capacity: String?
    var service1_serviceSwitchRating: String?
    var service1_distributionPanelRating: String?
    var service1_switchRating: String?
    var service1_circuitBreakerRating: String?
    
    var service2_capacity: String?
    var service2_serviceSwitchRating: String?
    var service2_distributionPanelRating: String?
    var service2_switchRating: String?
    var service2_circuitBreakerRating: String?
    
    var service3_capacity: String?
    var service3_serviceSwitchRating: String?
    var service3_distributionPanelRating: String?
    var service3_switchRating: String?
    var service3_circuitBreakerRating: String?
    
    var service4_capacity: String?
    var service4_serviceSwitchRating: String?
    var service4_distributionPanelRating: String?
    var service4_switchRating: String?
    var service4_circuitBreakerRating: String?
    
    var service5_capacity: String?
    var service5_serviceSwitchRating: String?
    var service5_distributionPanelRating: String?
    var service5_switchRating: String?
    var service5_circuitBreakerRating: String?
    
    var transformerDetail: String?
    var multiMeter: String?
    var numberOfElectricalMeters: String?
    var electricalMeter1: String?
    var electricalMeter2: String?
    var electricalMeter3: String?
    var electricalMeter4: String?
    var electricalMeter5: String?
    var subPanelBoard: String?
    var subPanelBreakerRating: String?
    
    // REQUIERED ELECTRICAL PHOTOS
    var photos_transformer: String?
    var photos_electricalRoom: String?
    var photos_electricalMeter: String?
    var photos_distributionPanel: String?

    enum CodingKeys: String, CodingKey {
        case projectAddress                     = "sac_projectAddress"
        case projectID                          = "sac_projectID"
        case status                             = "sac_status"
        case scheduleDate                       = "sac_scheduleDate"
        case assignedDate                       = "sac_assignedDate"
        case assignedTeam                       = "sac_assignedTeam"

        case copyOfStructuralLayout             = "sac_copyOfStructuralLayout"
        case copyOfFloorPlan                    = "sac_copyOfFloorPlan"
        case copyOfElectricalDrawing            = "sac_copyOfElectricalDrawing"
        
        case structuralType                     = "sac_structuralType"
        case areaOfPropertySite                 = "sac_areaOfPropertySite"
        case buildingHeight                     = "sac_buildingHeight"
        case mainBeamSpacing                    = "sac_mainBeamSpacing"
        case openWebSteelJoistSpacing_OWSJ      = "sac_openWebSteelJoistSpacing_OWSJ"
        case openWebSteelJoistSpacing_D         = "sac_openWebSteelJoistSpacing_D"
        case heightofwebsteelJoist              = "sac_heightofwebsteelJoist"
        case endThreeWebMemberType              = "sac_endThreeWebMemberType"
        case endThreeWebMemberTypeNotes         = "sac_endThreeWebMemberTypeNotes"
        case sizeOfEndThreeWebMember            = "sac_sizeOfEndThreeWebMember"
        case sizeOfBottomChord                  = "sac_sizeOfBottomChord"
        
        case photos_mainBeam                    = "sac_photosMainBeam"
        case photos_openWebSteelJoist           = "sac_photosOpenWebSteelJoist"
        case photos_bottomChord                 = "sac_photosBottomChord"
        case photos_webMember                   = "sac_photosWebMember"
        
        case electricalMeterRoomDimension       = "sac_electricalMeterRoomDimension"
        case service                            = "sac_service"
        case numberOfService                    = "sac_numberOfService"
        
        case service1_capacity                  = "sac_service1_capacity"
        case service1_serviceSwitchRating       = "sac_service1_serviceSwitchRating"
        case service1_distributionPanelRating   = "sac_service1_distributionPanelRating"
        case service1_switchRating              = "sac_service1_switchRating"
        case service1_circuitBreakerRating      = "sac_service1_circuitBreakerRating"
        
        case service2_capacity                  = "sac_service2_capacity"
        case service2_serviceSwitchRating       = "sac_service2_serviceSwitchRating"
        case service2_distributionPanelRating   = "sac_service2_distributionPanelRating"
        case service2_switchRating              = "sac_service2_switchRating"
        case service2_circuitBreakerRating      = "sac_service2_circuitBreakerRating"
        
        case service3_capacity                  = "sac_service3_capacity"
        case service3_serviceSwitchRating       = "sac_service3_serviceSwitchRating"
        case service3_distributionPanelRating   = "sac_service3_distributionPanelRating"
        case service3_switchRating              = "sac_service3_switchRating"
        case service3_circuitBreakerRating      = "sac_service3_circuitBreakerRating"
        
        case service4_capacity                  = "sac_service4_capacity"
        case service4_serviceSwitchRating       = "sac_service4_serviceSwitchRating"
        case service4_distributionPanelRating   = "sac_service4_distributionPanelRating"
        case service4_switchRating              = "sac_service4_switchRating"
        case service4_circuitBreakerRating      = "sac_service4_circuitBreakerRating"
        
        case service5_capacity                  = "sac_service5_capacity"
        case service5_serviceSwitchRating       = "sac_service5_serviceSwitchRating"
        case service5_distributionPanelRating   = "sac_service5_distributionPanelRating"
        case service5_switchRating              = "sac_service5_switchRating"
        case service5_circuitBreakerRating      = "sac_service5_circuitBreakerRating"

        case transformerDetail                  = "sac_transformerDetail"
        case multiMeter                         = "sac_multiMeter"
        case numberOfElectricalMeters           = "sac_numberOfElectricalMeters"
        case electricalMeter1                   = "sac_electricalMeter1"
        case electricalMeter2                   = "sac_electricalMeter2"
        case electricalMeter3                   = "sac_electricalMeter3"
        case electricalMeter4                   = "sac_electricalMeter4"
        case electricalMeter5                   = "sac_electricalMeter5"
        case subPanelBoard                      = "sac_subPanelBoard"
        case subPanelBreakerRating              = "sac_subPanelBreakerRating"

        case photos_transformer                 = "sac_photos_transformer"
        case photos_electricalRoom              = "sac_photos_electricalRoom"
        case photos_electricalMeter             = "sac_photos_electricalMeter"
        case photos_distributionPanel           = "sac_photos_distributionPanel"

    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // SYSTEM
        self.projectAddress                     = try values.decode(String.self, forKey: .projectAddress)
        self.projectID                          = try values.decode(String.self, forKey: .projectID)
        self.status                             = try values.decode(String.self, forKey: .status)
        self.scheduleDate                       = try values.decode(String.self, forKey: .scheduleDate)
        self.assignedDate                       = try values.decode(String.self, forKey: .assignedDate)
        self.assignedTeam                       = try values.decode(String.self, forKey: .assignedTeam)

        // LAYOUT
        self.copyOfStructuralLayout             = try values.decode(String.self, forKey: .copyOfStructuralLayout)
        self.copyOfFloorPlan                    = try values.decode(String.self, forKey: .copyOfFloorPlan)
        self.copyOfElectricalDrawing            = try values.decode(String.self, forKey: .copyOfElectricalDrawing)

        // STRUCTURAL
        self.structuralType                     = try values.decode(String.self, forKey: .structuralType)
        self.areaOfPropertySite                 = try values.decode(String.self, forKey: .areaOfPropertySite)
        self.buildingHeight                     = try values.decode(String.self, forKey: .buildingHeight)
        self.mainBeamSpacing                    = try values.decode(String.self, forKey: .mainBeamSpacing)
        self.openWebSteelJoistSpacing_OWSJ      = try values.decode(String.self, forKey: .openWebSteelJoistSpacing_OWSJ)
        self.openWebSteelJoistSpacing_D         = try values.decode(String.self, forKey: .openWebSteelJoistSpacing_D)
        self.heightofwebsteelJoist              = try values.decode(String.self, forKey: .heightofwebsteelJoist)
        self.endThreeWebMemberType              = try values.decode(String.self, forKey: .endThreeWebMemberType)
        self.endThreeWebMemberTypeNotes         = try values.decode(String.self, forKey: .endThreeWebMemberTypeNotes)
        self.sizeOfEndThreeWebMember            = try values.decode(String.self, forKey: .sizeOfEndThreeWebMember)
        self.sizeOfBottomChord                  = try values.decode(String.self, forKey: .sizeOfBottomChord)
        self.photos_mainBeam                    = try values.decode(String.self, forKey: .photos_mainBeam)
        self.photos_openWebSteelJoist           = try values.decode(String.self, forKey: .photos_openWebSteelJoist)
        self.photos_bottomChord                 = try values.decode(String.self, forKey: .photos_bottomChord)
        self.photos_webMember                   = try values.decode(String.self, forKey: .photos_webMember)

        // ELECTRICAL
        self.electricalMeterRoomDimension       = try values.decode(String.self, forKey: .electricalMeterRoomDimension)
        self.service                            = try values.decode(String.self, forKey: .service)
        self.numberOfService                    = try values.decode(String.self, forKey: .numberOfService)
        self.service1_capacity                  = try values.decode(String.self, forKey: .service1_capacity)
        self.service1_serviceSwitchRating       = try values.decode(String.self, forKey: .service1_serviceSwitchRating)
        self.service1_distributionPanelRating   = try values.decode(String.self, forKey: .service1_distributionPanelRating)
        self.service1_switchRating              = try values.decode(String.self, forKey: .service1_switchRating)
        self.service1_circuitBreakerRating      = try values.decode(String.self, forKey: .service1_circuitBreakerRating)
        self.service2_capacity                  = try values.decode(String.self, forKey: .service2_capacity)
        self.service2_serviceSwitchRating       = try values.decode(String.self, forKey: .service2_serviceSwitchRating)
        self.service2_distributionPanelRating   = try values.decode(String.self, forKey: .service2_distributionPanelRating)
        self.service2_switchRating              = try values.decode(String.self, forKey: .service2_switchRating)
        self.service2_circuitBreakerRating      = try values.decode(String.self, forKey: .service2_circuitBreakerRating)
        self.service3_capacity                  = try values.decode(String.self, forKey: .service3_capacity)
        self.service3_serviceSwitchRating       = try values.decode(String.self, forKey: .service3_serviceSwitchRating)
        self.service3_distributionPanelRating   = try values.decode(String.self, forKey: .service3_distributionPanelRating)
        self.service3_switchRating              = try values.decode(String.self, forKey: .service3_switchRating)
        self.service3_circuitBreakerRating      = try values.decode(String.self, forKey: .service3_circuitBreakerRating)
        self.service4_capacity                  = try values.decode(String.self, forKey: .service4_capacity)
        self.service4_serviceSwitchRating       = try values.decode(String.self, forKey: .service4_serviceSwitchRating)
        self.service4_distributionPanelRating   = try values.decode(String.self, forKey: .service4_distributionPanelRating)
        self.service4_switchRating              = try values.decode(String.self, forKey: .service4_switchRating)
        self.service4_circuitBreakerRating      = try values.decode(String.self, forKey: .service4_circuitBreakerRating)
        self.service5_capacity                  = try values.decode(String.self, forKey: .service5_capacity)
        self.service5_serviceSwitchRating       = try values.decode(String.self, forKey: .service5_serviceSwitchRating)
        self.service5_distributionPanelRating   = try values.decode(String.self, forKey: .service5_distributionPanelRating)
        self.service5_switchRating              = try values.decode(String.self, forKey: .service5_switchRating)
        self.service5_circuitBreakerRating      = try values.decode(String.self, forKey: .service5_circuitBreakerRating)
        self.transformerDetail                  = try values.decode(String.self, forKey: .transformerDetail)
        self.multiMeter                         = try values.decode(String.self, forKey: .multiMeter)
        self.numberOfElectricalMeters           = try values.decode(String.self, forKey: .numberOfElectricalMeters)
        self.electricalMeter1                   = try values.decode(String.self, forKey: .electricalMeter1)
        self.electricalMeter2                   = try values.decode(String.self, forKey: .electricalMeter2)
        self.electricalMeter3                   = try values.decode(String.self, forKey: .electricalMeter3)
        self.electricalMeter4                   = try values.decode(String.self, forKey: .electricalMeter4)
        self.electricalMeter5                   = try values.decode(String.self, forKey: .electricalMeter5)
        self.subPanelBoard                      = try values.decode(String.self, forKey: .subPanelBoard)
        self.subPanelBreakerRating              = try values.decode(String.self, forKey: .subPanelBreakerRating)
        
        self.photos_transformer                 = try values.decode(String.self, forKey: .photos_transformer)
        self.photos_electricalRoom              = try values.decode(String.self, forKey: .photos_electricalRoom)
        self.photos_electricalMeter             = try values.decode(String.self, forKey: .photos_electricalMeter)
        self.photos_distributionPanel           = try values.decode(String.self, forKey: .photos_distributionPanel)
    }
    
    init() {
        self.projectAddress = ""
        self.projectID      = ""
        self.status         = ""
    }
}

enum UploadStatus: String, Codable {
    case pending     = "Pending"
    case uploading   = "Uploading"
    case completed   = "Completed"
}

struct SiteAssessmentProjectInformationStructure: Codable {
    var projectAddress  : String!
    var projectID       : String!
    var status          : UploadStatus!
    
    var scheduleDate    : Date?
    var assignedTeam    : String!
    var assignedDate    : Date!
    var uploadedDate    : Date?
    
    private enum CodingKeys: String, CodingKey {
        case projectAddress = "sac_projectAddress"
        case projectID      = "sac_projectID"
        case status         = "sac_status"
        
        case scheduleDate   = "sac_sheduleDate"
        case assignedTeam   = "sac_assignedTeam"
        case assignedDate   = "sac_assignedDate"
        case uploadedDate   = "sac_uploadedDate"
    }

    init() {
        self.projectAddress = ""
        self.projectID      = ""
        self.status         = .pending

        self.scheduleDate   = nil
        self.assignedTeam   = ""
        self.assignedDate   = nil
        self.uploadedDate   = nil
    }
    
    init(from decoder: Decoder) throws {
        let values      = try decoder.container(keyedBy: CodingKeys.self)
        projectAddress  = try values.decode(String.self, forKey: .projectAddress)
        projectID       = try values.decode(String.self, forKey: .projectID)
        status          = try values.decode(UploadStatus.self, forKey: .status)
        scheduleDate    = try values.decode(Date.self, forKey: .scheduleDate)
        assignedTeam    = try values.decode(String.self, forKey: .assignedTeam)
        assignedDate    = try values.decode(Date.self, forKey: .assignedDate)
        uploadedDate    = try values.decode(Date.self, forKey: .uploadedDate)
    }
    
    init(withZohoData data: [String: String?]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        self.projectAddress = data["sac_projectAddress"]!
        self.projectID      = data["sac_projectID"]!
        self.status         = .pending
        
        let scheduleDate = Date() // formatter.date(from: data["sac_sheduleDate"]! ?? "2019-10-13 12:18:12")
        let assignedDate = Date() // formatter.date(from: data["sac_assignedDate"]! ?? "")
        let uploadedDate = Date() // formatter.date(from: data["sac_uploadedDate"]! ?? "")

        self.scheduleDate   = scheduleDate
        self.assignedTeam   = data["sac_assignedTeam"]!
        self.assignedDate   = assignedDate
        self.uploadedDate   = uploadedDate
    }
    
    func toDictionary() -> [String: String?] {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let scheduleDate = formatter.string(from: self.scheduleDate ?? Date())
        let assignedDate = formatter.string(from: self.assignedDate ?? Date())
        let uploadedDate = formatter.string(from: self.uploadedDate ?? Date())

        return [
            "Project Address": self.projectAddress,
            "Project ID": self.projectID,
            "Status": self.status.rawValue,
            "Schedule Date": scheduleDate,
            "Assigned Team": self.assignedTeam,
            "Assigned Date": assignedDate,
            "Upload Date": uploadedDate
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
        self.name = ""
        self.status = .pending
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

struct SiteAssessmentImageArrayStructure: Codable {
    var key: String
    var images: [ImageAttributes]
    
    private enum CodingKeys: CodingKey {
        case key
        case images
    }
    
    init() {
        self.key = ""
        self.images = []
    }
    
    init(key: String, images: [ImageAttributes]) {
        self.key = key
        self.images = images
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key        = try values.decode(String.self, forKey: .key)
        images     = try values.decode([ImageAttributes].self, forKey: .images)
    }
    
}

struct SiteAssessmentDataStructure: Codable, Equatable {
    
    var prjInformation: SiteAssessmentProjectInformationStructure
    var prjQuestionnaire: [QuestionaireConfigs_SectionsWrapper]
    var prjImageArray: [SiteAssessmentImageArrayStructure]
    
    private enum CodingKeys: String, CodingKey {
        case prjInformation = "detail"
        case prjQuestionnaire = "questionnaire"
        case prjImageArray = "imageArray"
    }
    
    init() {
        self.prjInformation = SiteAssessmentProjectInformationStructure()
        self.prjQuestionnaire = []
        self.prjImageArray = []
    }
    
    init(withProjectInformation info: SiteAssessmentProjectInformationStructure, withProjectQuestionnaire questionnaire: [QuestionaireConfigs_SectionsWrapper], withProjectImageArray array: [SiteAssessmentImageArrayStructure]) {
        self.prjInformation = info
        self.prjQuestionnaire = questionnaire
        self.prjImageArray = array
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        prjInformation      = try values.decode(SiteAssessmentProjectInformationStructure.self, forKey: .prjInformation)
        prjQuestionnaire    = try values.decode([QuestionaireConfigs_SectionsWrapper].self, forKey: .prjQuestionnaire)
        prjImageArray       = try values.decode([SiteAssessmentImageArrayStructure].self, forKey: .prjImageArray)
    }
    
    init(withZohoData data: [String: String]) {
        self.prjInformation = SiteAssessmentProjectInformationStructure(withZohoData: data)
        self.prjImageArray = []
        
        if let path = Bundle.main.url(forResource: "QuestionnaireConfigs", withExtension: "plist"),
            let plistData = try? Data(contentsOf: path),
            let allData = try? PropertyListDecoder().decode([QuestionaireConfigs_SectionsWrapper].self, from: plistData) {
            self.prjQuestionnaire = allData
            
            allData.enumerated().forEach { (sectionNum, section) in
                section.Questions.enumerated().forEach({ (questionIndex, question) in
                    if let theData = data.first(where: { (key, value) -> Bool in
                        key == question.Key
                    }) {
                        self.prjQuestionnaire[sectionNum].Questions[questionIndex].Value = theData.value
                    }
                })
            }
        } else {
            self.prjQuestionnaire = []
        }
    }
    
    static func == (lhs: SiteAssessmentDataStructure, rhs: SiteAssessmentDataStructure) -> Bool {
        return lhs.prjInformation.projectAddress == rhs.prjInformation.projectAddress && lhs.prjInformation.projectID == rhs.prjInformation.projectID
    }
}

struct QuestionaireConfigs_QuestionsWrapper: IdentifiableType, Codable, Equatable, Hashable {
    var identity: Int?
    
    var Name: String
    var Key: String
    var QType: NewProjectReportCellType
    var Options: [String?]
    var Default: String?
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
        case Mandatory
        case Value
        case Interdependence
        case Dependent
    }
    
    static func == (lhs: QuestionaireConfigs_QuestionsWrapper, rhs: QuestionaireConfigs_QuestionsWrapper) -> Bool {
        return lhs.Name == rhs.Name && lhs.Key == rhs.Key
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
        Interdependence = try values.decode(String.self, forKey: .Interdependence)
        Dependent  = try values.decode([String: String].self, forKey: .Dependent)
        Value       = try values.decode(String.self, forKey: .Value)
        identity    = 0
    }
    
    init(question: QuestionaireConfigs_QuestionsWrapper) {
        self.Name        = question.Name
        self.Key         = question.Key
        self.QType       = question.QType
        self.Options     = question.Options
        self.Default     = question.Default
        self.Mandatory   = question.Mandatory
        self.Interdependence = question.Interdependence
        self.Dependent  = question.Dependent
        self.Value       = question.Value
        self.identity    = question.identity
    }
    
}

struct QuestionaireConfigs_SectionsWrapper: Codable {
    var Name: String
    var Questions: [QuestionaireConfigs_QuestionsWrapper]
    
    init() {
        self.Name = ""
        self.Questions = []
    }
    
    private enum CodingKeys: String, CodingKey {
        case Name
        case Questions
    }
    
    init(name: String, questions: [QuestionaireConfigs_QuestionsWrapper]) {
        self.Name = name
        self.Questions = questions
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        Name       = try values.decode(String.self, forKey: .Name)
        Questions  = try values.decode([QuestionaireConfigs_QuestionsWrapper].self, forKey: .Questions)
    }
}

struct QuestionnaireConfigsWrapper: Codable {
    var QuestionaireConfigs: [QuestionaireConfigs_SectionsWrapper]
}

// https://stackoverflow.com/questions/25127700/two-dimensional-array-in-swift
struct Matrix<T> {
    let rows: Int, columns: Int
    var grid: [T]
    init(rows: Int, columns: Int,defaultValue: T) {
        self.rows = rows
        self.columns = columns
        grid = Array(repeating: defaultValue, count: rows * columns) 
    }
    func indexIsValid(row: Int, column: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns
    }
    subscript(row: Int, column: Int) -> T {
        get {
            assert(indexIsValid(row: row, column: column), "Index out of range")
            return grid[(row * columns) + column]
        }
        set {
            assert(indexIsValid(row: row, column: column), "Index out of range")
            grid[(row * columns) + column] = newValue
        }
    }
}
