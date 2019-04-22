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
    case jsonEncodeFailed = "Json encode failed."
    case createFolderFailed = "Create folder failed."
}

class DataStorageService {
    public static var shared: DataStorageService!
    
    public static func instantiateSharedInstance() {
        shared = DataStorageService()
    }
    
    public var homeDirectory: URL!
    public var currentProjectHomeDirectory: URL!
    public var currentProjectID: String!
    
    public var projectList: [SiteAssessmentDataStructure]?
        
    private var prjData: SiteAssessmentDataStructure! {
        didSet {
            currentProjectHomeDirectory = homeDirectory.appendingPathComponent(prjData.prjInformation.projectID)
            currentProjectID = prjData.prjInformation.projectID
        }
    }

    private init() {
        getHomeDirectory()
        
        loadLocalProject()
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
    
    public func updateProject(prjData: SiteAssessmentDataStructure) {
        if let index = self.projectList?.firstIndex(where: {$0.prjInformation.projectID == prjData.prjInformation.projectID}) {
            self.projectList?[index] = prjData
        }
    }
    
    public func updateLocalProject(prjList: [SiteAssessmentDataStructure]) {
        
        if let localPrj = self.projectList {
                       
            let newProjects = prjList.filter({newPrj in
                !localPrj.contains(where: {$0.prjInformation.projectID == newPrj.prjInformation.projectID})
            })
            
            self.projectList?.append(contentsOf: newProjects)
        }
    }
    
    private func loadLocalProject() {
        if let contents = try? FileManager.default.contentsOfDirectory(at: homeDirectory, includingPropertiesForKeys: nil).filter { $0.pathExtension == "json" } {
            let prjList = contents.compactMap { (fileURL) -> SiteAssessmentDataStructure? in
                guard let data = try? Data(contentsOf: fileURL),
                    let unarchivedData = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? Data
                    else {
                        print("[loadLocalProject - JSONDecoder().decode failed]")
                        writeToLog("[loadLocalProject - JSONDecoder().decode failed]")
                        return nil
                        
                }
                
                do {
                    let decodedData = try JSONDecoder().decode(SiteAssessmentDataStructure.self, from: unarchivedData)
                    return decodedData
                } catch {
                    print("loadLocalProject - Error = \(error)")
                    writeToLog("loadLocalProject - Error = \(error)")
                }
                
                return nil
            }
            
            self.projectList = prjList
        }
    }
    
    public func storeImages(prjID: String, name: String, images: [UIImage], onCompleted: (([ImageAttributes]?, Error?) -> Void)?) {
        
        if !FileManager.default.fileExists(atPath: currentProjectHomeDirectory.path) {
            let result = Result {try FileManager.default.createDirectory(at: currentProjectHomeDirectory, withIntermediateDirectories: true, attributes: nil)}
            switch result {
            case .success:
                writeToLog("[storeImages - FileManager.default.createDirectory] success.")
            case .failure(let error):
                writeToLog("[storeImages - FileManager.default.createDirectory] failed. Error=\(error)")
                onCompleted?(nil, SiteAssessmentError.createFolderFailed)
                return
            }
        }
        
        let result = Result {try FileManager.default.contentsOfDirectory(at: currentProjectHomeDirectory, includingPropertiesForKeys: nil)}
        switch result {
        case .success(let urls):
            let imageUrls = urls.filter { $0.pathExtension == "png" && ($0.lastPathComponent.contains(name))}
            
            imageUrls.forEach({ url in
                _ = Result {try FileManager.default.removeItem(at: url)}
            })
        case .failure:
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
    
    public func storeData(withData saData: SiteAssessmentDataStructure, onCompleted: ((Bool, Error?) -> Void)?) {
        
        guard let jsonData = try? JSONEncoder().encode(saData),
            let data = try? NSKeyedArchiver.archivedData(withRootObject: jsonData, requiringSecureCoding: false),
            let prjID = saData.prjInformation.projectID,
            let t = saData.prjInformation.type.rawValue.first // C or R
            else {
                print("storeData failed.")
                onCompleted?(false, SiteAssessmentError.jsonEncodeFailed)
                return
        }
                
        let filename = String(t) + prjID
        let file = homeDirectory.appendingPathComponent(filename).appendingPathExtension("json")
        
        let result = Result {try data.write(to: file)}
        switch result {
        case .success:
            print("storeData successfully.")
            onCompleted?(true, nil)
        case .failure(let error):
            print("storeData failed.")
            onCompleted?(false, error)
        }

    }
    
    public func setCurrentProject(projectID: String) {
        currentProjectID = projectID
        currentProjectHomeDirectory = homeDirectory.appendingPathComponent(projectID)
    }
    
    public func retrieveCurrentProjectData() -> SiteAssessmentDataStructure {
        guard let currentProjectID = currentProjectID, let prjData = self.projectList?.first(where: {$0.prjInformation.projectID == currentProjectID}) else {
            return SiteAssessmentDataStructure()
        }
        
        return prjData
    }
    
    public func storeCurrentProjectData(data: SiteAssessmentDataStructure) {
        if let index = self.projectList?.firstIndex(where: {$0.prjInformation.projectID == data.prjInformation.projectID}) {
            self.projectList?[index] = data
        }
    }
    
    public func retrieveProjectList(type: SiteAssessmentType) -> [SiteAssessmentDataStructure]? {
    
        if let prjList = self.projectList?.filter({$0.prjInformation.type == type}) {
            return prjList
        } else {
            return nil
        }
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
        
        if !FileManager.default.fileExists(atPath: file.path) {
            let result = Result { FileManager.default.createFile(atPath: file.path, contents: nil, attributes: nil) }
            switch result {
            case .success:
                writeToLog("[storeImages - FileManager.default.createDirectory] success.")
            case .failure(let error):
                writeToLog("[storeImages - FileManager.default.createDirectory] failed. Error=\(error)")
                return
            }
        }
        
        let formatter = DateFormatter()
        
        formatter.dateFormat = "[yyyy-MM-dd HH:mm:ss]"
        
        let formattedMsg = formatter.string(from: Date()) + " " + msg
        
        DispatchQueue.main.async {
            let result = Result {try FileHandle(forWritingTo: file)}
            switch result {
            case .success(let handle):
                handle.seekToEndOfFile()
                handle.write(formattedMsg.data(using: .utf8)!)
                handle.closeFile()
            case .failure(let error):
                print("Error = \(error.localizedDescription)")
            }
        }
    }
}
