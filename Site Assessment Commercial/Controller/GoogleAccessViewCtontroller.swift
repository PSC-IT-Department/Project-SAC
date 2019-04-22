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
    
    static let id = "GoogleAccessViewController"
    
    let service = GTLRDriveService()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let email = GoogleService.shared.getEmail() {
            setupForSignOut()
        } else {
            setupForSignIn()
        }
    }
    
    static func instantiateFromStoryBoard() -> GoogleAccessViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: id) as? GoogleAccessViewController
        return controller
    }
    
    private func setupView() {
        self.title = "Google"
    }
    
    private func setupForSignOut() {
        let bundle = Bundle.main
        
        guard let signOutView = bundle.loadNibNamed("GoogleSignOut", owner: self, options: nil)?.first as? GoogleSignOutView else { return }

        signOutView.label.text = GoogleService.shared.getEmail()
        signOutView.signOutButton.addTarget(self, action: #selector(buttonSignOutDidClicked), for: .touchUpInside)
        signOutView.center = view.center
        
        self.view.addSubview(signOutView)
    }
    
    @objc func buttonSignOutDidClicked(_ sender: UIButton) {
        let alertVC = UIAlertController(title: "Sign Out", message: "", preferredStyle: .alert)
        
        let actionConfrim = UIAlertAction(title: "Yes", style: .default, handler: { _ in
            GIDSignIn.sharedInstance()?.signOut()
            GoogleService.shared.resetGoogleUserInformation()
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
        GIDSignIn.sharedInstance().scopes = [kGTLRAuthScopeDrive, kGTLRAuthScopeCalendar]
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
            GoogleService.shared.storeGoogleAccountInformation(signIn: signIn)
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}

// MARK: - GIDSignInUIDelegate
extension GoogleAccessViewController: GIDSignInUIDelegate {}
