//
//  SADTO.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-29.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

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
