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

class GoogleAccessViewController: UIViewController {
    
    private var titleString: String!
    
    let service = GTLRDriveService()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = titleString
        
        if let email = GoogleService.sharedGoogleService.retrieveGoogleUserEmail() {
            setupForSignOut()
        } else {
            setupForSignIn()
        }
    }
    
    static func instantiateFromStoryBoard(withTitle title: String) -> GoogleAccessViewController {
        let viewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "ThirdPartyAccessViewController") as! GoogleAccessViewController
        viewController.titleString = title
        return viewController
    }
    
    private func setupForSignOut() {
        
        let signOutView = Bundle.main.loadNibNamed("GoogleSignOut", owner: self, options: nil)?.first as! GoogleSIgnOutView

        signOutView.label.text = GoogleService.sharedGoogleService.retrieveGoogleUserEmail()
        signOutView.signOutButton.addTarget(self, action: #selector(buttonSignOutDidClicked), for: .touchUpInside)
        signOutView.center = view.center
        
        self.view.addSubview(signOutView)
    }
    
    @objc func buttonSignOutDidClicked(_ sender: UIButton) {
        let alertVC = UIAlertController(title: "Sign Out", message: "", preferredStyle: .alert)
        
        let actionConfrim = UIAlertAction(title: "Yes", style: .default, handler: { _ in
            GIDSignIn.sharedInstance()?.signOut()
            GoogleService.sharedGoogleService.resetGoogleUserInformation()
            self.navigationController?.popToRootViewController(animated: true)

        })
        
        let actionCancel = UIAlertAction(title: "No", style: .cancel, handler: { _ in
            self.navigationController?.popToRootViewController(animated: true)
        })
        
        alertVC.addAction(actionConfrim)
        alertVC.addAction(actionCancel)
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    private func setupForSignIn() {
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().scopes = [kGTLRAuthScopeDrive]
        GIDSignIn.sharedInstance().shouldFetchBasicProfile = true
        GIDSignIn.sharedInstance().signInSilently()

        let button = GIDSignInButton(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        button.center = view.center
        view.addSubview(button)
    }
}

// MARK: - GIDSignInDelegate
extension GoogleAccessViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print(error)
        } else {
            GoogleService.sharedGoogleService.storeGoogleAccountInformation(signIn: signIn)
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}

// MARK: - GIDSignInUIDelegate
extension GoogleAccessViewController: GIDSignInUIDelegate {}
