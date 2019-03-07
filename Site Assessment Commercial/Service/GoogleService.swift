//
//  GoogleService.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-02-20.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

import SwifterSwift
import RxReachability

enum GDriveError: Error {
    case NoDataAtPath
}

class GoogleService {
    
    private let rootDir = "Site Assessment"
    private let service: GTLRDriveService
    private var ggFolderIDs: [String: String] = [:]

    public var signIn: GIDSignIn?
    
    public static var sharedGoogleService: GoogleService!
    
    public static func instantiateSharedInstance(service: GTLRDriveService) {
        sharedGoogleService = GoogleService(service)
    }
    
    init() {
        self.service = GTLRDriveService()
        self.signIn = GIDSignIn()
    }

    init(_ service: GTLRDriveService) {
        self.service = service
        self.signIn = GIDSignIn()
    }

    func prepareForGoogleSignin() {
        
    }
    
    func storeGoogleAccountInformation(signIn: GIDSignIn) {
        
        let user = signIn.currentUser
        self.signIn = signIn
        service.authorizer = user!.authentication.fetcherAuthorizer()
        
        UserDefaults.standard.set(signIn.clientID, forKey: "GoogleClientID")
        UserDefaults.standard.set(user!.profile.email, forKey: "GoogleUser")
    }
    
    func retrieveGoogleUserInformation() -> GIDSignIn? {
        return self.signIn
    }
    
    func resetGoogleUserInformation() {
        UserDefaults.standard.removeObject(forKey: "GoogleUser")
        UserDefaults.standard.removeObject(forKey: "GoogleClientID")
    }
    
    func retrieveGoogleClientID() -> String? {
        return UserDefaults.standard.string(forKey: "GoogleClientID")
    }
    
    func retrieveGoogleUserEmail() -> String? {
        return UserDefaults.standard.string(forKey: "GoogleUser")
    }
    
    public func listFilesInFolder(_ folder: String, onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> ()) {
        search(folder) { (folderID, error) in
            guard let ID = folderID else {
                onCompleted(nil, error)
                return
            }
            
            self.listFiles(ID, onCompleted: onCompleted)
        }
    }
    
    private func listFiles(_ folderID: String, onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 100
        query.q = "'\(folderID)' in parents"
        
        service.executeQuery(query) { (ticket, result, error) in
            onCompleted(result as? GTLRDrive_FileList, error)
        }
    }
    
    
    public func uploadProjectFlie(fileName: String, fileFormat: String, MIMEType: String, folderID: String, onCompleted: @escaping (Bool, Error?) -> ()) {

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            let error = CustomError(description: "Cannot find project folder", code: -1)
            onCompleted(false, error)
            return
        }
        
        let fileURL = documentsURL.appendingPathComponent(fileName).appendingPathExtension(fileFormat).path
        self.upload(folderID, path: fileURL, MIMEType: MIMEType, onCompleted: { (fileID, error) in
            guard let fid = fileID else {
                onCompleted(false, error)
                return
            }
            
            print("json fileID = \(fid)")
            onCompleted(true, nil)
            return
        })
    }

    public func uploadImages(fid: String, onCompleted: ((Bool, Error?) -> ())?) {
        createProjectSectionFolders(pfid: fid) { (sectionFolderIDs, error) in
            guard let sfids = sectionFolderIDs else {
                onCompleted?(false, error)
                return
            }
            
            let saData = DataStorageService.sharedDataStorageService.retrieveCurrentProjectData()
            
            var totalAmount = saData.prjImageArray.reduce(0, { (result, imageArray) -> Int in
                result + imageArray.images.count
            })
            
            print("totalAmount = \(totalAmount)")
            
            saData.prjImageArray.forEach({ (imageArray) in
                let sections = saData.prjQuestionnaire.filter{$0.Questions.contains(where: {$0.Name == imageArray.key})}
                
                if let section = sections.first {
                    imageArray.images.forEach({ (imageAttr) in
                        if let fid = sfids[section.Name] {
                            self.upload(fid, path: imageAttr.path, MIMEType: "image/png", onCompleted: { (fileID, error) in
                                if let err = error {
                                    print("Error = \(err)")
                                }
                                
                                if let fid = fileID {
                                    print("Image fid = \(fid)")
                                    
                                    totalAmount -= 1
                                    if totalAmount == 0 {
                                        onCompleted?(true, nil)
                                        return
                                    }
                                }
                            })
                        }
                    })
                    
                }
            })
        }
    }
    
    public func uploadData(fid: String, onCompleted: ((Bool, Error?) -> ())?) {
        createProjectDataFolder(pfid: fid) { (folderID, error) in
            guard let fid = folderID else {
                onCompleted?(false, error)
                return
            }
            
            let saData = DataStorageService.sharedDataStorageService.retrieveCurrentProjectData()
            
            guard let prjId = saData.prjInformation["Project ID"] else {
                let err = CustomError(description: "uploadProject - Project ID not found.", code: -1)
                onCompleted?(false, err)
                return
            }
            
            self.uploadProjectFlie(fileName: prjId, fileFormat: "json", MIMEType: "application/json", folderID: fid, onCompleted: { (success, error) in
                if let err = error {
                    onCompleted?(false, err)
                    return
                }
                
                if success {
                    onCompleted?(true, nil)
                    return
                }
            })
        }
    }
    
    public func uploadProject(withData saData: SiteAssessmentDataStructure, onCompleted: ((Bool, Error?) -> ())?) {
        search(self.rootDir) { (folderID, error) in
            if let err = error {
                print("Error = \(err)")
            }
            
            if let fid = folderID {
                print("fid = \(fid)")
                
                self.createProjectFolder(rfid: fid, onCompleted: { (folderID, error) in
                    
                    if let err = error {
                        print("Error = \(err)")
                        onCompleted?(false, err)
                    }
                    
                    if let pfid = folderID {
                        print("pfid = \(pfid)")
                        
                        self.uploadData(fid: pfid, onCompleted: { (success, error) in
                            if let err = error {
                                print("Error = \(err)")
                            }
                            
                            if success {
                                print("JSON file uploaded successfully.")
                            }
                        })
                        
                        self.uploadImages(fid: pfid, onCompleted: { (success, error) in
                            if let err = error {
                                print("Error = \(err)")
                            }
                            
                            if success {
                                print("Image(s) uploaded successfully.")
                                onCompleted?(true, nil)
                                return
                            }
                        })
                    }
                })
            }
        }
    }
    
    private func createProjectSectionQuestionFolders(sfid: String, onCompleted: (([String: String]?, Error?) -> ())?) {
        let prjdata = DataStorageService.sharedDataStorageService.retrieveCurrentProjectData()
        
        var qfids:[String: String] = [:]
        prjdata.prjQuestionnaire.forEach { (section) in
            let questions = section.Questions.filter{$0.QType == .image}
            
            questions.forEach({ (question) in
                self.createSubfolder(question.Name, sfid, onCompleted: { (questionFolderID, error) in
                    if let err = error {
                        print("Error = \(err)")
                    }
                    
                    guard let qfid = questionFolderID else {
                        print("Error: createSubfolder failed for questions.")
                        onCompleted?(nil, error)
                        return
                    }
                    
                    qfids.updateValue(qfid, forKey: question.Name)
                    
                    self.ggFolderIDs.updateValue(qfid, forKey: question.Name)
                    if qfids.count == prjdata.prjQuestionnaire.count {
                        onCompleted?(qfids, nil)
                    }
                })
            })
        }
    }
    
    private func createProjectSectionFolders(pfid: String, onCompleted: (([String: String]?, Error?) -> ())?) {
        let prjdata = DataStorageService.sharedDataStorageService.retrieveCurrentProjectData()
        
        var sfids:[String: String] = [:]
        prjdata.prjQuestionnaire.forEach({ (section) in
            self.createSubfolder(section.Name, pfid, onCompleted: { (sectionFolderID, error) in
                if let err = error {
                    print("Error = \(err)")
                }
                
                guard let sfid = sectionFolderID else {
                    print("Error: createSubfolder failed for sections.")
                    onCompleted?(nil, error)
                    return
                }
                
                sfids.updateValue(sfid, forKey: section.Name)
                self.ggFolderIDs.updateValue(sfid, forKey: section.Name)

                if sfids.count == prjdata.prjQuestionnaire.count {
                    onCompleted?(sfids, nil)
                }
            })
        })
    }
    
    private func createProjectDataFolder(pfid: String, onCompleted: ((String?, Error?) -> ())?) {
        
        let sectionData = "DATA"
        self.createSubfolder(sectionData, pfid, onCompleted: { (dataFolderID, error) in
            if let err = error {
                print("Error = \(err)")
            }
            
            guard let dfid = dataFolderID else {
                print("Error: createSubfolder failed for \(sectionData).")
                onCompleted?(nil, error)
                return
            }
            
            self.ggFolderIDs.updateValue(dfid, forKey: sectionData)
            onCompleted?(dfid, nil)
        })
        
    }
    
    private func createProjectFolder(rfid: String, onCompleted: ((String?, Error?) -> ())?) {
        let prjdata = DataStorageService.sharedDataStorageService.retrieveCurrentProjectData()
        
        guard let prjAddr = prjdata.prjInformation["Project Address"] else {
            let err = CustomError(description: "Project Address not found.", code: -1)
            onCompleted?(nil, err)
            return
        }
        
        self.createSubfolder(prjAddr, rfid, onCompleted: { (folderID, error) in
            if let err = error {
                print("Error: \(err.localizedDescription)")
                return
            }
            
            guard let fid = folderID else {
                onCompleted?(nil, error)
                return
            }
            
            self.ggFolderIDs.updateValue(fid, forKey: "Project Address")
            onCompleted?(fid, nil)
            return
        })
    }
    
    private func createFolders(rootFolderID: String, onCompleted: (([String: String]?, Error?) -> ())?) {
        self.createProjectFolder(rfid: rootFolderID, onCompleted: { (prjFolderID, error) in
            if let err = error {
                print("Error = \(err)")
                
            }
            
            guard let pfid = prjFolderID else {
                onCompleted?(nil, error)
                return
            }
            
            var fids:[String: String] = [:]
            
            self.createProjectSectionFolders(pfid: pfid, onCompleted: { (SectionFolderIDs, error) in
                if let err = error {
                    print("Error = \(err)")
                    
                }
                
                guard let sfids = SectionFolderIDs else {
                    onCompleted?(nil, error)
                    return
                }
                
                fids = sfids
                
            })
            
            self.createProjectDataFolder(pfid: pfid, onCompleted: { (DataFolderID, error ) in
                if let err = error {
                    print("Error = \(err)")
                    
                }
                
                guard let dfid = DataFolderID else {
                    onCompleted?(nil, error)
                    return
                }
                
                fids.updateValue(dfid, forKey: "DATA")
                
            })
            
            onCompleted?(fids, nil)
            return
        })
        

    }

    public func uploadFile(_ name: String, path: String, MIMEType: String, onCompleted: ((String?, Error?) -> ())?) {
        
        search(name) { (folderID, error) in
            
            if let ID = folderID {
                self.upload(ID, path: path, MIMEType: MIMEType, onCompleted: onCompleted)
            } else {
                self.createFolder(name, onCompleted: { (folderID, error) in
                    guard let ID = folderID else {
                        onCompleted?(nil, error)
                        return
                    }
                    self.upload(ID, path: path, MIMEType: MIMEType, onCompleted: onCompleted)
                })
            }
        }
    }
    
    private func upload(_ parentID: String, path: String, MIMEType: String, onCompleted: ((String?, Error?) -> ())?) {
        
        guard let data = FileManager.default.contents(atPath: path) else {
            onCompleted?(nil, GDriveError.NoDataAtPath)
            return
        }
        
        let file = GTLRDrive_File()
        file.name = path.components(separatedBy: "/").last
        file.parents = [parentID]
        
        let uploadParams = GTLRUploadParameters.init(data: data, mimeType: MIMEType)
        uploadParams.shouldUploadWithSingleRequest = true
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParams)
        query.fields = "id"
        
        self.service.executeQuery(query, completionHandler: { (ticket, file, error) in
            onCompleted?((file as? GTLRDrive_File)?.identifier, error)
        })
    }
    
    public func download(_ fileID: String, onCompleted: @escaping (Data?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileID)
        service.executeQuery(query) { (ticket, file, error) in
            onCompleted((file as? GTLRDataObject)?.data, error)
        }
    }
    
    public func search(_ fileName: String, onCompleted: @escaping (String?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        //sharedWithMe and title contains 'Site Assessment'
        query.q = "name contains '\(fileName)'"
        
        service.executeQuery(query) { (ticket, results, error) in
            onCompleted((results as? GTLRDrive_FileList)?.files?.first?.identifier, error)
        }
    }

    public func createFolder(_ name: String, onCompleted: @escaping (String?, Error?) -> ()) {
        let file = GTLRDrive_File()
        file.name = name
        file.mimeType = "application/vnd.google-apps.folder"
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: nil)
        query.fields = "id"
        
        service.executeQuery(query) { (ticket, folder, error) in
            onCompleted((folder as? GTLRDrive_File)?.identifier, error)
        }
    }
    
    public func createSubfolder(_ name: String, _ parentID: String, onCompleted: @escaping (String?, Error?) -> ()) {
        let file = GTLRDrive_File()
        file.name = name
        file.mimeType = "application/vnd.google-apps.folder"
        file.parents = [parentID]
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: nil)
        query.fields = "id"
        
        service.executeQuery(query) { (ticket, folder, error) in
            onCompleted((folder as? GTLRDrive_File)?.identifier, error)
        }
    }
    
    public func delete(_ fileID: String, onCompleted: ((Error?) -> ())?) {
        let query = GTLRDriveQuery_FilesDelete.query(withFileId: fileID)
        service.executeQuery(query) { (ticket, nilFile, error) in
            onCompleted?(error)
        }
    }
}
