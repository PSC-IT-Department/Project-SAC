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
    
    private var answerDictionary: [String: String] = [:]

    private init() {
    }
    
    deinit {
    }
    
    public func initAnserDictionary() {
        self.answerDictionary = [:]
    }
    
    public func writeToAnswerDictionary(value: String, key: String) {
        self.answerDictionary.updateValue(value, forKey: key)
        print(self.answerDictionary)
    }
    
    public func readFromAnswerDictionary() -> [String: String] {
        return self.answerDictionary
    }
    
    public func storeData() {
        // Store all data
        
        guard let data = SADTO.testData.first else {
            print("Data is empty.")
            return
        }
        
        guard let appPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            print("appPath is nil.")
            return
        }
        
        print("appPath = \(appPath)")
        
        let filePath = appPath.appendingFormat("/\(data.projectId).plist")
        print("filePath = \(filePath)")

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
