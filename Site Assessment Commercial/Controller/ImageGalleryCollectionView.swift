//
//  ImageGalleryCollectionView.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-01-08.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ImageGalleryCollectionView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var images: [UIImage]? = []

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.dataSource = self
        self.delegate = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                
        let imagesCount = images?.count ?? 1
        
        return imagesCount == 1 ? 1 : imagesCount + 1
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageGalleryCell", for: indexPath) as! ImageGalleryCell
        
        if indexPath.row == images?.count {
            cell.imageView.image = UIImage(named: "Add_Pictures")
        } else {
            if let image = images?[indexPath.row] {
                cell.imageView.image = image
            } else {
                cell.imageView.image = UIImage()
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: 84, height: 84)
    }

}
