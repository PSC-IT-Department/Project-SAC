//
//  ZohoService.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-02-25.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import Foundation

class ZohoService {
    
    // Public Information
    private let baseURL              = "https://creator.zoho.com"
    private let appName              = "site-assessment"
    private let format               = "json"
    private let authtokenValue       = "d3b26c03684aa2db7158bb155e25a071"
    private let zc_ownernameValue    = "zoho_it1346"
    private let scopeValue           = "creatorapi"
    private let rawValue             = "true"
    
    // Site Assessment Commercial
    private let sacFormName          = "Site_Assessment_Commercial"
    private let sacReportName        = "Site_Assessment_Commercial_Report"
    private let sacStatus            = "sac_status"
    private let sacStatusUploading   = "Uploading"
    private let sacProjectID         = "sac_projectID"
    private let sacAssignedTeam      = "sac_assignedTeam"
    
    // Measurment Team Mapping
    private let mtmFormName          = "Measurement_Team_Mapping"
    private let mtmReportName        = "Measurement_Team_Mapping_Report"
    private var mtmGoogleAccount     = "mtm_ggAccount"
    private let mtmGoogleEmail       = "mtm_ggEmail"
    private let mtmZohoAccount       = "mtm_zohoAccount"
    private let mtmZohoEmail         = "mtm_zohoEmail"

    public static var sharedZohoService: ZohoService!

    public static func instantiateSharedInstance() {
        sharedZohoService = ZohoService()
    }
    
    public func lookupZohoUser(onCompleted: ((String?) -> ())?) {
        let mtmBaseURL = "\(baseURL)/api/\(format)/\(appName)/view/\(mtmReportName)"

        guard let ggEmail = GoogleService.sharedGoogleService.retrieveGoogleUserEmail(), let ggAccount = ggEmail.split(separator: "@").first else {
            onCompleted?(nil)
            return
        }

        guard var components = URLComponents(string: mtmBaseURL) else {
            onCompleted?(nil)
            return
        }
        
        let criteriaValue = "\(self.mtmGoogleAccount)==\(ggAccount)"
        let queryItems = [
            URLQueryItem(name: "authtoken"   , value: authtokenValue),
            URLQueryItem(name: "zc_ownername", value: zc_ownernameValue),
            URLQueryItem(name: "scope"       , value: scopeValue),
            URLQueryItem(name: "raw"         , value: rawValue),
            URLQueryItem(name: "criteria"    , value: criteriaValue),
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
        
        let task = URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            if let err = error {
                print("Error = \(err)")
            }
            
            guard let responseData = data,
                let jsonResponse = try? JSONSerialization.jsonObject(with:
                    responseData, options: []) as? [String: [[String: String]]],
                let zohoAccount = jsonResponse?[self.mtmFormName]?.first?[self.mtmZohoAccount]
                else {
                    onCompleted?(nil)
                    return
            }
            
            onCompleted?(zohoAccount)
            return
        }
        
        task.resume()
        
    }

    public func getProjectList(onCompleted: (([[String: String]]?) -> ())?) {
        let downloadBaseURL = "\(baseURL)/api/\(format)/\(appName)/view/\(sacReportName)"

        self.lookupZohoUser { zohoAccount in
            guard let assignedTeam = zohoAccount else {
                onCompleted?(nil)
                return
            }
            
            guard var components = URLComponents(string: downloadBaseURL) else {
                onCompleted?(nil)
                return
            }
            
            let criteriaValue = "\(self.sacAssignedTeam)==\(assignedTeam)&&\(self.sacStatus)==Pending"
            let queryItems = [
                URLQueryItem(name: "authtoken"   , value: self.authtokenValue),
                URLQueryItem(name: "zc_ownername", value: self.zc_ownernameValue),
                URLQueryItem(name: "scope"       , value: self.scopeValue),
                URLQueryItem(name: "raw"         , value: self.rawValue),
                URLQueryItem(name: "criteria"    , value: criteriaValue),
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
            
            let task = URLSession.shared.dataTask(with: url) {
                (data, response, error) in
                if let err = error {
                    print("Error = \(err)")
                }
                
                guard let responseData = data,
                    let jsonResponse = try? JSONSerialization.jsonObject(with:
                        responseData, options: []) as? [String: [[String: String]]],
                    let zohoData = jsonResponse?[self.sacFormName]
                    else {
                            onCompleted?(nil)
                            return
                }
                onCompleted?(zohoData)
                return
            }
            
            task.resume()
        }

    }
    
    public func uploadData(projectID: String, saData:[String: String], onCompleted: @escaping (Bool) -> ()) {
        let uploadBaseURL = "\(baseURL)/api/\(zc_ownernameValue)/\(format)/\(appName)/form/\(sacFormName)/record/update"

        guard var urlComponents = URLComponents(string: uploadBaseURL) else {
            onCompleted(false)
            return
        }
        
        let criteriaValue = "\(sacProjectID)=\(projectID)"
        let queryItems = [
            URLQueryItem(name: "authtoken"   ,value: authtokenValue),
            URLQueryItem(name: "scope"       ,value: scopeValue),
            URLQueryItem(name: "criteria"    ,value: criteriaValue),
        ]
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            onCompleted(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        guard let uploadData = saData.compactMap ({ (key, value) in [key, value].joined(separator: "=")}).joined(separator: "&").data(using: .utf8) else {
            onCompleted(false)
            return
        }
        
        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { (data, response, error) in
            if let err = error {
                print ("error: \(err)")
            }
            
            guard let respData = data,
                  let response = response as? HTTPURLResponse,
                  (200...299).contains(response.statusCode)
                else {
                onCompleted(false)
                return
            }
            guard let dataString = String(data: respData, encoding: .utf8), dataString.contains("Success") else {
                onCompleted(false)
                return
            }
            
            onCompleted(true)
            
        }
        
        task.resume()
    }
    
    public func uploadProject(withData saData:SiteAssessmentDataStructure, onCompleted: @escaping (Bool) -> ()) {
        var sendData: [String: String] = [:]
        
        if let prjID = saData.prjInformation.projectID {
        
            sendData.updateValue(prjID, forKey: sacProjectID)
            sendData.updateValue(UploadStatus.completed.rawValue, forKey: sacStatus)
            
            saData.prjQuestionnaire.forEach { (section) in
                section.Questions.forEach{ (question) in
                    if let value = question.Value {
                        sendData.updateValue(value, forKey: question.Key)
                    }
                }
            }
                        
            uploadData(projectID: prjID, saData: sendData) { (success) in
                onCompleted(success)
            }
        }
    }
    
    public func setRemoteToUploading(projectID: String, onCompleted: @escaping (Bool) -> ()) {
        uploadData(projectID: projectID, saData: [sacStatus: sacStatusUploading]) { (success) in
            onCompleted(success)
        }
    }
        
}
