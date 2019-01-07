//
//  ImageGalleryTableView.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-01-04.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ImageGalleryTableView: UITableView, UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ImageGalleryCell") as! ImageGalleryCell
        return cell
    }
    
    override func awakeFromNib() {
        self.dataSource = self
        self.delegate = self
    }
    
    
    
}
