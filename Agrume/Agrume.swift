//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import UIKit

public final class Agrume: UIViewController {

  private var images: [AgrumeImage]!
  private let startIndex: Int
  private let background: Background
  
  private weak var dataSource: AgrumeDataSource?

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
  public var hideStatusBar = false

  public enum TapBehavior {
    case dismissIfZoomedOut
    case dismissAlways
    case zoomOut
  }
  public var tapBehavior: TapBehavior = .dismissIfZoomedOut

  /// Initialize with a single image
  ///
  /// - Parameter image: The image to present
  /// - Parameter background: The background configuration
  public convenience init(image: UIImage, background: Background = .colored(.black)) {
    self.init(images: [image], background: background)
  }

  /// Initialize with a single image url
  ///
  /// - Parameter url: The image url to present
  /// - Parameter background: The background configuration
  public convenience init(url: URL, background: Background = .colored(.black)) {
    self.init(urls: [url], background: background)
  }

  /// Initialize with a data source
  ///
  /// - Parameter dataSource: The `AgrumeDataSource` to use
  /// - Parameter startIndex: The optional start index when showing multiple images
  /// - Parameter background: The background configuration
	public convenience init(dataSource: AgrumeDataSource, startIndex: Int = 0, background: Background = .colored(.black)) {
		self.init(dataSource: dataSource, startIndex: startIndex, background: background)
	}
	
  /// Initialize with an array of images
  ///
  /// - Parameter images: The images to present
  /// - Parameter startIndex: The optional start index when showing multiple images
  /// - Parameter background: The background configuration
  public convenience init(images: [UIImage], startIndex: Int = 0, background: Background = .colored(.black)) {
    self.init(images: images, urls: nil, startIndex: startIndex, background: background)
  }

  /// Initialize with an array of image urls
  ///
  /// - Parameter urls: The image urls to present
  /// - Parameter startIndex: The optional start index when showing multiple images
  /// - Parameter background: The background configuration
  public convenience init(urls: [URL], startIndex: Int = 0, background: Background = .colored(.black)) {
    self.init(images: nil, urls: urls, startIndex: startIndex, background: background)
  }

	private init(images: [UIImage]? = nil, urls: [URL]? = nil, dataSource: AgrumeDataSource? = nil, startIndex: Int,
	             background: Background) {
    switch (images, urls) {
    case (let images?, nil):
      self.images = images.map { AgrumeImage(image: $0) }
    case (_, let urls?):
      self.images = urls.map { AgrumeImage(url: $0) }
    default:
      assert(dataSource != nil, "No images or URLs passed. You must provide an AgrumeDataSource in that case.")
    }
		
    self.startIndex = startIndex
    self.background = background
    super.init(nibName: nil, bundle: nil)
    
    self.dataSource = dataSource ?? self
    
    modalPresentationStyle = .custom
    modalPresentationCapturesStatusBarAppearance = true
  }

  deinit {
    downloadTask?.cancel()
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("Not implemented")
  }

  private var backgroundSnapshot: UIImage!
  private var backgroundImageView: UIImageView!
  private var _blurContainerView: UIView?
  private var blurContainerView: UIView {
    if _blurContainerView == nil {
      let view = UIView(frame: self.view.frame)
      view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      if case .colored(let color) = background {
        view.backgroundColor = color
      } else {
        view.backgroundColor = .clear
      }
      _blurContainerView = view
    }
    return _blurContainerView!
  }
  private var _blurView: UIVisualEffectView?
  private var blurView: UIVisualEffectView {
    guard case .blurred(let style) = background, _blurView == nil else {
      return _blurView!
    }
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: style))
    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    blurView.frame = view.frame
        _blurView = blurView
    return _blurView!
  }
  private var _collectionView: UICollectionView?
  private var collectionView: UICollectionView {
    if _collectionView == nil {
      let layout = UICollectionViewFlowLayout()
      layout.minimumInteritemSpacing = 0
      layout.minimumLineSpacing = 0
      layout.scrollDirection = .horizontal
      layout.itemSize = view.frame.size
      
      let collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
      collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      collectionView.register(AgrumeCell.self, forCellWithReuseIdentifier: String(describing: AgrumeCell.self))
      collectionView.dataSource = self
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
      let indicatorStyle: UIActivityIndicatorViewStyle
      switch background {
      case .blurred(let style):
        indicatorStyle = style == .dark ? .whiteLarge : .gray
      case .colored(let color):
        indicatorStyle = color.isLight ? .gray : .whiteLarge
      }
      let spinner = UIActivityIndicatorView(activityIndicatorStyle: indicatorStyle)
      spinner.center = view.center
      spinner.startAnimating()
      spinner.alpha = 0
      _spinner = spinner
    }
    return _spinner!
  }

  private var downloadTask: URLSessionDataTask?

  /// Present Agrume
  /// - Parameter viewController: The UIViewController to present from
  /// - Parameter backgroundSnapshotVC: Optional UIViewController that will be used as basis for a blurred background
  public func show(from viewController: UIViewController, backgroundSnapshotVC: UIViewController? = nil) {
    backgroundSnapshot = (backgroundSnapshotVC ?? viewControllerForSnapshot(fromViewController: viewController))?.view.snapshot()
    view.isUserInteractionEnabled = false
    addSubviews()
    show(from: viewController)
  }
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    addSubviews()
  }
  
  private func addSubviews() {
    view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    backgroundImageView = UIImageView(frame: view.frame)
    backgroundImageView.image = backgroundSnapshot
    view.addSubview(backgroundImageView)
    
    if case .blurred(_) = background {
      blurContainerView.addSubview(blurView)
    }
    view.addSubview(blurContainerView)
    view.addSubview(collectionView)
    if startIndex > 0 {
      collectionView.scrollToItem(at: IndexPath(item: startIndex, section: 0), at: [], animated: false)
    }
    view.addSubview(spinner)
  }
  
  private func show(from viewController: UIViewController) {
    DispatchQueue.main.async {
      self.blurContainerView.alpha = 1
      self.collectionView.alpha = 0
      self.collectionView.frame = self.view.frame
      let scaling: CGFloat = .initialScalingToExpandFrom
      self.collectionView.transform = CGAffineTransform(scaleX: scaling, y: scaling)

      viewController.present(self, animated: false) {
        UIView.animate(withDuration: .transitionAnimationDuration,
                       delay: 0,
                       options: .beginFromCurrentState,
                       animations: {
                        self.collectionView.alpha = 1
                        self.collectionView.transform = .identity
          }, completion: { _ in
            self.view.isUserInteractionEnabled = true
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
    dismissAfterFlick()
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
  
  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animate(alongsideTransition: nil) { _ in
      guard let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
      layout.itemSize = size
      layout.invalidateLayout()
      
      self.collectionView.visibleCells.forEach { cell in
        (cell as! AgrumeCell).recenterImage(size: size)
      }
    }
    super.viewWillTransition(to: size, with: coordinator)
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

extension Agrume: UICollectionViewDataSource {

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return dataSource?.numberOfImages ?? 0
  }

  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell: AgrumeCell = collectionView.dequeue(indexPath: indexPath)
    
    cell.tapBehavior = tapBehavior

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
    UIView.animate(withDuration: .transitionAnimationDuration,
                   delay: 0,
                   options: .beginFromCurrentState,
                   animations: {
                    self.collectionView.alpha = 0
                    self.blurContainerView.alpha = 0
      }, completion: dismissCompletion)
  }
  
  func dismissAfterTap() {
    view.isUserInteractionEnabled = false
    
    UIView.animate(withDuration: .transitionAnimationDuration,
                   delay: 0,
                   options: .beginFromCurrentState,
                   animations: {
                    self.collectionView.alpha = 0
                    self.blurContainerView.alpha = 0
                    let scaling: CGFloat = .maxScalingForExpandingOffscreen
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
