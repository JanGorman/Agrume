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
	func image(forIndex index: Int, completion: (UIImage?) -> Void)

}

public final class Agrume: UIViewController {

  private static let TransitionAnimationDuration: TimeInterval = 0.3
  private static let InitialScalingToExpandFrom: CGFloat = 0.6
  private static let MaxScalingForExpandingOffscreen: CGFloat = 1.25

  private static let ReuseIdentifier = "ReuseIdentifier"

  private var images: [UIImage]!
  private var imageURLs: [URL]!
  private var startIndex: Int?
  private let backgroundBlurStyle: UIBlurEffectStyle
  private let dataSource: AgrumeDataSource?

  public typealias DownloadCompletion = (image: UIImage?) -> Void
    
  public var didDismiss: (() -> Void)?
  public var didScroll: ((index: Int) -> Void)?
  public var download: ((url: URL, completion: DownloadCompletion) -> Void)?
  public var statusBarStyle: UIStatusBarStyle? {
    didSet {
      setNeedsStatusBarAppearanceUpdate()
    }
  }

  public convenience init(image: UIImage, backgroundBlurStyle: UIBlurEffectStyle? = .dark) {
      self.init(image: image, imageURL: nil, backgroundBlurStyle: backgroundBlurStyle)
  }

  public convenience init(imageURL: URL, backgroundBlurStyle: UIBlurEffectStyle? = .dark) {
      self.init(image: nil, imageURL: imageURL, backgroundBlurStyle: backgroundBlurStyle)
  }

	public convenience init(dataSource: AgrumeDataSource, startIndex: Int? = nil,
	                        backgroundBlurStyle: UIBlurEffectStyle? = .dark) {
		self.init(image: nil, images: nil, dataSource: dataSource, startIndex: startIndex,
		          backgroundBlurStyle: backgroundBlurStyle)
	}
	
  public convenience init(images: [UIImage], startIndex: Int? = nil, backgroundBlurStyle: UIBlurEffectStyle? = .dark) {
      self.init(image: nil, images: images, startIndex: startIndex, backgroundBlurStyle: backgroundBlurStyle)
  }

  public convenience init(imageURLs: [URL], startIndex: Int? = nil, backgroundBlurStyle: UIBlurEffectStyle? = .dark) {
      self.init(image: nil, imageURLs: imageURLs, startIndex: startIndex, backgroundBlurStyle: backgroundBlurStyle)
  }

	private init(image: UIImage? = nil, imageURL: URL? = nil, images: [UIImage]? = nil,
	             dataSource: AgrumeDataSource? = nil, imageURLs: [URL]? = nil, startIndex: Int? = nil,
	             backgroundBlurStyle: UIBlurEffectStyle? = .dark) {
    assert(backgroundBlurStyle != nil)
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
    
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()

    NotificationCenter.default.addObserver(self, selector: #selector(Agrume.orientationDidChange),
                                                     name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
  }

  deinit {
    downloadTask?.cancel()
    UIDevice.current.endGeneratingDeviceOrientationNotifications()
    NotificationCenter.default.removeObserver(self)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("Not implemented")
  }

  private func frameForCurrentDeviceOrientation() -> CGRect {
    let bounds = view.bounds
    if UIDeviceOrientationIsLandscape(currentDeviceOrientation()) {
      if bounds.width / bounds.height > bounds.height / bounds.width {
        return bounds
      } else {
        return CGRect(origin: bounds.origin, size: CGSize(width: bounds.height, height: bounds.width))
      }
    }
    return bounds
  }

  private func currentDeviceOrientation() -> UIDeviceOrientation {
    return UIDevice.current.orientation
  }

  private var backgroundSnapshot: UIImage!
  private var backgroundImageView: UIImageView!
  private lazy var blurContainerView: UIView = {
    let view = UIView(frame: self.view.frame)
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    return view
  }()
  private lazy var blurView: UIVisualEffectView = {
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: self.backgroundBlurStyle))
    blurView.frame = self.view.frame
    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    return blurView
  }()
  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = 0
    layout.minimumLineSpacing = 0
    layout.scrollDirection = .horizontal
    layout.itemSize = self.view.frame.size

    let collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
    collectionView.register(AgrumeCell.self, forCellWithReuseIdentifier: Agrume.ReuseIdentifier)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.isPagingEnabled = true
    collectionView.backgroundColor = UIColor.clear
    collectionView.delaysContentTouches = false
    collectionView.showsHorizontalScrollIndicator = false
    return collectionView
  }()
  private lazy var spinner: UIActivityIndicatorView = {
    let activityIndicatorStyle: UIActivityIndicatorViewStyle = self.backgroundBlurStyle == .dark ? .whiteLarge : .gray
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: activityIndicatorStyle)
    spinner.center = self.view.center
    spinner.startAnimating()
    spinner.alpha = 0
    return spinner
  }()
  private var downloadTask: URLSessionDataTask?

  override public func viewDidLoad() {
    super.viewDidLoad()
    view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    backgroundImageView = UIImageView(frame: view.frame)
    backgroundImageView.image = backgroundSnapshot
    view.addSubview(backgroundImageView)
    blurContainerView.addSubview(blurView)
    view.addSubview(blurContainerView)
    view.addSubview(collectionView)

    if let index = startIndex {
      collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: [],
                                             animated: false)
    }
    view.addSubview(spinner)
  }

  private var lastUsedOrientation: UIDeviceOrientation?

  public override func viewWillAppear(_ animated: Bool) {
    lastUsedOrientation = currentDeviceOrientation()
  }

  private func deviceOrientationFromStatusBarOrientation() -> UIDeviceOrientation {
    return UIDeviceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
  }

  private var initialOrientation: UIDeviceOrientation!

  public func showFrom(_ viewController: UIViewController, backgroundSnapshotVC: UIViewController? = .none) {
    backgroundSnapshot = (backgroundSnapshotVC ?? viewControllerForSnapshot(fromViewController: viewController))?.view.snapshot()
    view.frame = frameForCurrentDeviceOrientation()
    view.isUserInteractionEnabled = false
    initialOrientation = deviceOrientationFromStatusBarOrientation()
    updateLayoutsForCurrentOrientation()

    DispatchQueue.main.async {
      self.collectionView.alpha = 0
      self.collectionView.frame = self.view.frame
      let scaling = Agrume.InitialScalingToExpandFrom
      self.collectionView.transform = CGAffineTransform(scaleX: scaling, y: scaling)
  
      viewController.present(self, animated: false) {
        UIView.animate(withDuration: Agrume.TransitionAnimationDuration,
                                   delay: 0,
                                   options: .beginFromCurrentState,
                                   animations: { [weak self] in
                                      self?.collectionView.alpha = 1
                                      self?.collectionView.transform = .identity
                                   }, completion: { [weak self] finished in
                                      self?.view.isUserInteractionEnabled = finished
                                   })
        }
      }
  }

  private func viewControllerForSnapshot(fromViewController viewController: UIViewController) -> UIViewController? {
    var presentingVC = viewController.view.window?.rootViewController
    while presentingVC?.presentedViewController != nil {
      presentingVC = presentingVC?.presentedViewController
    }
    return presentingVC
  }

  public func dismiss() {
    self.dismissAfterFlick()
  }

  public func showImage(atIndex index : Int) {
    collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: [],
                                           animated: true)
  }

	public func reload() {
		DispatchQueue.main.async {
			self.collectionView.reloadData()
		}
	}

}

extension Agrume {

  // MARK: Rotation

  @objc private func orientationDidChange() {
    let orientation = currentDeviceOrientation()
    guard let lastOrientation = lastUsedOrientation else { return }
    let landscapeToLandscape = UIDeviceOrientationIsLandscape(orientation) && UIDeviceOrientationIsLandscape(lastOrientation)
    let portraitToPortrait = UIDeviceOrientationIsPortrait(orientation) && UIDeviceOrientationIsPortrait(lastOrientation)
    guard (landscapeToLandscape || portraitToPortrait) && orientation != lastUsedOrientation else { return }
    lastUsedOrientation = orientation
    UIView.animate(withDuration: 0.6) { [weak self] in
      self?.updateLayoutsForCurrentOrientation()
    }
  }

  public override func viewWillTransition(to size: CGSize,
                                                with coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animate(alongsideTransition: { [weak self] _ in
      self?.updateLayoutsForCurrentOrientation()
    }, completion: { [weak self] _ in
      self?.lastUsedOrientation = self?.deviceOrientationFromStatusBarOrientation()
    })
  }

  private func updateLayoutsForCurrentOrientation() {
    var transform = CGAffineTransform.identity
    if initialOrientation == .portrait {
      switch (currentDeviceOrientation()) {
      case .landscapeLeft:
        transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
      case .landscapeRight:
        transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
      case .portraitUpsideDown:
        transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
      default:
        break
      }
    } else if initialOrientation == .portraitUpsideDown {
      switch (currentDeviceOrientation()) {
      case .landscapeLeft:
        transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
      case .landscapeRight:
        transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
      case .portrait:
        transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
      default:
        break
      }
    } else if initialOrientation == .landscapeLeft {
      switch (currentDeviceOrientation()) {
      case .landscapeRight:
        transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
      case .portrait:
        transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
      case .portraitUpsideDown:
        transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
      default:
        break
      }
    } else if initialOrientation == .landscapeRight {
      switch (currentDeviceOrientation()) {
      case .landscapeLeft:
        transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
      case .portrait:
        transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
      case .portraitUpsideDown:
        transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
      default:
        break
      }
    }

    backgroundImageView.center = view.center
    backgroundImageView.transform = transform.concatenating(CGAffineTransform(scaleX: 1, y: 1))

    spinner.center = view.center

    collectionView.performBatchUpdates({ [unowned self] in
      self.collectionView.collectionViewLayout.invalidateLayout()
      self.collectionView.frame = self.view.frame
      let width = self.collectionView.frame.width
      let page = Int((self.collectionView.contentOffset.x + (0.5 * width)) / width)
      let updatedOffset = CGFloat(page) * self.collectionView.frame.width
      self.collectionView.contentOffset = CGPoint(x: updatedOffset, y: self.collectionView.contentOffset.y)

      let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
      layout.itemSize = self.view.frame.size
    }) { _ in
      for visibleCell in self.collectionView.visibleCells as! [AgrumeCell] {
        visibleCell.updateScrollViewAndImageViewForCurrentMetrics()
      }
    }
  }

}

extension Agrume: UICollectionViewDataSource {

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if let dataSource = self.dataSource {
      return dataSource.numberOfImages
    }
    return images?.count > 0 ? images.count : imageURLs.count
  }

  public func collectionView(_ collectionView: UICollectionView,
                             cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    downloadTask?.cancel()

    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Agrume.ReuseIdentifier,
                                                                     for: indexPath) as! AgrumeCell

    if let images = self.images {
      cell.image = images[(indexPath as NSIndexPath).row]
    } else if let imageURLs = self.imageURLs {
      spinner.alpha = 1
      let completion: DownloadCompletion = { [weak self] image in
        cell.image = image
        self?.spinner.alpha = 0
      }

      if let download = download {
        download(url: imageURLs[(indexPath as NSIndexPath).row], completion: completion)
      } else if let download = AgrumeServiceLocator.shared.downloadHandler {
        download(url: imageURLs[(indexPath as NSIndexPath).row], completion: completion)
      } else {
        downloadImage(imageURLs[(indexPath as NSIndexPath).row], completion: completion)
      }
		} else if let dataSource = self.dataSource {
			spinner.alpha = 1
			let index = (indexPath as NSIndexPath).row
			
        dataSource.image(forIndex: index) { [weak self] image in
        DispatchQueue.main.async {
          if collectionView.indexPathsForVisibleItems.contains(indexPath) {
            cell.image = image
            self?.spinner.alpha = 0
          }
        }
			}
		}
    // Only allow panning if horizontal swiping fails. Horizontal swiping is only active for zoomed in images
    collectionView.panGestureRecognizer.require(toFail: cell.swipeGesture)
    cell.delegate = self
    return cell
  }

  private func downloadImage(_ url: URL, completion: DownloadCompletion) {
    downloadTask = ImageDownloader.downloadImage(url) { image in
      completion(image: image)
    }
  }

}

extension Agrume: UICollectionViewDelegate {

  public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                             forItemAt indexPath: IndexPath) {
    didScroll?(index: (indexPath as NSIndexPath).row)
		
		if let dataSource = self.dataSource {
      let collectionViewCount = collectionView.numberOfItems(inSection: 0)
			let dataSourceCount = dataSource.numberOfImages
			
      // if dataSource hasn't changed the number of images then there is no need to reload (we assume that the same number shall result in the same data)
			guard collectionViewCount != dataSourceCount else { return }
			
			if (indexPath as NSIndexPath).row >= dataSourceCount { // if the dataSource number of images has been decreased and we got out of bounds
				showImage(atIndex: dataSourceCount - 1)
				reload()
			} else if (indexPath as NSIndexPath).row == collectionViewCount - 1 { // if we are at the last element of the collection but we are not out of bounds
				reload()
			}
		}
  }

}

extension Agrume: AgrumeCellDelegate {
  
  private func dismissCompletion(_ finished: Bool) {
    presentingViewController?.dismiss(animated: false) {
      self.didDismiss?()
    }
  }

  func dismissAfterFlick() {
    UIView.animate(withDuration: Agrume.TransitionAnimationDuration,
                               delay: 0,
                               options: .beginFromCurrentState,
                               animations: { [unowned self] in
                                self.collectionView.alpha = 0
                                self.blurContainerView.alpha = 0
      }, completion: dismissCompletion)
  }
  
  func dismissAfterTap() {
    view.isUserInteractionEnabled = false
    
    UIView.animate(withDuration: Agrume.TransitionAnimationDuration,
                               delay: 0,
                               options: .beginFromCurrentState,
                               animations: { [unowned self] in
                                self.collectionView.alpha = 0
                                self.blurContainerView.alpha = 0
                                let scaling = Agrume.MaxScalingForExpandingOffscreen
                                self.collectionView.transform = CGAffineTransform(scaleX: scaling, y: scaling)
      }, completion: dismissCompletion)
  }
}

extension Agrume {
  // MARK: Status Bar
    public override var preferredStatusBarStyle:  UIStatusBarStyle {
        return statusBarStyle ?? super.preferredStatusBarStyle
    }
}
