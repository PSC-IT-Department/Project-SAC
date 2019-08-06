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
    
    var images: [UIImage] = [UIImage(named: "Add_Pictures")!] {
        didSet {
            images.append(UIImage(named: "Add_Pictures")!)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.dataSource = self
        self.delegate = self

    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cellIdentifier = CellIdentifier<ImageGalleryCell>(reusableIdentifier: "ImageGalleryCell")
        let cell = collectionView.dequeueReusableCellWithIdentifier(identifier: cellIdentifier,
                                                                    forIndexPath: indexPath)
        
        let image = images[indexPath.row]
        
        cell.imageView.image = image
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: 32, height: 32)
    }

}
