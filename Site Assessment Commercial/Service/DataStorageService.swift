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
            writeToLog("[storeData - FileManager.default.urls] failed.")
            return
        }
        
        homeDirectory = documentsURL
    }
    
    public func storeImages(prjID: String, name: String, images: [UIImage], onCompleted: (([ImageAttributes]?, Error?) -> ())?) {
        
        if !FileManager.default.fileExists(atPath: currentProjectHomeDirectory.path) {
            let result = Result {try FileManager.default.createDirectory(at: currentProjectHomeDirectory, withIntermediateDirectories: true, attributes: nil)}
            switch result {
            case .success(_):
                writeToLog("[storeImages - FileManager.default.createDirectory] success.")
            case .failure(let error):
                writeToLog("[storeImages - FileManager.default.createDirectory] failed. Error=\(error)")
                onCompleted?(nil, SiteAssessmentError.createFolderFailed)
                return
            }
        }
        
        let result = Result {try FileManager.default.contentsOfDirectory(at: currentProjectHomeDirectory, includingPropertiesForKeys: nil).filter{ $0.pathExtension == "png" && ($0.lastPathComponent.contains(name))}}
        switch result {
        case .success(let urls):
            urls.forEach({ url in
                _ = Result {try FileManager.default.removeItem(at: url)}
            })
        case .failure(_):
            writeToLog("No such files.")
        }
        
        let imgAttrs = images.enumerated().compactMap { (index, image) -> ImageAttributes? in
            let fileName = name + "_\(index)"
            let fileURL = currentProjectHomeDirectory.appendingPathComponent(fileName).appendingPathExtension("png")

            let result = Result { try image.pngData()?.write(to: fileURL) }
            switch result {
            case .success:
                //            SaveToCustomAlbum.shared.save(image: image)

                writeToLog("[storeImages - img.pngData()?.write] success.")
                return ImageAttributes(name: fileName)
            case .failure(let error):
                writeToLog("[storeImages - img.pngData()?.write] failed. Error=\(error)")
                return nil
            }

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
        let file = homeDirectory.appendingPathComponent(filename).appendingPathExtension("json")
        
        let result = Result {try data.write(to: file)}
        switch result {
        case .success:
            onCompleted?(true, nil)
        case .failure(let error):
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
                    let unarchivedData = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? Data,
                    let decodedData = try? JSONDecoder().decode(SiteAssessmentDataStructure.self, from: unarchivedData)
                    else {
                        writeToLog("[retrieveProjectList - JSONDecoder().decode failed]")
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
    
    public func getLog() -> Data? {
        let file = homeDirectory.appendingPathComponent("log.txt")
        
        let result = Result {try Data(contentsOf: file)}
        switch result {
        case .success(let data):
            return data
        default:
            return nil
        }
    }

    public func writeToLog(_ msg: String!) {
        let file = homeDirectory.appendingPathComponent("log.txt")
        
        DispatchQueue.main.async {
            let result = Result {try FileHandle(forWritingTo: file)}
            switch result {
            case .success(let handle):
                handle.seekToEndOfFile()
                handle.write(msg.data(using: .utf8)!)
                handle.closeFile()
            case .failure(let error):
                print("Error = \(error.localizedDescription)")
            }
        }
    }
}
