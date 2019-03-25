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

enum SiteAssessmentError: String, LocalizedError {
    case jsonEncodeFailed = "jsonEncodeFailed"
    case createFolderFailed = "createFolderFailed"
}

class DataStorageService {
    public static var sharedDataStorageService: DataStorageService!
    
    public static func instantiateSharedInstance() {
        sharedDataStorageService = DataStorageService()
    }
    
    public var homeDirectory: URL!
    public var currentProjectHomeDirectory: URL!
    public var currentProjectID: String!
        
    private var prjData: SiteAssessmentDataStructure! {
        didSet {
            currentProjectHomeDirectory = homeDirectory.appendingPathComponent(prjData.prjInformation.projectID)
            currentProjectID = prjData.prjInformation.projectID
        }
    }

    private init() {
        getHomeDirectory()
    }
    
    deinit {
    }
    
    private func getHomeDirectory() {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("[storeData - FileManager.default.urls] failed.")
            return
        }
        
        homeDirectory = documentsURL
    }
    
    public func storeImages(prjID: String, name: String, images: [UIImage], onCompleted: (([ImageAttributes]?, Error?) -> ())?) {        
        if !FileManager.default.fileExists(atPath: currentProjectHomeDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: currentProjectHomeDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("[storeImages - FileManager.default.createDirectory] failed. Error=\(error)")
                onCompleted?(nil, SiteAssessmentError.createFolderFailed)
                return
            }
        }
        
        let imgAttrs = images.enumerated().compactMap { (index, image) -> ImageAttributes in
            let fileName = name + "_\(index)"
            let fileURL = currentProjectHomeDirectory.appendingPathComponent(fileName).appendingPathExtension("png")

            do {
                try image.pngData()?.write(to: fileURL)
            } catch {
                print("[storeImages - img.pngData()?.write] failed. Error=\(error)")
                return ImageAttributes()
            }
//            SaveToCustomAlbum.shared.save(image: image)
            
            return ImageAttributes(name: fileName)
        }
    
        onCompleted?(imgAttrs, nil)
    }
    
    public func storeData(withData saData: SiteAssessmentDataStructure, onCompleted: ((Bool, Error?) -> ())?) {
        
        guard let jsonData = try? JSONEncoder().encode(saData),
            let data = try? NSKeyedArchiver.archivedData(withRootObject: jsonData, requiringSecureCoding: false),
            let prjID = saData.prjInformation.projectID,
            let t = saData.prjInformation.type.rawValue.first // C or R
            else {
                onCompleted?(false, SiteAssessmentError.jsonEncodeFailed)
                return
        }
        let filename = String(t) + prjID
        let fileURL = homeDirectory.appendingPathComponent(filename).appendingPathExtension("json")
        
        do {
            try data.write(to: fileURL)
            onCompleted?(true, nil)
        } catch {
            onCompleted?(false, error)
        }
    }
    
    public func retrieveCurrentProjectData() -> SiteAssessmentDataStructure {
        return self.prjData
    }
    
    public func storeCurrentProjectData(data: SiteAssessmentDataStructure) {
        self.prjData = data
    }
    
    public func retrieveProjectList(type: String) -> [SiteAssessmentDataStructure]? {        
        if let t = type.first, let contents = try? FileManager.default.contentsOfDirectory(at: homeDirectory, includingPropertiesForKeys: nil).filter{ $0.pathExtension == "json" && ($0.lastPathComponent.contains(t))} {
            let prjList = contents.compactMap { (fileURL) -> SiteAssessmentDataStructure? in
                guard let data = try? Data(contentsOf: fileURL),
                    let unarchivedData = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! Data,
                    let decodedData = try? JSONDecoder().decode(SiteAssessmentDataStructure.self, from: unarchivedData)
                    else {
                        print("[retrieveProjectList - JSONDecoder().decode failed]")
                        return nil
                }
                
                return decodedData
            }
            
            return prjList
        }
        
        return nil
    }

    public func storeGroupingOption(option: GroupingOptions) {
        UserDefaults.standard.set(option.rawValue, forKey: "GroupingOption")
    }
    
    public func retrieveGroupingOption() -> GroupingOptions {
        
        if let value = UserDefaults.standard.value(forKey: "GroupingOption") as? String,
            let option = GroupingOptions(rawValue: value) {
            return option
        } else {
            let option = GroupingOptions.status
            storeGroupingOption(option: option)
            return option
        }
    }
    
    public func storeDefaultType(option: SiteAssessmentType) {
        UserDefaults.standard.set(option.rawValue, forKey: "SiteAssessmentType")
    }
    
    public func retrieveTypeOption() -> SiteAssessmentType {
        if let value = UserDefaults.standard.value(forKey: "SiteAssessmentType") as? String,
            let option = SiteAssessmentType(rawValue: value) {
            return option
        } else {
            let option = SiteAssessmentType.SiteAssessmentResidential
            storeDefaultType(option: option)
            return option
        }
    }
    
    public func storeMapTypeOption(option: MapTypeOptions) {
        UserDefaults.standard.set(option.rawValue, forKey: "MapTypeOptions")
    }
    
    public func retrieveMapTypeOption() -> MapTypeOptions {
        if let value = UserDefaults.standard.value(forKey: "MapTypeOptions") as? UInt,
            let option = MapTypeOptions(rawValue: value) {
            return option
        } else {
            let option = MapTypeOptions.standard
            storeMapTypeOption(option: option)
            return option
        }
    }

}
