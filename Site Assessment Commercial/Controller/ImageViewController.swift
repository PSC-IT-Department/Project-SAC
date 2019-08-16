//
//  ImageViewController.swift
//  Site Assessment Commercial
//
//  Created by ChenYu on 2019-03-27.
//  Copyright © 2019 chyapp.com. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxGesture

class ImageViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    static let id = "ImageViewController"
    
    private var disposeBag = DisposeBag()
    
    var photoName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBackground()
        if let photoName = photoName {
            imageView.image = UIImage(named: photoName)
        }
        
        configureSizeAndZoomScale(image: imageView.image)
        
        setupTapHandling()
    }
    
    static func instantiateFromStoryBoard(imageName: String) -> ImageViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: id) as? ImageViewController
        viewController?.photoName = imageName
        
        return viewController
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in self?.centerScrollViewContents() }, completion: nil)
    }
    
    @IBAction func scrollViewDoubleTapped(recognizer: UITapGestureRecognizer) {
        let pointInView = recognizer.location(in: imageView)
        if scrollView.zoomScale < scrollView.maximumZoomScale {
            zoomToScale(scale: scrollView.maximumZoomScale, pointInView: pointInView)
        } else {
            zoomToScale(scale: scrollView.minimumZoomScale, pointInView: pointInView)
        }
    }
    
    func configureSizeAndZoomScale(image: UIImage?) {
        if let image = image {
            imageView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: image.size)
            scrollView.addSubview(imageView)
            scrollView.contentSize = image.size
            
            let scrollViewFrame = scrollView.frame
            let scaleWidth = scrollViewFrame.size.width / scrollView.contentSize.width
            let scaleHeight = scrollViewFrame.size.height / scrollView.contentSize.height
            let minScale = min(scaleWidth, scaleHeight)
            
            scrollView.minimumZoomScale = minScale
            scrollView.maximumZoomScale = 1.0
            scrollView.zoomScale = minScale
            
            centerScrollViewContents()
        }
    }
    
    func centerScrollViewContents() {
        let boundsSize = scrollView.bounds.size
        var contentsFrame = imageView.frame
        
        if contentsFrame.size.width < boundsSize.width {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        
        imageView.frame = contentsFrame
    }
    
    func zoomToScale(scale: CGFloat, pointInView: CGPoint) {
        let scrollViewSize = scrollView.bounds.size
        let w = scrollViewSize.width / scale
        let h = scrollViewSize.height / scale
        let x = pointInView.x - (w / 2.0)
        let y = pointInView.y - (h / 2.0)
        
        let rectToZoomTo = CGRect(x: x, y: y, width: w, height: h)
        
        scrollView.zoom(to: rectToZoomTo, animated: true)
    }

    deinit {
        print("ImageViewController deinit")
    }
}

extension ImageViewController {
    func setupTapHandling() {
        imageView
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UIScrollViewDelegate
extension ImageViewController: UIScrollViewDelegate {
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerScrollViewContents()
    }
}
