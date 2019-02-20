//
//  ThirdPartyAccessViewController.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-02-19.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

class ThirdPartyAccessViewController: UIViewController{
    
    private var titleString: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = titleString
        
        setupGoogleSignIn()
        
    }
    
    static func instantiateFromStoryBoard(withTitle title: String) -> ThirdPartyAccessViewController {
        let viewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "ThirdPartyAccessViewController") as! ThirdPartyAccessViewController
        viewController.titleString = title
        return viewController
    }
    
    private func setupGoogleSignIn() {

        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = [kGTLRAuthScopeDrive]
        GIDSignIn.sharedInstance().signInSilently()
        GIDSignIn.sharedInstance()?.shouldFetchBasicProfile = true

        let button = GIDSignInButton(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        button.center = view.center
//        button.isUserInteractionEnabled = false
        view.addSubview(button)
    }
}

// MARK: - GIDSignInDelegate
extension ThirdPartyAccessViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print(error)
        } else {
            UserDefaults.standard.set(user, forKey: "GoogleAccount")
        
            dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - GIDSignInUIDelegate
extension ThirdPartyAccessViewController: GIDSignInUIDelegate {}
