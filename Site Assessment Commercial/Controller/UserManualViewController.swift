//
//  UserManualViewController.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-04-12.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

import WebKit

class UserManualViewController: UIViewController {
    
    static let id = "UserManualViewController"
    
    let url: URL = URL(string: "https://polaronsolar.com/wp-content/uploads/2019/04/userManual.html")!

    @IBOutlet weak var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        webViewLoadPages()
    }
    
    static func instantiateFromStoryBoard() -> UserManualViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: id) as? UserManualViewController
        return controller
    }
}

extension UserManualViewController {
    
    private func setupView() {
        self.title = "User Manual"
    }
    
    private func webViewLoadPages() {
        let urlRequest = URLRequest(url: url)
        webView.load(urlRequest)
    }
}
