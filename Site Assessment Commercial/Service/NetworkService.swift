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

enum ReachabilityStatus {
    case unknown
    case disconnected
    case connected
}

class NetworkService {
    
    private let disposeBag = DisposeBag()

    public static var sharedNetworkService: NetworkService!

    private let reachability: Reachability!
    public private(set) var reachabilityStatus: ReachabilityStatus

    public static func instantiateSharedInstance() {
        sharedNetworkService = NetworkService()
    }
    
    private init() {
        reachability = Reachability()
        reachabilityStatus = .unknown
        
        beginListeningNetworkReachability()
    }
    
    func beginListeningNetworkReachability() {

        /*
        reachability.rx.reachabilityChanged
            .subscribe(onNext: { reachability in
                print("Reachability changed: \(reachability.connection.description)")
            })
            .disposed(by: disposeBag)
         */
        
        reachability.rx.status
            .subscribe(onNext: { status in
                switch status {
                case .cellular, .wifi:
                    self.reachabilityStatus = .connected
                    
                    NotificationCenter.default.post(name: .didReceiveReachabilityMsg, object: "Online Mode")
                case .none:
                    self.reachabilityStatus = .disconnected
                    NotificationCenter.default.post(name: .didReceiveReachabilityMsg, object: "Offline Mode")
                }
            })
            .disposed(by: disposeBag)
        
        /*
        reachability.rx.isReachable
            .subscribe(onNext: { isReachable in
                print("Is reachable: \(isReachable)")
            })
            .disposed(by: disposeBag)
        
        reachability.rx.isConnected
            .subscribe(onNext: {
                print("Is connected")
            })
            .disposed(by: disposeBag)
        
        reachability.rx.isDisconnected
            .subscribe(onNext: {
                print("Is disconnected")
            })
            .disposed(by: disposeBag)
         */
        
        try? reachability.startNotifier()

    }
    
    deinit {
        reachability.stopNotifier()
    }
    
}
