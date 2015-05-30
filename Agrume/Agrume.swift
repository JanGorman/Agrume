//
//  Agrume.swift
//  Agrume
//
//  Created by Jan Gorman on 23/05/15.
//  Copyright (c) 2015 Schnaub. All rights reserved.
//

import UIKit

public class Agrume: UIViewController {
    
    private static let TransitionAnimationDuration: NSTimeInterval = 0.3
    private static let MaxScalingForExpandingOffscreen: CGFloat = 1.25
    
    private static let ReuseIdentifier = "ReuseIdentifier"
    
    private var backgroundSnapshot: UIImage!
    private var backgroundImageView: UIImageView!
    private var blurView: UIVisualEffectView!
    
    private var collectionView: UICollectionView!
    private var spinner: UIActivityIndicatorView!
    private var downloadTask: NSURLSessionDataTask?
    
    private var images: [UIImage]!
    private var imageURLs: [NSURL]!
    private var startIndex: Int?
    private var backgroundBlurStyle: UIBlurEffectStyle!
    
    public var didDismiss: (() -> Void)?
    public var didScroll: ((index: Int) -> Void)?
    
    private init(
        image: UIImage? = nil,
        imageURL: NSURL? = nil,
        images: [UIImage]? = nil,
        imageURLs: [NSURL]? = nil,
        startIndex: Int? = nil,
        backgroundBlurStyle: UIBlurEffectStyle? = .Dark) {

        self.images = images
        if let image = image {
            self.images = [image]
        }
        self.imageURLs = imageURLs
        if let imageURL = imageURL {
            self.imageURLs = [imageURL]
        }
            
        self.startIndex = startIndex
        self.backgroundBlurStyle = backgroundBlurStyle!
        super.init(nibName: nil, bundle: nil)
    }
    
    public convenience init(image: UIImage, backgroundBlurStyle: UIBlurEffectStyle? = .Dark) {
        self.init(image: image, imageURL: nil, backgroundBlurStyle: backgroundBlurStyle)
    }

    public convenience init(imageURL: NSURL, backgroundBlurStyle: UIBlurEffectStyle? = .Dark) {
        self.init(image: nil, imageURL: imageURL, backgroundBlurStyle: backgroundBlurStyle)
    }
    
    public convenience init(images: [UIImage], startIndex: Int? = nil, backgroundBlurStyle: UIBlurEffectStyle? = .Dark) {
        self.init(image: nil, images: images, startIndex: startIndex, backgroundBlurStyle: backgroundBlurStyle)
    }
    
    public convenience init(imageURLs: [NSURL], startIndex: Int? = nil, backgroundBlurStyle: UIBlurEffectStyle? = .Dark) {
        self.init(image: nil, imageURLs: imageURLs, startIndex: startIndex, backgroundBlurStyle: backgroundBlurStyle)
    }

    deinit {
        downloadTask?.cancel()
    }
    
    func downloadImage(url: NSURL, completion: (image: UIImage?) -> Void) {
        downloadTask = ImageDownloader.downloadImage(url) {
            [weak self] image in
            if let downloadedImage = image {
                completion(image: downloadedImage)
                self?.spinner.alpha = 0
            }
        }
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.autoresizingMask = .FlexibleHeight | .FlexibleWidth

        backgroundImageView = UIImageView(frame: view.bounds)
        backgroundImageView.image = backgroundSnapshot
        view.addSubview(backgroundImageView)
        
        blurView = UIVisualEffectView(effect: UIBlurEffect(style: backgroundBlurStyle))
        blurView.frame = view.bounds
        blurView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        view.addSubview(blurView)
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .Horizontal
        layout.itemSize = view.bounds.size
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.registerClass(AgrumeCell.self, forCellWithReuseIdentifier: Agrume.ReuseIdentifier)
        collectionView.dataSource = self
        collectionView.pagingEnabled = true
        collectionView.backgroundColor = UIColor.clearColor()
        collectionView.delaysContentTouches = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        view.addSubview(collectionView)
        
        if let index = startIndex {
            collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: .allZeros, animated: false)
        }

        let activityIndicatorStyle: UIActivityIndicatorViewStyle = backgroundBlurStyle == .Dark ? .WhiteLarge : .Gray
        spinner = UIActivityIndicatorView(activityIndicatorStyle: activityIndicatorStyle)
        spinner.center = view.center
        spinner.startAnimating()
        spinner.alpha = 0
        view.addSubview(spinner)
    }
    
    public func showFrom(viewController: UIViewController) {
        backgroundSnapshot = viewController.view.snapshot()
    
        view.userInteractionEnabled = false
        
        viewController.presentViewController(self, animated: false) {
            self.collectionView.alpha = 0
            self.collectionView.frame = self.view.bounds
            let scaling = Agrume.MaxScalingForExpandingOffscreen
            self.collectionView.transform = CGAffineTransformMakeScale(scaling, scaling)
            
            dispatch_async(dispatch_get_main_queue()) {
                UIView.animateWithDuration(Agrume.TransitionAnimationDuration,
                    delay: 0,
                    options: .BeginFromCurrentState | .CurveEaseInOut,
                    animations: {
                        [weak self] in
                        self?.collectionView.alpha = 1
                        self?.collectionView.transform = CGAffineTransformIdentity
                    },
                    completion: {
                        [weak self] finished in
                        self?.view.userInteractionEnabled = finished
                    }
                )
            }
        }
    }
    
}

extension Agrume: UICollectionViewDataSource {
    
    // MARK: UICollectionViewDataSource
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images?.count > 0 ? images.count : imageURLs.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        downloadTask?.cancel()
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Agrume.ReuseIdentifier, forIndexPath: indexPath) as! AgrumeCell

        if let images = self.images {
            cell.image = images[indexPath.row]
        } else if let imageURLs = self.imageURLs {
            spinner.alpha = 1
            downloadImage(imageURLs[indexPath.row]) {
                image in
                cell.image = image
            }
        }
        // Only allow panning if horizontal swiping fails. Horizontal swiping is only active for zoomed in images
        collectionView.panGestureRecognizer.requireGestureRecognizerToFail(cell.swipeGesture)
        cell.dismissAfterFlick = dismissAfterFlick()
        cell.dismissByExpanding = dismissByExpanding()
        return cell
    }

    func dismissAfterFlick() -> (() -> Void) {
        return {
            [weak self] in
            UIView.animateWithDuration(Agrume.TransitionAnimationDuration,
                delay: 0,
                options: .BeginFromCurrentState | .CurveEaseInOut,
                animations: {
                    self?.collectionView.alpha = 0
                    self?.blurView.alpha = 0
                },
                completion: {
                    _ in
                   self?.presentingViewController?.dismissViewControllerAnimated(false) {
                       self?.didDismiss?()
                   }
                }
            )
        }
    }

    func dismissByExpanding() -> (() -> Void) {
        return {
            [weak self] in
            self?.view.userInteractionEnabled = false

            UIView.animateWithDuration(Agrume.TransitionAnimationDuration,
                delay: 0,
                options: .BeginFromCurrentState | .CurveEaseInOut,
                animations: {
                    self?.collectionView.alpha = 0
                    self?.blurView.alpha = 0
                    let scaling = Agrume.MaxScalingForExpandingOffscreen
                    self?.collectionView.transform = CGAffineTransformMakeScale(scaling, scaling)
                },
                completion: {
                    _ in
                    self?.presentingViewController?.dismissViewControllerAnimated(false) {
                        self?.didDismiss?()
                    }
            })
        }
    }
    
}

extension Agrume: UICollectionViewDelegate, UIScrollViewDelegate {
    
    public func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        didScroll?(index: indexPath.row)
    }

}

