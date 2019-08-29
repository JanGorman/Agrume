//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import UIKit

public final class Agrume: UIViewController {

  private var images: [AgrumeImage]!
  private let startIndex: Int
  private let background: Background
  private let dismissal: Dismissal
  
  private var overlayView: UIView?
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

  /// Tap behaviour, i.e. what happens when you tap outside of the image area
  public enum TapBehavior {
    case dismissIfZoomedOut
    case dismissAlways
    case zoomOut
  }
  /// Default tap behaviour is to dismiss the view if zoomed out
  public var tapBehavior: TapBehavior = .dismissIfZoomedOut

  /// Initialize with a single image
  ///
  /// - Parameters:
  ///   - image: The image to present
  ///   - background: The background configuration
  ///   - dismissal: The dismiss configuration
  public convenience init(image: UIImage, background: Background = .colored(.black), dismissal: Dismissal = .withPhysics) {
    self.init(images: [image], background: background, dismissal: dismissal)
  }

  /// Initialize with a single image url
  ///
  /// - Parameters:
  ///   - url: The image url to present
  ///   - background: The background configuration
  ///   - dismissal: The dismiss configuration
  public convenience init(url: URL, background: Background = .colored(.black), dismissal: Dismissal = .withPhysics) {
    self.init(urls: [url], background: background, dismissal: dismissal)
  }

  /// Initialize with a data source
  ///
  /// - Parameters:
  ///   - dataSource: The `AgrumeDataSource` to use
  ///   - startIndex: The optional start index when showing multiple images
  ///   - background: The background configuration
  ///   - dismissal: The dismiss configuration
	public convenience init(dataSource: AgrumeDataSource, startIndex: Int = 0, background: Background = .colored(.black),
                          dismissal: Dismissal = .withPhysics) {
    self.init(images: nil, dataSource: dataSource, startIndex: startIndex, background: background, dismissal: dismissal)
	}

  /// Initialize with an array of images
  ///
  /// - Parameters:
  ///   - images: The images to present
  ///   - startIndex: The optional start index when showing multiple images
  ///   - background: The background configuration
  ///   - dismissal: The dismiss configuration
  public convenience init(images: [UIImage], startIndex: Int = 0, background: Background = .colored(.black),
                          dismissal: Dismissal = .withPhysics) {
    self.init(images: images, urls: nil, startIndex: startIndex, background: background, dismissal: dismissal)
  }

  /// Initialize with an array of image urls
  ///
  /// - Parameters:
  ///   - urls: The image urls to present
  ///   - startIndex: The optional start index when showing multiple images
  ///   - background: The background configuration
  ///   - dismissal: The dismiss configuration
  public convenience init(urls: [URL], startIndex: Int = 0, background: Background = .colored(.black),
                          dismissal: Dismissal = .withPhysics) {
    self.init(images: nil, urls: urls, startIndex: startIndex, background: background, dismissal: dismissal)
  }

	private init(images: [UIImage]? = nil, urls: [URL]? = nil, dataSource: AgrumeDataSource? = nil, startIndex: Int,
               background: Background, dismissal: Dismissal) {
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
    self.dismissal = dismissal
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
      let blurContainerView = UIView()
      blurContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      if case .colored(let color) = background {
        blurContainerView.backgroundColor = color
      } else {
        blurContainerView.backgroundColor = .clear
      }
      blurContainerView.frame = view.frame
      _blurContainerView = blurContainerView
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

      let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
      collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      collectionView.register(AgrumeCell.self, forCellWithReuseIdentifier: String(describing: AgrumeCell.self))
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
      let indicatorStyle: UIActivityIndicatorView.Style
      switch background {
      case .blurred(let style):
        indicatorStyle = style == .dark ? .whiteLarge : .gray
      case .colored(let color):
        indicatorStyle = color.isLight ? .gray : .whiteLarge
      }
      let spinner = UIActivityIndicatorView(style: indicatorStyle)
      spinner.center = view.center
      spinner.startAnimating()
      spinner.alpha = 0
      _spinner = spinner
    }
    return _spinner!
  }

  private var downloadTask: URLSessionDataTask?
  
  public override var preferredStatusBarStyle:  UIStatusBarStyle {
    return statusBarStyle ?? super.preferredStatusBarStyle
  }

  /// Present Agrume
  ///
  /// - Parameters:
  ///   - viewController: The UIViewController to present from
  ///   - backgroundSnapshotVC: Optional UIViewController that will be used as basis for a blurred background
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
    
    if case .blurred = background {
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
      let scale: CGFloat = .initialScaleToExpandFrom
      self.collectionView.transform = CGAffineTransform(scaleX: scale, y: scale)

      viewController.present(self, animated: false) {
        UIView.animate(withDuration: .transitionAnimationDuration,
                       delay: 0,
                       options: .beginFromCurrentState,
                       animations: {
                        self.collectionView.alpha = 1
                        self.collectionView.transform = .identity
                        self.addOverlayView()
          }, completion: { _ in
            self.view.isUserInteractionEnabled = true
          })
      }
    }
  }
  
  private func addOverlayView() {
    switch dismissal {
    case .withButton(let button), .withPhysicsAndButton(let button):
      let overlayView = AgrumeOverlayView(closeButton: button)
      overlayView.delegate = self
      overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      overlayView.frame = view.bounds
      view.addSubview(overlayView)
      self.overlayView = overlayView
    default:
      break
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
    switch dismissal {
    case .withPhysics, .withPhysicsAndButton:
      cell.hasPhysics = true
    case .withButton:
      cell.hasPhysics = false
    }

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

extension Agrume: UICollectionViewDelegate {

  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    guard let indexPath = collectionView.indexPathsForVisibleItems.first else {
      return
    }
    didScroll?(indexPath.item)
  }

}

extension Agrume: AgrumeCellDelegate {

  var isSingleImageMode: Bool {
    return dataSource?.numberOfImages == 1
  }
  
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
                    self.overlayView?.alpha = 0
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
                    self.overlayView?.alpha = 0
                    let scale: CGFloat = .maxScaleForExpandingOffscreen
                    self.collectionView.transform = CGAffineTransform(scaleX: scale, y: scale)
      }, completion: dismissCompletion)
  }

}

extension Agrume: AgrumeOverlayViewDelegate {

  func agrumeOverlayViewWantsToClose(_ view: AgrumeOverlayView) {
    dismiss()
  }

}
