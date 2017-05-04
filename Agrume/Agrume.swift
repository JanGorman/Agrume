//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import UIKit

public protocol AgrumeDataSource {
	
  /// The number of images contained in the data source
	var numberOfImages: Int { get }
  
  /// Return the image for the passed in index
  ///
  /// - Parameter index: The index (collection view item) being displayed
  /// - Parameter completion: The completion that returns the image to be shown at the index
	func image(forIndex index: Int, completion: (UIImage?) -> Void)

}

public final class Agrume: UIViewController {

  fileprivate static let transitionAnimationDuration: TimeInterval = 0.3
  fileprivate static let initialScalingToExpandFrom: CGFloat = 0.6
  fileprivate static let maxScalingForExpandingOffscreen: CGFloat = 1.25
  fileprivate static let reuseIdentifier = "reuseIdentifier"

  fileprivate var images: [UIImage]!
  fileprivate var imageUrls: [URL]!
  private var startIndex: Int?
  private let backgroundBlurStyle: UIBlurEffectStyle?
  private let backgroundColor: UIColor?
  fileprivate let dataSource: AgrumeDataSource?

  public typealias DownloadCompletion = (_ image: UIImage?) -> Void
  
  /// Optional closure to call whenever Agrume is dismissed.
  public var didDismiss: (() -> Void)?
  /// Optional closure to call whenever Agrume scrolls to the next image in a collection. Passes the "page" index
  public var didScroll: ((_ index: Int) -> Void)?
  /// An optional download handler. Passed the URL that is supposed to be loaded. Call the completion with the image
  /// when the download is done.
  public var download: ((_ url: URL, _ completion: @escaping DownloadCompletion) -> Void)?
  /// Status bar style when presenting
  public var statusBarStyle: UIStatusBarStyle? {
    didSet {
      setNeedsStatusBarAppearanceUpdate()
    }
  }
  /// Hide status bar when presenting. Defaults to `false`
  public var hideStatusBar: Bool = false

  /// Initialize with a single image
  ///
  /// - Parameter image: The image to present
  /// - Parameter backgroundBlurStyle: The UIBlurEffectStyle to apply to the background when presenting
  /// - Parameter backgroundColor: The background color when presenting
  public convenience init(image: UIImage, backgroundBlurStyle: UIBlurEffectStyle? = nil, backgroundColor: UIColor? = nil) {
    self.init(image: image, imageUrl: nil, backgroundBlurStyle: backgroundBlurStyle, backgroundColor: backgroundColor)
  }

  /// Initialize with a single image url
  ///
  /// - Parameter imageUrl: The image url to present
  /// - Parameter backgroundBlurStyle: The UIBlurEffectStyle to apply to the background when presenting
  /// - Parameter backgroundColor: The background color when presenting
  public convenience init(imageUrl: URL, backgroundBlurStyle: UIBlurEffectStyle? = .dark, backgroundColor: UIColor? = nil) {
    self.init(image: nil, imageUrl: imageUrl, backgroundBlurStyle: backgroundBlurStyle, backgroundColor: backgroundColor)
  }

  /// Initialize with a data source
  ///
  /// - Parameter dataSource: The `AgrumeDataSource` to use
  /// - Parameter startIndex: The optional start index when showing multiple images
  /// - Parameter backgroundBlurStyle: The UIBlurEffectStyle to apply to the background when presenting
  /// - Parameter backgroundColor: The background color when presenting
	public convenience init(dataSource: AgrumeDataSource, startIndex: Int? = nil,
	                        backgroundBlurStyle: UIBlurEffectStyle? = .dark, backgroundColor: UIColor? = nil) {
		self.init(image: nil, images: nil, dataSource: dataSource, startIndex: startIndex,
		          backgroundBlurStyle: backgroundBlurStyle, backgroundColor: backgroundColor)
	}
	
  /// Initialize with an array of images
  ///
  /// - Parameter images: The images to present
  /// - Parameter startIndex: The optional start index when showing multiple images
  /// - Parameter backgroundBlurStyle: The UIBlurEffectStyle to apply to the background when presenting
  /// - Parameter backgroundColor: The background color when presenting
  public convenience init(images: [UIImage], startIndex: Int? = nil, backgroundBlurStyle: UIBlurEffectStyle? = .dark,
                          backgroundColor: UIColor? = nil) {
    self.init(image: nil, images: images, startIndex: startIndex, backgroundBlurStyle: backgroundBlurStyle,
              backgroundColor: backgroundColor)
  }

  /// Initialize with an array of image urls
  ///
  /// - Parameter imageUrls: The image urls to present
  /// - Parameter startIndex: The optional start index when showing multiple images
  /// - Parameter backgroundBlurStyle: The UIBlurEffectStyle to apply to the background when presenting
  /// - Parameter backgroundColor: The background color when presenting
  public convenience init(imageUrls: [URL], startIndex: Int? = nil, backgroundBlurStyle: UIBlurEffectStyle? = .dark,
                          backgroundColor: UIColor? = nil) {
    self.init(image: nil, imageUrls: imageUrls, startIndex: startIndex, backgroundBlurStyle: backgroundBlurStyle,
              backgroundColor: backgroundColor)
  }

	private init(image: UIImage? = nil, imageUrl: URL? = nil, images: [UIImage]? = nil,
	             dataSource: AgrumeDataSource? = nil, imageUrls: [URL]? = nil, startIndex: Int? = nil,
	             backgroundBlurStyle: UIBlurEffectStyle? = nil, backgroundColor: UIColor? = nil) {
    switch (backgroundBlurStyle, backgroundColor) {
    case (let blur, .none):
      self.backgroundBlurStyle = blur
      self.backgroundColor = nil
    case (.none, let color):
      self.backgroundColor = color
      self.backgroundBlurStyle = nil
    default:
      self.backgroundBlurStyle = .dark
      self.backgroundColor = nil
    }

    self.images = images
    if let image = image {
      self.images = [image]
    }
    self.imageUrls = imageUrls
    if let imageURL = imageUrl {
      self.imageUrls = [imageURL]
    }

		self.dataSource = dataSource
    self.startIndex = startIndex
    super.init(nibName: nil, bundle: nil)
    
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange),
                                           name: .UIDeviceOrientationDidChange, object: nil)
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
  fileprivate var _blurContainerView: UIView?
  fileprivate var blurContainerView: UIView {
    if _blurContainerView == nil {
      let view = UIView(frame: self.view.frame)
      view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      view.backgroundColor = backgroundColor ?? .clear
      _blurContainerView = view
    }
    return _blurContainerView!
  }
  fileprivate var _blurView: UIVisualEffectView?
  private var blurView: UIVisualEffectView {
    if _blurView == nil {
      let blurView = UIVisualEffectView(effect: UIBlurEffect(style: self.backgroundBlurStyle!))
      blurView.frame = self.view.frame
      blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      _blurView = blurView
    }
    return _blurView!
  }
  fileprivate var _collectionView: UICollectionView?
  fileprivate var collectionView: UICollectionView {
    if _collectionView == nil {
      let layout = UICollectionViewFlowLayout()
      layout.minimumInteritemSpacing = 0
      layout.minimumLineSpacing = 0
      layout.scrollDirection = .horizontal
      layout.itemSize = self.view.frame.size
      
      let collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
      collectionView.register(AgrumeCell.self, forCellWithReuseIdentifier: Agrume.reuseIdentifier)
      collectionView.dataSource = self
      collectionView.delegate = self
      collectionView.isPagingEnabled = true
      collectionView.backgroundColor = .clear
      collectionView.delaysContentTouches = false
      collectionView.showsHorizontalScrollIndicator = false
      _collectionView = collectionView
    }
    return _collectionView!
  }
  fileprivate var _spinner: UIActivityIndicatorView?
  fileprivate var spinner: UIActivityIndicatorView {
    if _spinner == nil {
      let activityIndicatorStyle: UIActivityIndicatorViewStyle = self.backgroundBlurStyle == .dark ? .whiteLarge : .gray
      let spinner = UIActivityIndicatorView(activityIndicatorStyle: activityIndicatorStyle)
      spinner.center = self.view.center
      spinner.startAnimating()
      spinner.alpha = 0
      _spinner = spinner
    }
    return _spinner!
  }
  fileprivate var downloadTask: URLSessionDataTask?

  override public func viewDidLoad() {
    super.viewDidLoad()
    view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    backgroundImageView = UIImageView(frame: view.frame)
    backgroundImageView.image = backgroundSnapshot
    view.addSubview(backgroundImageView)
  }

  private var lastUsedOrientation: UIDeviceOrientation?

  public override func viewWillAppear(_ animated: Bool) {
    lastUsedOrientation = currentDeviceOrientation()
  }

  fileprivate func deviceOrientationFromStatusBarOrientation() -> UIDeviceOrientation {
    return UIDeviceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
  }

  fileprivate var initialOrientation: UIDeviceOrientation!

  public func showFrom(_ viewController: UIViewController, backgroundSnapshotVC: UIViewController? = nil) {
    backgroundSnapshot = (backgroundSnapshotVC ?? viewControllerForSnapshot(fromViewController: viewController))?.view.snapshot()
    view.frame = frameForCurrentDeviceOrientation()
    view.isUserInteractionEnabled = false
    addSubviews()
    initialOrientation = deviceOrientationFromStatusBarOrientation()
    updateLayoutsForCurrentOrientation()
    showFrom(viewController)
  }
  
  private func addSubviews() {
    if backgroundBlurStyle != nil {
      blurContainerView.addSubview(blurView)
    }
    view.addSubview(blurContainerView)
    view.addSubview(collectionView)
    if let index = startIndex {
      collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: [], animated: false)
    }
    view.addSubview(spinner)
  }
  
  private func showFrom(_ viewController: UIViewController) {
    DispatchQueue.main.async {
      self.blurContainerView.alpha = 1
      self.collectionView.alpha = 0
      self.collectionView.frame = self.view.frame
      let scaling = Agrume.initialScalingToExpandFrom
      self.collectionView.transform = CGAffineTransform(scaleX: scaling, y: scaling)
      
      viewController.present(self, animated: false) {
        UIView.animate(withDuration: Agrume.transitionAnimationDuration,
                       delay: 0,
                       options: .beginFromCurrentState,
                       animations: { [weak self] in
                        self?.collectionView.alpha = 1
                        self?.collectionView.transform = .identity
          }, completion: { [weak self] _ in
            self?.view.isUserInteractionEnabled = true
          })
      }
    }
  }

  fileprivate func viewControllerForSnapshot(fromViewController viewController: UIViewController) -> UIViewController? {
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
    collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: [], animated: true)
  }

	public func reload() {
		DispatchQueue.main.async {
			self.collectionView.reloadData()
		}
	}
  
  public override var prefersStatusBarHidden: Bool {
    return hideStatusBar
  }

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

  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animate(alongsideTransition: { [weak self] _ in
      self?.updateLayoutsForCurrentOrientation()
    }, completion: { [weak self] _ in
      self?.lastUsedOrientation = self?.deviceOrientationFromStatusBarOrientation()
    })
  }

  private func updateLayoutsForCurrentOrientation() {
    let transform = newTransform()

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
      }, completion: { _ in
        for visibleCell in self.collectionView.visibleCells as! [AgrumeCell] {
          visibleCell.updateScrollViewAndImageViewForCurrentMetrics()
        }
    })
  }
  
  private func newTransform() -> CGAffineTransform {
    var transform: CGAffineTransform = .identity
    if initialOrientation == .portrait {
      switch (currentDeviceOrientation()) {
      case .landscapeLeft:
        transform = CGAffineTransform(rotationAngle: .pi / 2)
      case .landscapeRight:
        transform = CGAffineTransform(rotationAngle: -(.pi / 2))
      case .portraitUpsideDown:
        transform = CGAffineTransform(rotationAngle: .pi)
      default:
        break
      }
    } else if initialOrientation == .portraitUpsideDown {
      switch (currentDeviceOrientation()) {
      case .landscapeLeft:
        transform = CGAffineTransform(rotationAngle: -(.pi / 2))
      case .landscapeRight:
        transform = CGAffineTransform(rotationAngle: .pi / 2)
      case .portrait:
        transform = CGAffineTransform(rotationAngle: .pi)
      default:
        break
      }
    } else if initialOrientation == .landscapeLeft {
      switch (currentDeviceOrientation()) {
      case .landscapeRight:
        transform = CGAffineTransform(rotationAngle: .pi)
      case .portrait:
        transform = CGAffineTransform(rotationAngle: -(.pi / 2))
      case .portraitUpsideDown:
        transform = CGAffineTransform(rotationAngle: .pi / 2)
      default:
        break
      }
    } else if initialOrientation == .landscapeRight {
      switch (currentDeviceOrientation()) {
      case .landscapeLeft:
        transform = CGAffineTransform(rotationAngle: .pi)
      case .portrait:
        transform = CGAffineTransform(rotationAngle: .pi / 2)
      case .portraitUpsideDown:
        transform = CGAffineTransform(rotationAngle: -(.pi / 2))
      default:
        break
      }
    }
    return transform
  }

}

extension Agrume: UICollectionViewDataSource {

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if let dataSource = dataSource {
      return dataSource.numberOfImages
    }
    if let images = images {
      return !images.isEmpty ? images.count : imageUrls.count
    }
    return imageUrls.count
  }

  public func collectionView(_ collectionView: UICollectionView,
                             cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Agrume.reuseIdentifier,
                                                  for: indexPath) as! AgrumeCell
    if let images = images {
      cell.image = images[indexPath.row]
		} else if let dataSource = dataSource {
			spinner.alpha = 1
			let index = indexPath.row
			
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



}

extension Agrume: UICollectionViewDelegate {

  public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                             forItemAt indexPath: IndexPath) {
    didScroll?(indexPath.row)
    
    if let imageUrls = imageUrls {
      let completion: DownloadCompletion = { [weak self] image in
        (cell as! AgrumeCell).image = image
        self?.spinner.alpha = 0
      }
      
      if let download = download {
        download(imageUrls[indexPath.row], completion)
      } else if let download = AgrumeServiceLocator.shared.downloadHandler {
        spinner.alpha = 1
        download(imageUrls[indexPath.row], completion)
      } else {
        spinner.alpha = 1
        downloadImage(imageUrls[indexPath.row], completion: completion)
      }
    }
		
		if let dataSource = dataSource {
      let collectionViewCount = collectionView.numberOfItems(inSection: 0)
			let dataSourceCount = dataSource.numberOfImages
			
			guard !hasDataSourceCountChanged(dataSourceCount: dataSourceCount, collectionViewCount: collectionViewCount)
        else { return }
			
			if isIndexPathOutOfBounds(indexPath, count: dataSourceCount) {
				showImage(atIndex: dataSourceCount - 1)
				reload()
			} else if isLastElement(atIndexPath: indexPath, count: collectionViewCount - 1) {
				reload()
			}
		}
  }
  
  private func downloadImage(_ url: URL, completion: @escaping DownloadCompletion) {
    downloadTask = ImageDownloader.downloadImage(url) { image in
      completion(image)
    }
  }
  
  private func hasDataSourceCountChanged(dataSourceCount: Int, collectionViewCount: Int) -> Bool {
    return collectionViewCount == dataSourceCount
  }
  
  private func isIndexPathOutOfBounds(_ indexPath: IndexPath, count: Int) -> Bool {
    return indexPath.item >= count
  }
  
  private func isLastElement(atIndexPath indexPath: IndexPath, count: Int) -> Bool {
    return indexPath.item == count
  }

}

extension Agrume: AgrumeCellDelegate {
  
  private func dismissCompletion(_ finished: Bool) {
    presentingViewController?.dismiss(animated: false) { [unowned self] in
      self.cleanup()
      self.didDismiss?()
    }
  }
  
  private func cleanup() {
    _blurContainerView?.removeFromSuperview()
    _blurContainerView = nil
    _blurView = nil
    _collectionView?.removeFromSuperview()
    _collectionView = nil
    _spinner?.removeFromSuperview()
    _spinner = nil
  }

  func dismissAfterFlick() {
    UIView.animate(withDuration: Agrume.transitionAnimationDuration,
                   delay: 0,
                   options: .beginFromCurrentState,
                   animations: { [unowned self] in
                    self.collectionView.alpha = 0
                    self.blurContainerView.alpha = 0
      }, completion: dismissCompletion)
  }
  
  func dismissAfterTap() {
    view.isUserInteractionEnabled = false
    
    UIView.animate(withDuration: Agrume.transitionAnimationDuration,
                   delay: 0,
                   options: .beginFromCurrentState,
                   animations: { [unowned self] in
                    self.collectionView.alpha = 0
                    self.blurContainerView.alpha = 0
                    let scaling = Agrume.maxScalingForExpandingOffscreen
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
