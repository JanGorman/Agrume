//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import UIKit

public final class Agrume: UIViewController {

  private static let transitionAnimationDuration: TimeInterval = 0.3
  private static let initialScalingToExpandFrom: CGFloat = 0.6
  private static let maxScalingForExpandingOffscreen: CGFloat = 1.25
  private static let reuseIdentifier = "reuseIdentifier"

  private var images: [AgrumeImage]!
  private let startIndex: Int
  private let backgroundBlurStyle: UIBlurEffectStyle?
  private let backgroundColor: UIColor?
  
  private weak var dataSource: AgrumeDataSource?

  public typealias DownloadCompletion = (_ image: UIImage?) -> Void
  
  /// Optional closure to call whenever Agrume is dismissed.
  public var didDismiss: (() -> Void)?
  /// Optional closure to call whenever Agrume scrolls to the next image in a collection. Passes the "page" index
  public var didScroll: ((_ index: Int) -> Void)?
  /// An optional download handler. Passed the URL that is supposed to be loaded. Call the completion with the image
  /// when the download is done.
  public var addownload: ((_ url: URL, _ completion: @escaping DownloadCompletion) -> Void)?
  /// Status bar style when presenting
  public var statusBarStyle: UIStatusBarStyle? {
    didSet {
      setNeedsStatusBarAppearanceUpdate()
    }
  }
  /// Hide status bar when presenting. Defaults to `false`
  public var hideStatusBar = false

  /// Initialize with a single image
  ///
  /// - Parameter image: The image to present
  /// - Parameter backgroundBlurStyle: The UIBlurEffectStyle to apply to the background when presenting
  /// - Parameter backgroundColor: The background color when presenting
  public convenience init(image: UIImage, backgroundBlurStyle: UIBlurEffectStyle? = nil, backgroundColor: UIColor? = nil) {
    self.init(images: [image], backgroundBlurStyle: backgroundBlurStyle, backgroundColor: backgroundColor)
  }

  /// Initialize with a single image url
  ///
  /// - Parameter imageUrl: The image url to present
  /// - Parameter backgroundBlurStyle: The UIBlurEffectStyle to apply to the background when presenting
  /// - Parameter backgroundColor: The background color when presenting
  public convenience init(imageUrl: URL, backgroundBlurStyle: UIBlurEffectStyle? = .dark, backgroundColor: UIColor? = nil) {
    self.init(urls: [imageUrl], backgroundBlurStyle: backgroundBlurStyle, backgroundColor: backgroundColor)
  }

  /// Initialize with a data source
  ///
  /// - Parameter dataSource: The `AgrumeDataSource` to use
  /// - Parameter startIndex: The optional start index when showing multiple images
  /// - Parameter backgroundBlurStyle: The UIBlurEffectStyle to apply to the background when presenting
  /// - Parameter backgroundColor: The background color when presenting
	public convenience init(dataSource: AgrumeDataSource, startIndex: Int? = nil,
	                        backgroundBlurStyle: UIBlurEffectStyle? = .dark, backgroundColor: UIColor? = nil) {
		self.init(dataSource: dataSource, startIndex: startIndex,
		          backgroundBlurStyle: backgroundBlurStyle, backgroundColor: backgroundColor)
	}
	
  /// Initialize with an array of images
  ///
  /// - Parameter images: The images to present
  /// - Parameter startIndex: The optional start index when showing multiple images
  /// - Parameter backgroundBlurStyle: The UIBlurEffectStyle to apply to the background when presenting
  /// - Parameter backgroundColor: The background color when presenting
  public convenience init(images: [UIImage], startIndex: Int = 0, backgroundBlurStyle: UIBlurEffectStyle? = .dark,
                          backgroundColor: UIColor? = nil) {
    self.init(images: images, urls: nil, startIndex: startIndex, backgroundBlurStyle: backgroundBlurStyle, backgroundColor: backgroundColor)
  }

  /// Initialize with an array of image urls
  ///
  /// - Parameter imageUrls: The image urls to present
  /// - Parameter startIndex: The optional start index when showing multiple images
  /// - Parameter backgroundBlurStyle: The UIBlurEffectStyle to apply to the background when presenting
  /// - Parameter backgroundColor: The background color when presenting
  public convenience init(urls: [URL], startIndex: Int = 0, backgroundBlurStyle: UIBlurEffectStyle? = .dark,
                          backgroundColor: UIColor? = nil) {
    self.init(images: nil, urls: urls, startIndex: startIndex, backgroundBlurStyle: backgroundBlurStyle,
              backgroundColor: backgroundColor)
  }

	private init(images: [UIImage]? = nil, urls: [URL]? = nil, dataSource: AgrumeDataSource? = nil, startIndex: Int = 0,
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

    switch (images, urls) {
    case (let images?, nil):
      self.images = images.map { AgrumeImage(image: $0) }
    case (_, let urls?):
      self.images = urls.map { AgrumeImage(url: $0) }
    default:
      assert(dataSource != nil, "No images or URLs passed. You must provide an AgrumeDataSource in that case.")
      break
    }
    
//    self.images = images
//    if let image = image {
//      self.images = [image]
//    }
//    self.imageUrls = imageUrls
//    if let imageURL = imageUrl {
//      self.imageUrls = [imageURL]
//    }
		
    self.startIndex = startIndex
    super.init(nibName: nil, bundle: nil)
    
    self.dataSource = dataSource ?? self
  }

  deinit {
    downloadTask?.cancel()
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
  private var _blurContainerView: UIView?
  private var blurContainerView: UIView {
    if _blurContainerView == nil {
      let view = UIView(frame: self.view.frame)
      view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      view.backgroundColor = backgroundColor ?? .clear
      _blurContainerView = view
    }
    return _blurContainerView!
  }
  private var _blurView: UIVisualEffectView?
  private var blurView: UIVisualEffectView {
    if _blurView == nil {
      let blurView = UIVisualEffectView(effect: UIBlurEffect(style: self.backgroundBlurStyle!))
      blurView.frame = self.view.frame
      blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      _blurView = blurView
    }
    return _blurView!
  }
  private var _collectionView: UICollectionView?
  private var collectionView: UICollectionView {
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
  private var _spinner: UIActivityIndicatorView?
  private var spinner: UIActivityIndicatorView {
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
  private var downloadTask: URLSessionDataTask?

  override public func viewDidLoad() {
    super.viewDidLoad()
    view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    backgroundImageView = UIImageView(frame: view.frame)
    backgroundImageView.image = backgroundSnapshot
    view.addSubview(backgroundImageView)
  }

  private var lastUsedOrientation: UIDeviceOrientation?

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    lastUsedOrientation = currentDeviceOrientation()
  }

  private func deviceOrientationFromStatusBarOrientation() -> UIDeviceOrientation {
    return UIDeviceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
  }

  private var initialOrientation: UIDeviceOrientation!

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
    if startIndex > 0 {
      collectionView.scrollToItem(at: IndexPath(item: startIndex, section: 0), at: [], animated: false)
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
    collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: [], animated: true)
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
      
      let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout
      layout?.itemSize = self.view.frame.size
    }, completion: { _ in
      for visibleCell in self.collectionView.visibleCells as! [AgrumeCell] {
        visibleCell.updateScrollViewAndImageViewForCurrentMetrics()
      }
    })
  }
  
  private func newTransform() -> CGAffineTransform {
    switch initialOrientation {
    case .portrait:
      return transformPortrait()
    case .portraitUpsideDown:
      return transformPortraitUpsideDown()
    case .landscapeLeft:
      return transformLandscapeLeft()
    case .landscapeRight:
      return transformLandscapeRight()
    default:
      return .identity
    }
  }

  private func transformPortrait() -> CGAffineTransform {
    switch currentDeviceOrientation() {
    case .landscapeLeft:
      return CGAffineTransform(rotationAngle: .pi / 2)
    case .landscapeRight:
      return CGAffineTransform(rotationAngle: -(.pi / 2))
    case .portraitUpsideDown:
      return CGAffineTransform(rotationAngle: .pi)
    default:
      return .identity
    }
  }

  private func transformPortraitUpsideDown() -> CGAffineTransform {
    switch currentDeviceOrientation() {
    case .landscapeLeft:
      return CGAffineTransform(rotationAngle: -(.pi / 2))
    case .landscapeRight:
      return CGAffineTransform(rotationAngle: .pi / 2)
    case .portrait:
      return CGAffineTransform(rotationAngle: .pi)
    default:
      return .identity
    }
  }

  private func transformLandscapeLeft() -> CGAffineTransform {
    switch currentDeviceOrientation() {
    case .landscapeRight:
      return CGAffineTransform(rotationAngle: .pi)
    case .portrait:
      return CGAffineTransform(rotationAngle: -(.pi / 2))
    case .portraitUpsideDown:
      return CGAffineTransform(rotationAngle: .pi / 2)
    default:
      return .identity
    }
  }

  private func transformLandscapeRight() -> CGAffineTransform {
    switch currentDeviceOrientation() {
    case .landscapeLeft:
      return CGAffineTransform(rotationAngle: .pi)
    case .portrait:
      return CGAffineTransform(rotationAngle: .pi / 2)
    case .portraitUpsideDown:
      return CGAffineTransform(rotationAngle: -(.pi / 2))
    default:
      return .identity
    }
  }

}

extension Agrume: UICollectionViewDataSource {

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return dataSource?.numberOfImages ?? 0
  }

  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Agrume.reuseIdentifier,
                                                  for: indexPath) as! AgrumeCell
    spinner.alpha = 1
    dataSource?.image(forIndex: indexPath.item) { [weak self] image in
      DispatchQueue.main.async {
        cell.image = image
        self?.spinner.alpha = 0
      }
    }
    // Only allow panning if horizontal swiping fails. Horizontal swiping is only active for zoomed in images
    collectionView.panGestureRecognizer.require(toFail: cell.swipeGesture)
    cell.delegate = self
    return cell
  }

}

extension Agrume: AgrumeDataSource {
  
  public var numberOfImages: Int {
    return images.count
  }
  
  public func image(forIndex index: Int, completion: @escaping (UIImage?) -> Void) {
    if let handler = AgrumeServiceLocator.shared.downloadHandler, let url = images[index].url {
      handler(url, completion)
    } else if let url = images[index].url {
      downloadTask = ImageDownloader.downloadImage(url, completion: completion)
    } else {
      completion(images[index].image)
    }
  }
  
}

extension Agrume: UICollectionViewDelegate {

  public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    didScroll?(indexPath.item)

    spinner.alpha = 1
    dataSource?.image(forIndex: indexPath.item) { [weak self] image in
      (cell as! AgrumeCell).image = image
      self?.spinner.alpha = 0
    }
  }
  
  private func isDataSourceCountUnchanged(dataSourceCount: Int, collectionViewCount: Int) -> Bool {
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
    _collectionView?.visibleCells.forEach { cell in
      (cell as? AgrumeCell)?.cleanup()
    }
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
                   animations: {
                    self.collectionView.alpha = 0
                    self.blurContainerView.alpha = 0
                    let scaling = Agrume.maxScalingForExpandingOffscreen
                    self.collectionView.transform = CGAffineTransform(scaleX: scaling, y: scaling)
      }, completion: dismissCompletion)
  }
  
  func isSingleImageMode() -> Bool {
    return dataSource?.numberOfImages == 1
  }
  
}

extension Agrume {
  
  // MARK: Status Bar

  public override var preferredStatusBarStyle:  UIStatusBarStyle {
    return statusBarStyle ?? super.preferredStatusBarStyle
  }
  
}
