//
//  Agrume.swift
//  Agrume
//

import UIKit

public protocol AgrumeDataSource {
	
  /// The number of images contained in the data source
	var numberOfImages: Int { get }
  
  /// Return the image for the passed in image
  ///
  /// - Parameter index: The index (collection view item) being displayed
  /// - Parameter completion: The completion that returns the image to be shown at the index
	func imageForIndex(index: Int, completion: (UIImage?) -> Void)

}

public final class Agrume: UIViewController {

  private static let TransitionAnimationDuration: NSTimeInterval = 0.3
  private static let InitialScalingToExpandFrom: CGFloat = 0.6
  private static let MaxScalingForExpandingOffscreen: CGFloat = 1.25

  private static let ReuseIdentifier = "ReuseIdentifier"

  private var images: [UIImage]!
  private var imageURLs: [NSURL]!
  private var startIndex: Int?
  private var backgroundBlurStyle: UIBlurEffectStyle!
  private var dataSource: AgrumeDataSource?
    
  public typealias DownloadCompletion = (image: UIImage?) -> Void
    
  public var didDismiss: (() -> Void)?
  public var didScroll: ((index: Int) -> Void)?
  public var download: ((url: NSURL, completion: DownloadCompletion) -> Void)?

  public convenience init(image: UIImage, backgroundBlurStyle: UIBlurEffectStyle? = .Dark) {
      self.init(image: image, imageURL: nil, backgroundBlurStyle: backgroundBlurStyle)
  }

  public convenience init(imageURL: NSURL, backgroundBlurStyle: UIBlurEffectStyle? = .Dark) {
      self.init(image: nil, imageURL: imageURL, backgroundBlurStyle: backgroundBlurStyle)
  }

	public convenience init(dataSource: AgrumeDataSource, startIndex: Int? = nil, backgroundBlurStyle: UIBlurEffectStyle? = .Dark) {
		self.init(image: nil, images: nil, dataSource: dataSource, startIndex: startIndex, backgroundBlurStyle: backgroundBlurStyle)
	}
	
  public convenience init(images: [UIImage], startIndex: Int? = nil, backgroundBlurStyle: UIBlurEffectStyle? = .Dark) {
      self.init(image: nil, images: images, startIndex: startIndex, backgroundBlurStyle: backgroundBlurStyle)
  }

  public convenience init(imageURLs: [NSURL], startIndex: Int? = nil, backgroundBlurStyle: UIBlurEffectStyle? = .Dark) {
      self.init(image: nil, imageURLs: imageURLs, startIndex: startIndex, backgroundBlurStyle: backgroundBlurStyle)
  }

	private init(image: UIImage? = nil, imageURL: NSURL? = nil, images: [UIImage]? = nil, dataSource: AgrumeDataSource? = nil,
	             imageURLs: [NSURL]? = nil, startIndex: Int? = nil, backgroundBlurStyle: UIBlurEffectStyle? = .Dark) {
    self.images = images
    if let image = image {
      self.images = [image]
    }
    self.imageURLs = imageURLs
    if let imageURL = imageURL {
      self.imageURLs = [imageURL]
    }

		self.dataSource = dataSource
    self.startIndex = startIndex
    self.backgroundBlurStyle = backgroundBlurStyle!
    super.init(nibName: nil, bundle: nil)

    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Agrume.orientationDidChange),
                                                     name: UIDeviceOrientationDidChangeNotification, object: nil)
  }

  deinit {
    downloadTask?.cancel()
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  private var backgroundSnapshot: UIImage!
  private var backgroundImageView: UIImageView!
  private lazy var blurContainerView: UIView = {
    let view = UIView(frame: self.view.bounds)
    view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    return view
  }()
  private lazy var blurView: UIVisualEffectView = {
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: self.backgroundBlurStyle))
    blurView.frame = self.view.bounds
    blurView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    return blurView
  }()
  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = 0
    layout.minimumLineSpacing = 0
    layout.scrollDirection = .Horizontal
    layout.itemSize = self.view.bounds.size

    let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
    collectionView.registerClass(AgrumeCell.self, forCellWithReuseIdentifier: Agrume.ReuseIdentifier)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.pagingEnabled = true
    collectionView.backgroundColor = UIColor.clearColor()
    collectionView.delaysContentTouches = false
    collectionView.showsHorizontalScrollIndicator = false
    return collectionView
  }()
  private lazy var spinner: UIActivityIndicatorView = {
    let activityIndicatorStyle: UIActivityIndicatorViewStyle = self.backgroundBlurStyle == .Dark ? .WhiteLarge : .Gray
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: activityIndicatorStyle)
    spinner.center = self.view.center
    spinner.startAnimating()
    spinner.alpha = 0
    return spinner
  }()
  private var downloadTask: NSURLSessionDataTask?

  override public func viewDidLoad() {
    super.viewDidLoad()

    view.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
    backgroundImageView = UIImageView(frame: view.bounds)
    backgroundImageView.image = backgroundSnapshot
    view.addSubview(backgroundImageView)
    blurContainerView.addSubview(blurView)
    view.addSubview(blurContainerView)
    view.addSubview(collectionView)

    if let index = startIndex {
      collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: [],
                                             animated: false)
    }
    view.addSubview(spinner)
  }

  private var lastUsedOrientation: UIDeviceOrientation?

  public override func viewWillAppear(animated: Bool) {
      lastUsedOrientation = UIDeviceOrientation(rawValue: UIApplication.sharedApplication().statusBarOrientation.rawValue)
  }

  private var initialOrientation: UIDeviceOrientation!

  public func showFrom(viewController: UIViewController) {
      backgroundSnapshot = UIApplication.sharedApplication().delegate?.window??.rootViewController?.view.snapshot()

      view.userInteractionEnabled = false
      initialOrientation = UIDeviceOrientation(rawValue: UIApplication.sharedApplication().statusBarOrientation.rawValue)
  
      dispatch_async(dispatch_get_main_queue()) {
        self.collectionView.alpha = 0
        self.collectionView.frame = self.view.bounds
        let scaling = Agrume.InitialScalingToExpandFrom
        self.collectionView.transform = CGAffineTransformMakeScale(scaling, scaling)
    
        viewController.presentViewController(self, animated: false) {
          UIView.animateWithDuration(Agrume.TransitionAnimationDuration,
                                     delay: 0,
                                     options: [.BeginFromCurrentState, .CurveEaseInOut],
                                     animations: {
                                      [weak self] in
                                      self?.collectionView.alpha = 1
                                      self?.collectionView.transform = CGAffineTransformIdentity
                                     }, completion: {
                                      [weak self] finished in
                                      self?.view.userInteractionEnabled = finished
                                     })
          }
        }
  }

  public func dismiss() {
      self.dismissAfterFlick()
  }

  public func showImageAtIndex(index : Int) {
    collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: [],
                                           animated: true)
  }

	public func reload() {
		dispatch_async (dispatch_get_main_queue()) {
			self.collectionView.reloadData()
		}
	}

}

extension Agrume {

  // MARK: Rotation

  func orientationDidChange() {
    let orientation = UIDevice.currentDevice().orientation
    guard let lastOrientation = lastUsedOrientation else { return }
    let landscapeToLandscape = UIDeviceOrientationIsLandscape(orientation) && UIDeviceOrientationIsLandscape(lastOrientation)
    let portraitToPortrait = UIDeviceOrientationIsPortrait(orientation) && UIDeviceOrientationIsPortrait(lastOrientation)
    guard (landscapeToLandscape || portraitToPortrait) && orientation != lastUsedOrientation else { return }
    lastUsedOrientation = orientation
    UIView.animateWithDuration(0.6) {
      [weak self] in
      self?.updateLayoutsForCurrentOrientation()
    }
  }

  public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator
    coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animateAlongsideTransition({ [weak self] _ in
      self?.updateLayoutsForCurrentOrientation()
    }) { [weak self] _ in
      let statusBarOrientation = UIApplication.sharedApplication().statusBarOrientation.rawValue
      self?.lastUsedOrientation = UIDeviceOrientation(rawValue: statusBarOrientation)
    }
  }

  func updateLayoutsForCurrentOrientation() {
    var transform = CGAffineTransformIdentity
    if initialOrientation == .Portrait {
      switch (UIApplication.sharedApplication().statusBarOrientation) {
      case .LandscapeLeft:
        transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
      case .LandscapeRight:
        transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
      case .PortraitUpsideDown:
        transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
      default:
          break
      }
    } else if initialOrientation == .PortraitUpsideDown {
      switch (UIApplication.sharedApplication().statusBarOrientation) {
      case .LandscapeLeft:
        transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
      case .LandscapeRight:
        transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
      case .Portrait:
        transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
      default:
        break
      }
    } else if initialOrientation == .LandscapeLeft {
      switch (UIApplication.sharedApplication().statusBarOrientation) {
      case .LandscapeRight:
        transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
      case .Portrait:
        transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
      case .PortraitUpsideDown:
        transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
      default:
        break
      }
    } else if initialOrientation == .LandscapeRight {
      switch (UIApplication.sharedApplication().statusBarOrientation) {
      case .LandscapeLeft:
        transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
      case .Portrait:
        transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
      case .PortraitUpsideDown:
        transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
      default:
        break
      }
    }

    backgroundImageView.center = view.center
    backgroundImageView.transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(1, 1))

    spinner.center = view.center
    collectionView.frame = view.bounds

    let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    layout.itemSize = view.bounds.size
    layout.invalidateLayout()
    // Apply update two runloops into the future
    dispatch_async(dispatch_get_main_queue()) {
      dispatch_async(dispatch_get_main_queue()) { [unowned self] in
        for visibleCell in self.collectionView.visibleCells() as! [AgrumeCell] {
          visibleCell.updateScrollViewAndImageViewForCurrentMetrics()
        }
      }
    }
  }

}

extension Agrume: UICollectionViewDataSource {

  public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if let dataSource = self.dataSource {
      return dataSource.numberOfImages
    }
    return images?.count > 0 ? images.count : imageURLs.count
  }

  public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    downloadTask?.cancel()

    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Agrume.ReuseIdentifier, forIndexPath: indexPath) as! AgrumeCell

    if let images = self.images {
      cell.image = images[indexPath.row]
    } else if let imageURLs = self.imageURLs {
      spinner.alpha = 1
      let completion: DownloadCompletion = { [weak self] image in
        cell.image = image
        self?.spinner.alpha = 0
      }

      if let download = download {
        download(url: imageURLs[indexPath.row], completion: completion)
      } else {
        downloadImage(imageURLs[indexPath.row], completion: completion)
      }
		} else if let dataSource = self.dataSource {
			spinner.alpha = 1
			let index = indexPath.row
			
			dataSource.imageForIndex(index) { [weak self] image in
        dispatch_async(dispatch_get_main_queue()) {
          if collectionView.indexPathsForVisibleItems().contains(indexPath) {
            cell.image = image
            self?.spinner.alpha = 0
          }
        }
			}
		}
    // Only allow panning if horizontal swiping fails. Horizontal swiping is only active for zoomed in images
    collectionView.panGestureRecognizer.requireGestureRecognizerToFail(cell.swipeGesture)
    cell.dismissAfterFlick = dismissAfterFlick
    cell.dismissByExpanding = dismissByExpanding
    return cell
  }

  private func downloadImage(url: NSURL, completion: DownloadCompletion) {
    downloadTask = ImageDownloader.downloadImage(url) { image in
      completion(image: image)
    }
  }

  private func dismissAfterFlick() {
    UIView.animateWithDuration(Agrume.TransitionAnimationDuration,
                               delay: 0,
                               options: [.BeginFromCurrentState, .CurveEaseInOut],
                               animations: {
                                self.collectionView.alpha = 0
                                self.blurContainerView.alpha = 0
                               }, completion: dismissCompletion)
  }

  private func dismissByExpanding() {
    view.userInteractionEnabled = false

    UIView.animateWithDuration(Agrume.TransitionAnimationDuration,
                               delay: 0,
                               options: [.BeginFromCurrentState, .CurveEaseInOut],
                               animations: {
                                self.collectionView.alpha = 0
                                self.blurContainerView.alpha = 0
                                let scaling = Agrume.MaxScalingForExpandingOffscreen
                                self.collectionView.transform = CGAffineTransformMakeScale(scaling, scaling)
                               }, completion: dismissCompletion)
  }
  
  private func dismissCompletion(finished: Bool) {
    presentingViewController?.dismissViewControllerAnimated(false) {
      self.didDismiss?()
    }
  }

}

extension Agrume: UICollectionViewDelegate {

  public func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell,
                             forItemAtIndexPath indexPath: NSIndexPath) {
    didScroll?(index: indexPath.row)
		
		if let dataSource = self.dataSource {
      let collectionViewCount = collectionView.numberOfItemsInSection(0)
			let dataSourceCount = dataSource.numberOfImages
			
      // if dataSource hasn't changed the number of images then there is no need to reload (we assume that the same number shall result in the same data)
			guard collectionViewCount != dataSourceCount else { return }
			
			if indexPath.row >= dataSourceCount { // if the dataSource number of images has been decreased and we got out of bounds
				showImageAtIndex(dataSourceCount - 1)
				reload()
			} else if indexPath.row == collectionViewCount - 1 { // if we are at the last element of the collection but we are not out of bounds
				reload()
			}
		}
  }

}
