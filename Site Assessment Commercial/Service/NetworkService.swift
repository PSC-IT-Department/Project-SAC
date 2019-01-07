//
//  NetworkService.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2018-11-28.
//  Copyright © 2018 chyapp.com. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import Alamofire
import RxAlamofire
import Reachability
import RxReachability

class NetworkService {
    
    private let disposeBag = DisposeBag()

    public static var sharedNetworkService: NetworkService!
    
    private let reachabilityManager: NetworkReachabilityManager?
    
    public static func instantiateSharedInstance() {
        sharedNetworkService = NetworkService()
    }
    
    private init() {
        self.reachabilityManager = NetworkReachabilityManager()
    }
    
    deinit {
    }
    
    public func syncFromZohoCreator() {
        let assignedToShorten = "klozoho"
    
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "creator.zoho.com"
        urlComponents.path = "/api/json/site-assessment/view/Site_Assessment_Report"
        
        let queryItemToken = URLQueryItem(name: "authtoken", value: "d3b26c03684aa2db7158bb155e25a071")
        let queryItemOwner = URLQueryItem(name: "zc_ownername", value: "zoho_it1346")
        let queryItemScope = URLQueryItem(name: "scope", value: "creatorapi")
        let queryItemRawJson = URLQueryItem(name: "raw", value: "true")
        let queryItemCriteria = URLQueryItem(name: "criteria", value: "sa_assignedToShorten==\(assignedToShorten)&&sa_completed==false")
        
        urlComponents.queryItems = [queryItemOwner, queryItemScope, queryItemToken, queryItemRawJson, queryItemCriteria]
        
        // Zoho Creator Only
        urlComponents.percentEncodedQuery = urlComponents.percentEncodedQuery?
                .replacingOccurrences(of: "&&", with: "%26%26")
        
        guard let url = urlComponents.url else {
            print("Error: url is wrong")
            return
        }
        
        let observable:Observable<(HTTPURLResponse, Any)> = requestJSON(.get, url)
        observable
            .subscribe(
                onNext: { [weak self] (resp, json) in
                    if resp.statusCode == 200 {
                        let data = json as? [String: Any]
                        let __data = data?["Site_Assessment"] as! [[String: Any]]
                        
                        print(__data)
                        DataStorageService.sharedDataStorageService.storeData()
                    }
                    else {
                        print(resp.statusCode)
                    }
                }, onError:{
                    print("Error: Data is wrong. \($0)")
            })
        .disposed(by: disposeBag)
    }

    func uploadToGoogleDrive() {
        
    }
    
    func uploadToZohoCreator() {
        
    }
    
}
