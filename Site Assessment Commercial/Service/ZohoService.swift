//
//  ZohoService.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-02-25.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import Foundation

enum ZohoKeywords: String {
    case status = "sa_status"
    case projectID = "sa_projectID"
    case assignedTeam = "sa_assignedTeam"
}

class ZohoService {
    
    // Public Information
    private let baseURL              = "https://creator.zoho.com"
    private let appName              = "site-assessment"
    private let format               = "json"
    private let authtokenValue       = "d3b26c03684aa2db7158bb155e25a071"
    private let zc_ownernameValue    = "polaronsolartech"
    private let scopeValue           = "creatorapi"
    private let rawValue             = "true"
    
    // Site Assessment Commercial
    private let sacFormName          = "Site_Assessment_Commercial"
    private let sacReportName        = "Site_Assessment_Commercial_Report"
    
    private let saFormName           = "Site_Assessment"
    private let saReportName         = "Site_Assessment_Report"
    
    private let saStatus             = "sa_status"
    private let saProjectID          = "sa_projectID"
    private let saAssignedTeam       = "sa_assignedTeam"
    
    // Measurment Team Mapping
    private let mtmFormName          = "Measurement_Team_Mapping"
    private let mtmReportName        = "Measurement_Team_Mapping_Report"
    
    private var mtmGoogleAccount     = "mtm_ggAccount"
    private let mtmGoogleEmail       = "mtm_ggEmail"
    private let mtmZohoAccount       = "mtm_zohoAccount"
    private let mtmZohoEmail         = "mtm_zohoEmail"

    public static var shared: ZohoService!

    public static func instantiateSharedInstance() {
        shared = ZohoService()
    }
    
    init () {
        guard let path = Bundle.main.url(forResource: "ThirdpartyInfo", withExtension: "plist") else {
            print("ThirdpartyInfo.plist cannot find.")
            return
        }
        
        let result = Result {try Data(contentsOf: path)}.flatMap { (data) -> Result<Any, Error> in
            return Result {try PropertyListSerialization.propertyList(from: data,
                                                                      options: .mutableContainers,
                                                                      format: nil)}
        }
        
        switch result {
        case .success(let plist):
            if let dictArray = plist as? [[String: Any]] {
                
                if let sectionZoho = dictArray.last,
                    let value = sectionZoho["Name"] as? String,
                    value == "Zoho",
                    let zohoConfig = sectionZoho["Settings"] as? [String: String] {
                    print("zohoConfig = \(zohoConfig)")
                }
            }
        case .failure(let error):
            print("Error: ThirdpartyInfo.plist init failed. error = \(error)")
        }
    }
    
    public func lookupZohoUser(onCompleted: ((String?) -> Void)?) {
        let mtmBaseURL = "\(baseURL)/api/\(format)/\(appName)/view/\(mtmReportName)"

        guard let ggEmail = GoogleService.shared.getEmail(), let ggAccount = ggEmail.split(separator: "@").first else {
            onCompleted?(nil)
            return
        }

        guard var components = URLComponents(string: mtmBaseURL) else {
            onCompleted?(nil)
            return
        }
        
        let criteriaValue = "\(mtmGoogleAccount)==\(ggAccount)"
        let queryItems = [
            URLQueryItem(name: "authtoken", value: authtokenValue),
            URLQueryItem(name: "zc_ownername", value: zc_ownernameValue),
            URLQueryItem(name: "scope", value: scopeValue),
            URLQueryItem(name: "raw", value: rawValue),
            URLQueryItem(name: "criteria", value: criteriaValue)
            ]

        components.queryItems = queryItems
        
        /* -------------------------- Zoho Creator Only -------------------------- */
        // https://stackoverflow.com/questions/43052657/encode-using-urlcomponents-in-swift
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "&&", with: "%26%26")
        /* ----------------------------------------------------------------------- */
        
        guard let url = components.url else {
            onCompleted?(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
            if let err = error {
                print("Error = \(err)")
            }
            
            guard let responseData = data,
                let jsonResponse = ((try? JSONSerialization.jsonObject(with:
                    responseData, options: []) as? [String: [[String: String]]]) as [String: [[String: String]]]??),
                let mtmFormName = self?.mtmFormName,
                let mtmZohoAccount = self?.mtmZohoAccount,
                let zohoAccount = jsonResponse?[mtmFormName]?.first?[mtmZohoAccount]
                else {
                    onCompleted?(nil)
                    return
            }
            
            onCompleted?(zohoAccount)
        }
        
        task.resume()
        
    }

    public func getProjectList(type: SiteAssessmentType, onCompleted: (([[String: String]]?) -> Void)?) {
        lookupZohoUser { [unowned self] zohoAccount in
            guard let assignedTeam = zohoAccount else {
                onCompleted?(nil)
                return
            }

            var downloadBaseURL = "\(self.baseURL)/api/\(self.format)/\(self.appName)/view/"

            let criteriaValue = "\(self.saAssignedTeam)==\(assignedTeam)&&\(self.saStatus)==Pending"

            var criteria = ""
            switch type {
            case .SiteAssessmentCommercial:
                downloadBaseURL.append(contentsOf: self.sacReportName)
                criteria = criteriaValue
            case .SiteAssessmentResidential:
                downloadBaseURL.append(contentsOf: self.saReportName)
                criteria = criteriaValue
            default:
                print("default")
                return
            }

            guard var components = URLComponents(string: downloadBaseURL) else {
                onCompleted?(nil)
                return
            }

            let queryItems = [
                URLQueryItem(name: "authtoken", value: self.authtokenValue),
                URLQueryItem(name: "zc_ownername", value: self.zc_ownernameValue),
                URLQueryItem(name: "scope", value: self.scopeValue),
                URLQueryItem(name: "raw", value: self.rawValue),
                URLQueryItem(name: "criteria", value: criteria)
                ]

            components.queryItems = queryItems

            /* -------------------------- Zoho Creator Only -------------------------- */
            // https://stackoverflow.com/questions/43052657/encode-using-urlcomponents-in-swift
            components.percentEncodedQuery = components.percentEncodedQuery?
                .replacingOccurrences(of: "&&", with: "%26%26")
            /* ----------------------------------------------------------------------- */

            guard let url = components.url else {
                onCompleted?(nil)
                return
            }

            let urlSession = URLSession.shared
            let task = urlSession.dataTask(with: url) { [unowned self] (data, _, error) in
                if let err = error {
                    print("Error = \(err)")
                }

                let formName = (type == .SiteAssessmentCommercial) ? self.sacFormName : self.saFormName

                if let responseData = data,
                    let jsonResponse = ((try? JSONSerialization.jsonObject(with:
                        responseData, options: []) as? [String: [[String: String]]])),
                    let zohoData = jsonResponse[formName] {
                    DataStorageService.shared.writeToLog("dataTask decoded successfully.")
                    DataStorageService.shared.writeToLog("zohoData = \(zohoData)")
                    // print("zohoData = \(zohoData)")
                    onCompleted?(zohoData)
                    return
                } else {
                    DataStorageService.shared.writeToLog("dataTask decoded failed.")
                    onCompleted?(nil)
                }
            }
            
            task.resume()
        }

    }
    
    public func uploadData(projectID: String, saData: [String: String], onCompleted: ((Bool) -> Void)?) {

        let data = DataStorageService.shared.retrieveCurrentProjectData()
        let type = data.prjInformation.type
        let viewName = (type == .SiteAssessmentCommercial) ? sacReportName : saReportName
        let action = "/record/update"
        let uploadBaseURL = "\(baseURL)/api/\(zc_ownernameValue)/\(format)/\(appName)/view/" + viewName + action

        guard var urlComponents = URLComponents(string: uploadBaseURL) else {
            DataStorageService.shared.writeToLog("uploadData URLComponents failed.")
            onCompleted?(false)
            return
        }
        
        let criteriaValue = "\(saProjectID)=\(projectID)"
        let queryItems = [
            URLQueryItem(name: "authtoken", value: authtokenValue),
            URLQueryItem(name: "scope", value: scopeValue),
            URLQueryItem(name: "criteria", value: criteriaValue)
        ]
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            DataStorageService.shared.writeToLog("uploadData url = urlComponents.url")
            onCompleted?(false)
            return
        }
                
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        guard let uploadData = saData.compactMap ({ (key, value) in
            [key, value].joined(separator: "=")}).joined(separator: "&").data(using: .utf8)
            else {
            DataStorageService.shared.writeToLog("uploadData uploadData = saData.compactMap")
            onCompleted?(false)
            return
        }
        
        let urlSession = URLSession.shared
        let task = urlSession.uploadTask(with: request, from: uploadData) { (data, response, error) in
            if let err = error {
                print ("error: \(err)")
            }
            
            guard let respData = data,
                let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode)
                else {
                    DataStorageService.shared.writeToLog("uploadData respData = data")
                    onCompleted?(false)
                    return
            }
            
            if let dataString = String(data: respData, encoding: .utf8) {
                print("dataString: \(dataString)")
                DataStorageService.shared.writeToLog("dataString: \(dataString)")

                if dataString.contains("Success") {
                    print("Success.")
                    onCompleted?(true)
                    return
                }
            } else {
                print("uploadData dataString conversion failed.")
                DataStorageService.shared.writeToLog("uploadData dataString conversion failed.")
                onCompleted?(false)
            }
        }
        
        task.resume()
    }
    
    public func uploadProject(withData saData: SiteAssessmentDataStructure, onCompleted: ((Bool) -> Void)?) {
        var sendData: [String: String] = [:]
        
        guard let prjID = saData.prjInformation.projectID else {
            print("uploadProject cannot get prjID.")
            onCompleted?(false)
            return
        }
        
        sendData.updateValue(prjID, forKey: saProjectID)
        sendData.updateValue(UploadStatus.completed.rawValue, forKey: saStatus)
        
        let allQuestions = saData.prjQuestionnaire.compactMap({$0.Questions}).joined().compactMap({($0.Key, $0.Value)})
        allQuestions.forEach({ sendData.updateValue($0.1 ?? "", forKey: $0.0) })
        
        uploadData(projectID: prjID, saData: sendData) { (success) in
            print("uploadProject success = \(success)")
            onCompleted?(success)
        }
    }
    
    public func setRemoteToUploading(projectID: String, onCompleted: ((Bool) -> Void)?) {
        uploadData(projectID: projectID,
                   saData: [saStatus: UploadStatus.uploading.rawValue]) { (success) in
            if success {
                print("setRemoteToUploading uploadData success.")
                onCompleted?(true)
            } else {
                print("setRemoteToUploading uploadData failed.")
                onCompleted?(false)
            }
        }
    }
}
