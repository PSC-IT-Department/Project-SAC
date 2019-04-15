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

    @IBOutlet weak var labelAppName: UILabel!
    @IBOutlet weak var labelVersion: UILabel!

    @IBOutlet weak var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupWebViewFrame()
        setupDelegate()
        
        if let url = Bundle.main.url(forResource: "about", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        
        if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            labelAppName.text = appName
        }

        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            
            // Version 1.0 (Build 60)
            let text = "Version " + version + " (Build " + build + ")"
            
            labelVersion.text = text
        }
    }
    
    static func instantiateFromStoryBoard() -> AboutViewController {
        let viewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "AboutViewController") as! AboutViewController
        return viewController
    }
}

extension AboutViewController {
    
    private func setupView() {
        title = "About this App"
    }
    
    private func setupWebViewFrame() {
        let borderColor : UIColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)

        webView.layer.borderWidth = 0.5
        webView.layer.borderColor = borderColor.cgColor
        webView.layer.cornerRadius = 5.0
    }
    
    private func setupDelegate() {
        webView.navigationDelegate = self
        webView.uiDelegate = self
    }
}

extension AboutViewController: WKNavigationDelegate, WKUIDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url
        guard url != nil else {
            decisionHandler(.allow)
            return
        }
        
        if url!.description.lowercased().starts(with: "http://") ||
            url!.description.lowercased().starts(with: "https://")  {
            decisionHandler(.cancel)
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        } else {
            decisionHandler(.allow)
        }
    }
}
