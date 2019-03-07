//
//  ZohoService.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-02-25.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import Foundation

class ZohoService {
    private let downloadBaseURL         = "https://creator.zoho.com/api/json/site-assessment/view/Site_Assessment_Commercial_Report"

    private let uploadBaseURL = "https://creator.zoho.com/api/zoho_it1346/json/site-assessment/form/Site_Assessment_Commercial/record/update"

    private let authtokenValue       = "d3b26c03684aa2db7158bb155e25a071"
    private let zc_ownernameValue    = "zoho_it1346"
    private let scopeValue           = "creatorapi"
    private let rawValue             = "true"

    public static var sharedZohoService: ZohoService!

    public static func instantiateSharedInstance() {
        sharedZohoService = ZohoService()
    }

    public func getProjectList(onCompleted: (([[String: String]]?) -> ())?) {

        guard let email = GoogleService.sharedGoogleService.retrieveGoogleUserEmail(), let assignedTeam = email.split(separator: "@").first else {
            onCompleted?(nil)
            return
        }
        
        guard var components = URLComponents(string: downloadBaseURL) else {
            onCompleted?(nil)
            return
        }
        
        //let criteriaValue = "sac_assignedTeam==\(assignedTeam)&&sac_status==Pending"
        let criteriaValue = "sac_status==Pending"
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
            
            guard let responseData = data else {
                onCompleted?(nil)
                return
            }
            
            do {
                guard let jsonResponse = try JSONSerialization.jsonObject(with:
                    responseData, options: []) as? [String: Any], let zohoData = jsonResponse["Site_Assessment_Commercial"] as? [[String: String]] else {
                        onCompleted?(nil)
                        return
                }
                onCompleted?(zohoData)
                
            } catch {
                print("[retrieveData - JSONDecoder().decode] failed, error = \(error).")
                onCompleted?(nil)
                return
            }
        }
        
        task.resume()
    }
    
    public func uploadData(projectID: String, saData:[String: String], onCompleted: @escaping (Bool) -> ()) {
        
        guard var urlComponents = URLComponents(string: uploadBaseURL) else {
            onCompleted(false)
            return
        }
        
        let criteriaValue = "sac_projectID=\(projectID)"
        let queryItems = [
            URLQueryItem(name: "authtoken"   , value: authtokenValue),
            URLQueryItem(name: "scope"       , value: scopeValue),
            URLQueryItem(name: "criteria"    , value: criteriaValue),
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
        
    }
    
    public func setRemoteToUploading(projectID: String, onCompleted: @escaping (Bool) -> ()) {
        uploadData(projectID: projectID, saData: ["sac_status": "Uploading"]) { (success) in
            onCompleted(success)
        }
    }
        
}
