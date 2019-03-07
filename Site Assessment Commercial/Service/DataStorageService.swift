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
import NotificationBannerSwift


protocol CustomErrorProtocol: LocalizedError {
    
    var title: String? { get }
    var code: Int { get }
}

struct CustomError: CustomErrorProtocol {
    
    var title: String?
    var code: Int
    var errorDescription: String? { return _description }
    var failureReason: String? { return _description }
    
    private var _description: String
    
    init(title: String? = "Error", description: String, code: Int) {
        self.title = title
        self._description = description
        self.code = code
    }
}

class DataStorageService {
    public static var sharedDataStorageService: DataStorageService!
    
    public static func instantiateSharedInstance() {
        sharedDataStorageService = DataStorageService()
    }
    
    private var answerDictionary: [String: String] = [:]
    
    private var prjData = SiteAssessmentDataStructure()

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
    
    public func storeImages(prjID: String, name: String, images: [UIImage], onCompleted: (([ImageAttributes]?, Error?) -> ())?) {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("[storeData - FileManager.default.urls] failed.")
            
            let error = CustomError(description: "File not found.", code: -1)
            onCompleted?(nil, error)
            return
        }
        
        let prjFolder = documentsURL.appendingPathComponent(prjID)
        
        if !FileManager.default.fileExists(atPath: String(describing: prjFolder)) {
            do {
                try FileManager.default.createDirectory(at: prjFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("[storeImages - FileManager.default.createDirectory] failed. Error=\(error)")
                return
            }
        }
        
        let imgAttrs = images.enumerated().map { (index, image) -> ImageAttributes in
            var fileName = name
            fileName.append("_\(index)")
            let fileURL = prjFolder.appendingPathComponent(fileName).appendingPathExtension("png")
            do {
                try image.pngData()?.write(to: fileURL)
            } catch {
                print("[storeImages - img.pngData()?.write] failed. Error=\(error)")
                return ImageAttributes()
            }
            
            SaveToCustomAlbum.shared.save(image: image)
            
            return ImageAttributes(name: fileName, path: fileURL.path)
        }
    
        onCompleted?(imgAttrs, nil)
    }
    
    public func storeData(withData saData: SiteAssessmentDataStructure, onCompleted: ((Bool, Error?) -> ())?) {
        
        guard let prjId = saData.prjInformation["Project ID"] else {
            let error = CustomError(description: "[storeData - saData.prjInformation[Project ID]] failed.", code: -1)
            onCompleted?(false, error)
            return
        }
        
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            let err = CustomError(description: "[storeData - FileManager.default.urls] failed.", code: -1)
            onCompleted?(false, err)
            return
        }
        
        let fileURL = documentsURL.appendingPathComponent(prjId).appendingPathExtension("json")
        do {
            let jsonData = try JSONEncoder().encode(saData)
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: jsonData, requiringSecureCoding: false)
                do {
                    try data.write(to: fileURL)
                    onCompleted?(true, nil)

                } catch {
                    onCompleted?(false, error)
                    return
                }
            } catch {
                onCompleted?(false, error)
                return
            }
        } catch {
            onCompleted?(false, error)
            return
        }
    }
    
    public func retrieveCurrentProjectData() -> SiteAssessmentDataStructure {
        return self.prjData
    }
    
    public func storeCurrentProjectData(data: SiteAssessmentDataStructure) {
        self.prjData = data
    }
    
    public func retrieveProjectList() -> [SiteAssessmentDataStructure] {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("[retrieveData - FileManager.default.urls] failed.")
            return []
        }
        
        do {
            return try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil).filter{ $0.pathExtension == "json" }.map { (fileURL) -> SiteAssessmentDataStructure in
                do {
                    let data = try Data(contentsOf: fileURL)
                    do {

                        let unarchivedData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! Data
                        
                        do {
                            let decodedData = try JSONDecoder().decode(SiteAssessmentDataStructure.self, from: unarchivedData)
                            return decodedData
                        } catch {
                            print("[retrieveData - JSONDecoder().decode] failed, error = \(error).")
                            return SiteAssessmentDataStructure.init()
                        }
                    } catch {
                        print("[retrieveData - NSKeyedUnarchiver.unarchiveTopLevelObjectWithData] failed, error = \(error).")
                        return SiteAssessmentDataStructure.init()
                    }
                } catch {
                    print("[retrieveData - Data(contentsOf: fileUrl)] failed, error = \(error).")
                    return SiteAssessmentDataStructure.init()
                }
            }
        } catch {
            print("[retrieveData - FileManager.default.contentsOfDirectory] failed, error = \(error).")
        }
        
        return []
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
    
    public func loadProjectList() -> [SiteAssessmentDataStructure] {
        
        let info = [
            "Project Address"   : "12345678",
            "Project ID"        : "12345678",
            "Schedule Date"     : "2019-09-23",
            "Status"            : "Pending"
        ]
        
        let questionnaire: [QuestionaireConfigs_SectionsWrapper] = []
        let array: [SiteAssessmentImageArrayStructure] = []
        
        let data = SiteAssessmentDataStructure(withProjectInformation: info, withProjectQuestionnaire: questionnaire, withProjectImageArray: array)
        
        let info2 = [
            "Project Address"   : "37877213",
            "Project ID"        : "37877213",
            "Schedule Date"     : "2019-09-23",
            "Status"            : "Pending"
        ]
        
        let data2 = SiteAssessmentDataStructure(withProjectInformation: info2, withProjectQuestionnaire: questionnaire, withProjectImageArray: array)

        return [data, data2]
    }
}
