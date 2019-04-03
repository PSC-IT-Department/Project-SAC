//
//  AboutViewController.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-04-01.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import UIKit
import WebKit

import RxCocoa
import RxSwift

class AboutViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        
        if let url = Bundle.main.url(forResource: "about", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }
    
    static func instantiateFromStoryBoard() -> AboutViewController {
        let viewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "AboutViewController") as! AboutViewController
        return viewController
    }
}

extension AboutViewController {
    
    func setupView() {
        title = "About this App"
    }
}
