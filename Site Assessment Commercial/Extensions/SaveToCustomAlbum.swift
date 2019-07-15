//
//  SaveToCustomAlbum.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-01-25.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import Photos

class SaveToCustomAlbum: NSObject {
    static let albumName = "Site Assessment"
    static let shared = SaveToCustomAlbum()
    
    private var assetCollection: PHAssetCollection!
    
    private override init() {
        super.init()
        
        if let assetCollection = fetchAssetCollectionForAlbum() {
            self.assetCollection = assetCollection
            return
        }
    }
    
    private func checkAuthorizationWithHandler(completion: @escaping ((_ success: Bool) -> Void)) {
        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization({ (_) in
                self.checkAuthorizationWithHandler(completion: completion)
            })
        } else if PHPhotoLibrary.authorizationStatus() == .authorized {
            self.createAlbumIfNeeded { (success) in
                if success {
                    completion(true)
                } else {
                    completion(false)
                }
                
            }
            
        } else {
            completion(false)
        }
    }
    
    private func createAlbumIfNeeded(completion: @escaping ((_ success: Bool) -> Void)) {
        if let assetCollection = fetchAssetCollectionForAlbum() {
            // Album already exists
            self.assetCollection = assetCollection
            completion(true)
        } else {
            let library = PHPhotoLibrary.shared()
            
            let title = SaveToCustomAlbum.albumName
            library.performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            }, completionHandler: { [weak self] (success, _) in
                if success {
                    self?.assetCollection = self?.fetchAssetCollectionForAlbum()
                    completion(true)
                } else {
                    completion(false)
                }
            })
        }
    }
    
    private func fetchAssetCollectionForAlbum() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", SaveToCustomAlbum.albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let _: AnyObject = collection.firstObject {
            return collection.firstObject
        }
        return nil
    }
    
    func saveImages(imageArray: [UIImage]) {
        imageArray.forEach { self.save(image: $0) }
    }
    
    func save(image: UIImage) {
        self.checkAuthorizationWithHandler { [weak self] (success) in
            if success, let collection = self?.assetCollection {
                PHPhotoLibrary.shared().performChanges({
                    let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
                    if let albumChangeRequest = PHAssetCollectionChangeRequest(for: collection) {
                        let enumeration: NSArray = [assetPlaceHolder!]
                        albumChangeRequest.addAssets(enumeration)
                    }
                    
                }, completionHandler: { (success, error) in
                    if success {
                        print("Successfully saved image to \(SaveToCustomAlbum.albumName).")
                    } else {
                        print("Error writing to image library: \(error!.localizedDescription)")
                    }
                })
                
            }
        }
    }
    
    func saveMovieToLibrary(movieURL: URL) {
        
        self.checkAuthorizationWithHandler { [weak self] (success) in
            if success, let collection = self?.assetCollection {

                let library = PHPhotoLibrary.shared()
                library.performChanges({
                    if let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: movieURL) {
                        let assetPlaceHolder = request.placeholderForCreatedAsset
                        if let albumChangeRequest = PHAssetCollectionChangeRequest(for: collection) {
                            let enumeration: NSArray = [assetPlaceHolder!]
                            albumChangeRequest.addAssets(enumeration)
                        }
                    }
                    
                }, completionHandler: { (success, error) in
                    if success {
                        print("Successfully saved video to Camera Roll.")
                    } else {
                        print("Error writing to movie library: \(error!.localizedDescription)")
                    }
                })
            }
        }
        
    }
}
