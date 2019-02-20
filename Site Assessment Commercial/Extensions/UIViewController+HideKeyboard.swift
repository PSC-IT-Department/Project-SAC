//
//  UIViewController+HideKeyboard.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-02-15.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import UIKit

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
}
