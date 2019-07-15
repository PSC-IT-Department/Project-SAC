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

enum GDriveError: String, Error {
    case NoDataAtPath = "NO SUCH DATA AT THE PATH"
}

class GoogleService {
    
    private let rootDir = "Site Assessment"
    private let driveService: GTLRDriveService
    private let calendarService: GTLRCalendarService
    private var ggFolderIDs: [String: String] = [:]

    public var calendarId: String!
    public var signIn: GIDSignIn?
    
    public static var shared: GoogleService!
    
    public static func instantiateSharedInstance() {
        shared = GoogleService()
    }
    
    init() {
        self.signIn = GIDSignIn()
        self.driveService = GTLRDriveService()
        self.calendarService = GTLRCalendarService()
    }
    
    func storeGoogleAccountInformation(signIn: GIDSignIn) {
        
        let user = signIn.currentUser
        self.signIn = signIn
        driveService.authorizer = user!.authentication.fetcherAuthorizer()
        calendarService.authorizer = user!.authentication.fetcherAuthorizer()
        
        UserDefaults.standard.set(user!.profile.email, forKey: "GoogleUser")
    }
    
    func syncWithCalendar() {
        
    }
    
    func retrieveGoogleUserInformation() -> GIDSignIn? {
        return self.signIn
    }
    
    func resetGoogleUserInformation() {
        UserDefaults.standard.removeObject(forKey: "GoogleUser")
    }
    
    func getEmail() -> String? {
        return UserDefaults.standard.string(forKey: "GoogleUser")
    }
    
    public func listFilesInFolder(_ folder: String, onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> Void) {
        search(folder) { (folderID, error) in
            guard let ID = folderID else {
                onCompleted(nil, error)
                return
            }
            
            self.listFiles(ID, onCompleted: onCompleted)
        }
    }
    
    private func listFiles(_ folderID: String, onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> Void) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 100
        query.q = "'\(folderID)' in parents"
        
        driveService.executeQuery(query) { (_, result, error) in
            onCompleted(result as? GTLRDrive_FileList, error)
        }
    }
    
    public func uploadProjectFlie(fileName: String,
                                  fileFormat: String,
                                  MIMEType: String,
                                  folderID: String,
                                  onCompleted: @escaping (Bool, Error?) -> Void) {

        guard let homeDirectory = DataStorageService.shared.homeDirectory else {
            print("homeDirectory is nil")
            onCompleted(false, nil)
            return
        }

        let fileURL = homeDirectory.appendingPathComponent(fileName).appendingPathExtension(fileFormat).path
        self.upload(folderID, path: fileURL, MIMEType: MIMEType, onCompleted: { (fileID, error) in
            guard let fid = fileID else {
                print("fileURL = \(fileURL)")
                onCompleted(false, error)
                return
            }
            
            print("json fileID = \(fid)")
            onCompleted(true, nil)
            return
        })
    }

    public func uploadImages(fid: String, onCompleted: ((Bool, Error?) -> Void)?) {
        createProjectSectionFolders(pfid: fid) { (sectionFolderIDs, error) in
            guard let sfids = sectionFolderIDs else {
                onCompleted?(false, error)
                return
            }
            
            let saData = DataStorageService.shared.retrieveCurrentProjectData()
            
            var totalAmount = saData.prjImageArray.reduce(0, { (result, imageArray) -> Int in
                if let images = imageArray.images {
                    return result + images.count
                } else {
                    return result + 0
                }
            })
            
            saData.prjImageArray.forEach({ (imageArray) in
                let sections = saData.prjQuestionnaire.filter {$0.Questions.contains(where: {
                    $0.Name == imageArray.key})}
                
                if let section = sections.first {
                    imageArray.images?.forEach({ (imageAttr) in
                        guard let prjDir = DataStorageService.shared.projectDir else {
                            onCompleted?(false, nil)
                            return
                        }
                        
                        let imgName = prjDir.appendingPathComponent(imageAttr.name).appendingPathExtension("png")
                        let imgPath = imgName.path
                        
                        if let fid = sfids[section.Name] {
                            self.upload(fid, path: imgPath, MIMEType: "image/png", onCompleted: { (fileID, error) in
                                if let err = error {
                                    print("fileID, Error = \(err)")
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
    
    public func uploadData(fid: String, onCompleted: ((Bool, Error?) -> Void)?) {
        createProjectDataFolder(pfid: fid) { (folderID, error) in
            guard let fid = folderID else {
                onCompleted?(false, error)
                return
            }
            
            let saData = DataStorageService.shared.retrieveCurrentProjectData()
            
            if let prjID = saData.prjInformation.projectID, let prjType = saData.prjInformation.type {
            
                let t = prjType == .SiteAssessmentCommercial ? "S" : "R"
                let fileName = t + prjID
                let format = "json"
                let type = "application/json"
                self.uploadProjectFlie(fileName: fileName,
                                       fileFormat: format,
                                       MIMEType: type,
                                       folderID: fid) { (success, error) in
                    if let err = error {
                        onCompleted?(false, err)
                        return
                    }
                    
                    if success {
                        onCompleted?(true, nil)
                        return
                    }
                }
            }
        }
    }
    
    public func uploadProject(with saData: SiteAssessmentDataStructure, onCompleted: ((Bool, Error?) -> Void)?) {
 
        let imgAttrs = saData.prjImageArray.compactMap({$0.images}).joined().filter({ $0.name != "" })
        
        if imgAttrs.isEmpty {
            print("No Need to upload to Google Drive, success.")
            onCompleted?(true, nil)
            return
        }
        
        search(self.rootDir) { (folderID, error) in
            if let err = error {
                print("folderID, Error = \(err)")
                onCompleted?(false, err)
            }
            
            if let fid = folderID {
                print("fid = \(fid)")
                
                self.createProjectFolder(rfid: fid, onCompleted: { (folderID, error) in
                    
                    if let err = error {
                        print("createProjectFolder, Error = \(err)")
                        onCompleted?(false, err)
                    }
                    
                    if let pfid = folderID {
                        print("pfid = \(pfid)")
                        
                        self.uploadData(fid: pfid, onCompleted: { (success, error) in
                            if let err = error {
                                print("uploadData, Error = \(err)")
                            }
                            
                            if success {
                                print("JSON file uploaded successfully.")
                            }
                        })
                        
                        self.uploadImages(fid: pfid, onCompleted: { (success, error) in
                            if let err = error {
                                print("uploadImages, Error = \(err)")
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
    
    private func createProjectSectionQuestionFolders(sfid: String,
                                                     onCompleted: (([String: String]?, Error?) -> Void)?) {
        let prjdata = DataStorageService.shared.retrieveCurrentProjectData()
        
        var qfids: [String: String] = [:]
        prjdata.prjQuestionnaire.forEach { (section) in
            let questions = section.Questions.filter {$0.QType == .image}
            
            questions.forEach({ (question) in
                self.createSubfolder(question.Name, sfid, onCompleted: { (questionFolderID, error) in
                    if let err = error {
                        print("createSubfolder, Error = \(err)")
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
    
    private func createProjectSectionFolders(pfid: String, onCompleted: (([String: String]?, Error?) -> Void)?) {
        let prjdata = DataStorageService.shared.retrieveCurrentProjectData()
        
        var sfids: [String: String] = [:]
        prjdata.prjQuestionnaire.forEach({ (section) in
            self.createSubfolder(section.Name, pfid, onCompleted: { (sectionFolderID, error) in
                if let err = error {
                    print("createProjectSectionFolders, Error = \(err)")
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
    
    private func createProjectDataFolder(pfid: String, onCompleted: ((String?, Error?) -> Void)?) {
        
        let sectionData = "DATA"
        self.createSubfolder(sectionData, pfid, onCompleted: { (dataFolderID, error) in
            if let err = error {
                print("createProjectDataFolder, Error = \(err)")
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
    
    private func createProjectFolder(rfid: String, onCompleted: ((String?, Error?) -> Void)?) {
        let prjdata = DataStorageService.shared.retrieveCurrentProjectData()
        
        if let prjAddr = prjdata.prjInformation.projectAddress {
            
            self.createSubfolder(prjAddr, rfid, onCompleted: { (folderID, error) in
                if let err = error {
                    print("createProjectFolder, createSubfolder Error: \(err.localizedDescription)")
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
    }
    
    private func createFolders(rootFolderID: String, onCompleted: (([String: String]?, Error?) -> Void)?) {
        self.createProjectFolder(rfid: rootFolderID, onCompleted: { (prjFolderID, error) in
            if let err = error {
                print("Error = \(err)")
                
            }
            
            guard let pfid = prjFolderID else {
                onCompleted?(nil, error)
                return
            }
            
            var fids: [String: String] = [:]
            
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

    public func uploadFile(_ name: String, path: String, MIMEType: String, onCompleted: ((String?, Error?) -> Void)?) {
        
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
    
    private func upload(_ parentID: String, path: String, MIMEType: String, onCompleted: ((String?, Error?) -> Void)?) {
        
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
        
        self.driveService.executeQuery(query, completionHandler: { (_, file, error) in
            onCompleted?((file as? GTLRDrive_File)?.identifier, error)
        })
    }
    
    public func download(_ fileID: String, onCompleted: @escaping (Data?, Error?) -> Void) {
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileID)
        driveService.executeQuery(query) { (_, file, error) in
            onCompleted((file as? GTLRDataObject)?.data, error)
        }
    }
    
    public func search(_ fileName: String, onCompleted: @escaping (String?, Error?) -> Void) {
        let query = GTLRDriveQuery_FilesList.query()
        //sharedWithMe and title contains 'Site Assessment'
        query.q = "name contains '\(fileName)'"
        
        driveService.executeQuery(query) { (_, results, error) in
            onCompleted((results as? GTLRDrive_FileList)?.files?.first?.identifier, error)
        }
    }

    public func createFolder(_ name: String, onCompleted: @escaping (String?, Error?) -> Void) {
        let file = GTLRDrive_File()
        file.name = name
        file.mimeType = "application/vnd.google-apps.folder"
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: nil)
        query.fields = "id"
        
        driveService.executeQuery(query) { (_, folder, error) in
            onCompleted((folder as? GTLRDrive_File)?.identifier, error)
        }
    }
    
    public func createSubfolder(_ name: String, _ parentID: String, onCompleted: @escaping (String?, Error?) -> Void) {
        let file = GTLRDrive_File()
        file.name = name
        file.mimeType = "application/vnd.google-apps.folder"
        file.parents = [parentID]
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: nil)
        query.fields = "id"
        
        driveService.executeQuery(query) { (_, folder, error) in
            onCompleted((folder as? GTLRDrive_File)?.identifier, error)
        }
    }
    
    public func delete(_ fileID: String, onCompleted: ((Error?) -> Void)?) {
        let query = GTLRDriveQuery_FilesDelete.query(withFileId: fileID)
        driveService.executeQuery(query) { (_, _, error) in
            onCompleted?(error)
        }
    }
    
    public func checkDuplicateEventsByEventName(eventName: String) {
        fetchCalendarEventsList { (list, error) in
            if let eventList = list, error == nil {
                eventList.filter({$0.1 == eventName}).forEach({ (event) in
                    if let id = event.0 {
                        self.deleteCalendarEventById(eventId: id)
                    }
                })
            }
        }
    }
    
    public func deleteCalendarEventById(eventId: String) {
        guard let calendarId = self.calendarId else {
            return
        }
        
        let eventId = eventId
        
        let query = GTLRCalendarQuery_EventsDelete.query(withCalendarId: calendarId, eventId: eventId)
        
        calendarService.executeQuery(query, completionHandler: nil)
    }
    
    public func fetchCalendarEventsList(onCompleted: @escaping ([(String?, String?)]?, Error?) -> Void) {
        guard let calendarId = self.calendarId else {
            print("calendarId is nil")
            onCompleted(nil, SiteAssessmentError.googleCalendarFailed)
            return
        }
        
        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: calendarId)
        
        calendarService.executeQuery(query) { (_, list, error) in
            if let list = list as? GTLRCalendar_Events {
                let eventList = list.items?.compactMap({($0.identifier, $0.summary)})
                
                onCompleted(eventList, nil)
            } else {
                onCompleted(nil, error)
            }
        }
    }
    
    public func fetchCalendarList(onCompleted: @escaping ([String]?, Error?) -> Void) {
        let query = GTLRCalendarQuery_CalendarListList.query()
        
        calendarService.executeQuery(query) { (_, list, error) in
            
            if let list = list as? GTLRCalendar_CalendarList {
                let calendarList = list.items?.compactMap({$0.identifier})
                onCompleted(calendarList, nil)
            } else {
                onCompleted(nil, error)
            }
        }
    }
    
    public func addEventToCalendar(calendarId: String, name: String?,
                                   startTime: String?, endTime: String?,
                                   onCompleted: @escaping (Error?) -> Void) {
        
        let calendarID = calendarId
        
        let newEvent = GTLRCalendar_Event()
        newEvent.summary = name
        newEvent.descriptionProperty = name
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let startDateTime = dateFormatter.date(from: startTime!)!
        
        let endDate = dateFormatter.date(from: endTime!)!
        
        let eStartDateTime = GTLRDateTime(date: startDateTime)
        newEvent.start = GTLRCalendar_EventDateTime()
        newEvent.start?.dateTime = eStartDateTime
        
        let eEndDateTime = GTLRDateTime(date: endDate)
        newEvent.end = GTLRCalendar_EventDateTime()
        newEvent.end?.dateTime = eEndDateTime
        
        let reminder = GTLRCalendar_EventReminder()
        reminder.minutes = 60
        reminder.method = "email"
        
        newEvent.reminders = GTLRCalendar_Event_Reminders()
        newEvent.reminders?.overrides = nil
        newEvent.reminders?.useDefault = false
        
        let query = GTLRCalendarQuery_EventsInsert.query(withObject: newEvent, calendarId: calendarID)

        calendarService.executeQuery(query) { (_, _, error) in
            onCompleted(error)
        }
    }
}
