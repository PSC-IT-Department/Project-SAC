//
//  dataStorageService.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-29.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class DataStorageService {
    public static var sharedDataStorageService: DataStorageService!
    
    public static func instantiateSharedInstance() {
        sharedDataStorageService = DataStorageService()
    }
    
    private init() {
    }
    
    deinit {
    }
    
    public func storeData() {
        // Store all data
    }
    
    public func retrieveData()->[SADTO] {
        // Retrieve all data
        return SADTO.testData
    }
    
    public func retrieveQuestionnaire(){
        if let path = Bundle.main.path(forResource: "QuestionnaireConfigs", ofType: "plist") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let decoder = PropertyListDecoder()
                
                let qlist = try decoder.decode(SADTO.self, from: data)
                print(qlist)
            } catch {
                print(error)
            }
        }
    }
    
}
