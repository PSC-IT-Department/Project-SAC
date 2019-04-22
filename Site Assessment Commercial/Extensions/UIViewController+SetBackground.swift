//
//  UIViewController+SetBackground.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-03-15.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func setBackground(_ withBlurEffect: Bool = true) {
        let background = UIImage(named: "bg_img")
        
        var imageView: UIImageView!
        
        imageView = UIImageView(frame: view.bounds)
        imageView.contentMode =  UIView.ContentMode.scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = background
        imageView.center = view.center
        
        if withBlurEffect {
            let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = imageView.bounds
            imageView.addSubview(blurView)
        }
        
        view.addSubview(imageView)
        
        self.view.sendSubviewToBack(imageView)
    }
}
