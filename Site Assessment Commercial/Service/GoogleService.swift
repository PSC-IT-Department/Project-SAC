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
        signIn = GIDSignIn.sharedInstance()
        driveService = GTLRDriveService()
        calendarService = GTLRCalendarService()
    }
    
    func storeGoogleAccountInformation(_signIn: GIDSignIn) {
        let user = _signIn.currentUser
        signIn = _signIn
        driveService.authorizer = user!.authentication.fetcherAuthorizer()
        calendarService.authorizer = user!.authentication.fetcherAuthorizer()

        let userDefaults = UserDefaults.standard
        userDefaults.set(user!.profile.email, forKey: "GoogleUser")
    }
    
    func syncWithCalendar() {
    }
    
    func retrieveGoogleUserInformation() -> GIDSignIn? {
        return signIn
    }
    
    func resetGoogleUserInformation() {
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "GoogleUser")
    }
    
    func getEmail() -> String? {
        let userDefaults = UserDefaults.standard
        return userDefaults.string(forKey: "GoogleUser")
    }
    
    public func listFilesInFolder(_ folder: String, onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> Void) {
        search(folder) { [weak self] (folderID, error) in
            guard let ID = folderID else {
                onCompleted(nil, error)
                return
            }
            
            self?.listFiles(ID, onCompleted: onCompleted)
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

        guard let dataStorageService = DataStorageService.shared,
            let homeDirectory = dataStorageService.homeDirectory else {
            print("homeDirectory is nil")
            onCompleted(false, nil)
            return
        }

        let fileURL = homeDirectory.appendingPathComponent(fileName).appendingPathExtension(fileFormat).path
        upload(folderID, path: fileURL, MIMEType: MIMEType, onCompleted: { (fileID, error) in
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
        createCategoryFolders(pfid: fid) {
            [weak self, weak dataStorageService = DataStorageService.shared] (success, error) in
            guard success else {
                print("createCategoryFolders failed, error = \(String(describing: error))")
                onCompleted?(false, error)
                return
            }

            self?.createSectionFolders(pfid: fid, onCompleted: {
                [weak self, weak dataStorageService = DataStorageService.shared] (success, error) in
                guard success,
                    let imageArray = dataStorageService?.retrieveCurrentProjectData().prjImageArray
                    else {
                        print("createSectionFolders failed, error = \(String(describing: error))")
                    onCompleted?(false, error)
                    return
                }

                imageArray
                    .flatMap({$0.sections.filter({$0.count >= 1})})
                    .forEach({ (section) in
                        let sectionName = section.name
                        var start = 0
                        let count = section.count
                        if let sfid = self?.ggFolderIDs[sectionName],
                            let prjDir = dataStorageService?.homeDirectory,
                            let prjId = dataStorageService?.currentProjectID {

                            section.imageArrays
                                .compactMap({$0.images?.compactMap({$0.name})})
                                .flatMap({$0})
                                .forEach({ fileName in
                                    let prefix = prjDir.path + "/" + prjId + "/"
                                    let fileFullName = fileName + ".png"
                                    let filePath = prefix + fileFullName
                                    self?.upload(sfid, path: filePath, MIMEType: "image/png",
                                                 onCompleted: { (fileId, _) in
                                        start += 1
                                        if let fid = fileId {
                                            print("fid = \(fid)")
                                        } else {
                                            print("file upload failed.")
                                        }

                                        if start == count {
                                            print("Files upload successfully.")
                                            onCompleted?(true, nil)
                                            return
                                        }
                                    })
                                })
                        } else {
                            print("No such folder: \(sectionName)")
                            onCompleted?(false, nil)
                            return
                        }
                    })
            })
        }
    }
    
    public func uploadData(fid: String, onCompleted: ((Bool, Error?) -> Void)?) {
        createProjectDataFolder(pfid: fid) {
            [weak self, weak dataStorageService = DataStorageService.shared] (folderID, error) in
            guard let fid = folderID,
                let saData = dataStorageService?.retrieveCurrentProjectData()
                else {
                    onCompleted?(false, error)
                    return
            }

            if let prjID = saData.prjInformation.projectID, let prjType = saData.prjInformation.type {
            
                let t = prjType == .SiteAssessmentCommercial ? "S" : "R"
                let fileName = t + prjID
                let format = "json"
                let type = "application/json"
                self?.uploadProjectFlie(fileName: fileName,
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
        let imgCount = saData.prjImageArray.count

        print("imgCount = \(imgCount)")
        print("To-Do: if imgCount < 1")
        /*
        if imgCount < 1 {
            print("No need to upload to Google Drive, success.")
            onCompleted?(true, nil)
            return
        }
         */
        search(rootDir) { [weak self] (folderID, error) in
            if let err = error {
                print("folderID, Error = \(err)")
                onCompleted?(false, err)
            }
            
            if let fid = folderID {
                print("fid = \(fid)")
                
                self?.createProjectFolder(rfid: fid, onCompleted: { [weak self] (folderID, error) in
                    
                    if let err = error {
                        print("createProjectFolder, Error = \(err)")
                        onCompleted?(false, err)
                    }
                    
                    if let pfid = folderID {
                        print("pfid = \(pfid)")
                        
                        self?.uploadData(fid: pfid, onCompleted: { (success, error) in
                            if let err = error {
                                print("uploadData, Error = \(err)")
                            }
                            
                            if success {
                                print("JSON file uploaded successfully.")
                            }
                        })
                        
                        self?.uploadImages(fid: pfid, onCompleted: { (success, error) in
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

    private func createSectionFolders(pfid: String, onCompleted: ((Bool, Error?) -> Void)?) {
        guard let dataStorageService = DataStorageService.shared else {
            print("Error: createSectionFolders failed for DataStorageService.shared.")
            onCompleted?(false, nil)
            return
        }

        let imageArray = dataStorageService.retrieveCurrentProjectData().prjImageArray

        imageArray.filter({$0.sections.contains(where: {$0.count >= 1})})
            .forEach { category in
                var start = 0
                let sections = category.sections.filter({$0.count >= 1})
                let count = sections.count
                print("count = \(count)")
                
                if let cfid = ggFolderIDs[category.name] {
                    sections
                        .forEach({ (section) in
                            let sectionName = section.name
                            createSubfolder(sectionName, cfid, onCompleted: { [weak self] (folderId, error) in
                                if let err = error {
                                    print("createSectionFolders, Error = \(err)")
                                }

                                guard let fid = folderId else {
                                    print("Error: createSubfolder failed for sections.")
                                    onCompleted?(false, error)
                                    return
                                }

                                self?.ggFolderIDs.updateValue(fid, forKey: sectionName)

                                start += 1
                                if start == count {
                                    onCompleted?(true, nil)
                                    return
                                }
                            })
                        })
                } else {
                    print("No such category: \(category.name)")
                    onCompleted?(false, nil)
                    return
                }
        }
    }
    
    private func createCategoryFolders(pfid: String, onCompleted: ((Bool, Error?) -> Void)?) {
        guard let dataStorageService = DataStorageService.shared else {
            print("Error: createSubfolder failed for DataStorageService.shared.")
            onCompleted?(false, nil)
            return
        }

        let prjdata = dataStorageService.retrieveCurrentProjectData()
        let count = prjdata.prjQuestionnaire.count
        var start = 0
        prjdata.prjQuestionnaire
            .compactMap({$0.Name})
            .forEach({ [weak self] (name) in
                self?.createSubfolder(name, pfid, onCompleted: { [weak self] (sectionFolderID, error) in
                    if let err = error {
                        print("createProjectSectionFolders, Error = \(err)")
                    }

                    guard let sfid = sectionFolderID else {
                        print("Error: createSubfolder failed for sections.")
                        onCompleted?(false, error)
                        return
                    }

                    self?.ggFolderIDs.updateValue(sfid, forKey: name)

                    start += 1
                    if start == count {
                        onCompleted?(true, nil)
                    }
                })
            })
    }
    
    private func createProjectDataFolder(pfid: String, onCompleted: ((String?, Error?) -> Void)?) {
        let sectionData = "DATA"
        createSubfolder(sectionData, pfid, onCompleted: { [weak self] (dataFolderID, error) in
            if let err = error {
                print("createProjectDataFolder, Error = \(err)")
            }
            
            guard let dfid = dataFolderID else {
                print("Error: createSubfolder failed for \(sectionData).")
                onCompleted?(nil, error)
                return
            }
            
            self?.ggFolderIDs.updateValue(dfid, forKey: sectionData)
            onCompleted?(dfid, nil)
        })
    }
    
    private func createProjectFolder(rfid: String, onCompleted: ((String?, Error?) -> Void)?) {
        guard let dataStorage = DataStorageService.shared,
            let prjAddr = dataStorage.retrieveCurrentProjectData().prjInformation.projectAddress
            else {
            print("createProjectFolder DataStorageService.shared is nil")
            onCompleted?(nil, nil)
            return
        }

        createSubfolder(prjAddr, rfid, onCompleted: { [weak self] (folderID, error) in
            if let err = error {
                print("createProjectFolder, createSubfolder Error: \(err)")
            }

            guard let fid = folderID else {
                onCompleted?(nil, error)
                return
            }

            let key = "Project Address"
            self?.ggFolderIDs.updateValue(fid, forKey: key)
            onCompleted?(fid, nil)
            return
        })
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
        
        driveService.executeQuery(query, completionHandler: { (_, file, error) in
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
}

extension GoogleService {
    public func checkDuplicateEventsByEventName(eventName: String) {
        fetchCalendarEventsList { [weak self] (list, error) in
            if let eventList = list, error == nil {
                eventList.filter({$0.1 == eventName}).forEach({ (event) in
                    if let id = event.0 {
                        self?.deleteCalendarEventById(eventId: id)
                    }
                })
            }
        }
    }
    
    public func deleteCalendarEventById(eventId: String) {
        guard let calendarId = calendarId else {
            return
        }
        
        let eventId = eventId
        
        let query = GTLRCalendarQuery_EventsDelete.query(withCalendarId: calendarId, eventId: eventId)
        
        calendarService.executeQuery(query, completionHandler: nil)
    }
    
    public func fetchCalendarEventsList(onCompleted: @escaping ([(String?, String?)]?, Error?) -> Void) {
        guard let calendarId = calendarId else {
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
                                   notes: String?,
                                   onCompleted: @escaping (Error?) -> Void) {
        
        let calendarID = calendarId
        
        let newEvent = GTLRCalendar_Event()
        newEvent.summary = name
        newEvent.descriptionProperty = notes
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var startDateTime = Date()
        if let _startTime = startTime {
            startDateTime = dateFormatter.date(from: _startTime)!
        }

        var endDateTime = Date()
        if let _endTime = endTime {
            endDateTime = dateFormatter.date(from: _endTime)!
        }

        let eStartDateTime = GTLRDateTime(date: startDateTime)
        newEvent.start = GTLRCalendar_EventDateTime()
        newEvent.start?.dateTime = eStartDateTime
        
        let eEndDateTime = GTLRDateTime(date: endDateTime)
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
