//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import UIKit

public final class Agrume: UIViewController {

  /// Tap behaviour, i.e. what happens when you tap outside of the image area
  public enum TapBehavior {
    case dismissIfZoomedOut
    case dismissAlways
    case zoomOut
    case toggleOverlayVisibility
  }

  private var images: [AgrumeImage]!
  private let startIndex: Int
  private let dismissal: Dismissal
  
  private var overlayView: AgrumeOverlayView?
  private weak var dataSource: AgrumeDataSource?

  /// The background property. Set through the initialiser for most use cases.
  public var background: Background

  /// The "page" index for the current image
  public private(set) var currentIndex: Int
  
  public typealias DownloadCompletion = (_ image: UIImage?) -> Void

  /// Optional closure to call when user long pressed on an image
  public var onLongPress: ((UIImage?, UIViewController) -> Void)?
  /// Optional closure to call whenever Agrume is about to dismiss.
  public var willDismiss: (() -> Void)?
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

  /// Default tap behaviour is to dismiss the view if zoomed out
  public var tapBehavior: TapBehavior = .dismissIfZoomedOut

  override public var preferredStatusBarStyle: UIStatusBarStyle {
    statusBarStyle ?? super.preferredStatusBarStyle
  }

  /// Initialize with a single image
  ///
  /// - Parameters:
  ///   - image: The image to present
  ///   - background: The background configuration
  ///   - dismissal: The dismiss configuration
  ///   - overlayView: View to overlay the image (does not display with 'button' dismissals)
  public convenience init(image: UIImage, background: Background = .colored(.black),
                          dismissal: Dismissal = .withPan(.standard), overlayView: AgrumeOverlayView? = nil) {
    self.init(images: [image], background: background, dismissal: dismissal, overlayView: overlayView)
  }

  /// Initialize with a single image url
  ///
  /// - Parameters:
  ///   - url: The image url to present
  ///   - background: The background configuration
  ///   - dismissal: The dismiss configuration
  ///   - overlayView: View to overlay the image (does not display with 'button' dismissals)
  public convenience init(url: URL, background: Background = .colored(.black), dismissal: Dismissal = .withPan(.standard),
                          overlayView: AgrumeOverlayView? = nil) {
    self.init(urls: [url], background: background, dismissal: dismissal, overlayView: overlayView)
  }

  /// Initialize with a data source
  ///
  /// - Parameters:
  ///   - dataSource: The `AgrumeDataSource` to use
  ///   - startIndex: The optional start index when showing multiple images
  ///   - background: The background configuration
  ///   - dismissal: The dismiss configuration
  ///   - overlayView: View to overlay the image (does not display with 'button' dismissals)
  public convenience init(dataSource: AgrumeDataSource, startIndex: Int = 0, background: Background = .colored(.black),
                          dismissal: Dismissal = .withPan(.standard), overlayView: AgrumeOverlayView? = nil) {
    self.init(images: nil, dataSource: dataSource, startIndex: startIndex, background: background, dismissal: dismissal,
              overlayView: overlayView)
  }

  /// Initialize with an array of images
  ///
  /// - Parameters:
  ///   - images: The images to present
  ///   - startIndex: The optional start index when showing multiple images
  ///   - background: The background configuration
  ///   - dismissal: The dismiss configuration
  ///   - overlayView: View to overlay the image (does not display with 'button' dismissals)
  public convenience init(images: [UIImage], startIndex: Int = 0, background: Background = .colored(.black),
                          dismissal: Dismissal = .withPan(.standard), overlayView: AgrumeOverlayView? = nil) {
    self.init(images: images, urls: nil, startIndex: startIndex, background: background, dismissal: dismissal, overlayView: overlayView)
  }

  /// Initialize with an array of image urls
  ///
  /// - Parameters:
  ///   - urls: The image urls to present
  ///   - startIndex: The optional start index when showing multiple images
  ///   - background: The background configuration
  ///   - dismissal: The dismiss configuration
  ///   - overlayView: View to overlay the image (does not display with 'button' dismissals)
  public convenience init(urls: [URL], startIndex: Int = 0, background: Background = .colored(.black),
                          dismissal: Dismissal = .withPan(.standard), overlayView: AgrumeOverlayView? = nil) {
    self.init(images: nil, urls: urls, startIndex: startIndex, background: background, dismissal: dismissal, overlayView: overlayView)
  }

  private init(images: [UIImage]? = nil, urls: [URL]? = nil, dataSource: AgrumeDataSource? = nil, startIndex: Int,
               background: Background, dismissal: Dismissal, overlayView: AgrumeOverlayView? = nil) {
    switch (images, urls) {
    case (let images?, nil):
      self.images = images.map { AgrumeImage(image: $0) }
    case (_, let urls?):
      self.images = urls.map { AgrumeImage(url: $0) }
    default:
      assert(dataSource != nil, "No images or URLs passed. You must provide an AgrumeDataSource in that case.")
    }

    self.startIndex = startIndex
    self.currentIndex = startIndex
    self.background = background
    self.dismissal = dismissal
    super.init(nibName: nil, bundle: nil)
    
    self.overlayView = overlayView
    self.dataSource = dataSource ?? self
    
    modalPresentationStyle = .custom
    modalPresentationCapturesStatusBarAppearance = true
  }

  deinit {
    downloadTask?.cancel()
  }

  @available(*, unavailable)
  required public init?(coder aDecoder: NSCoder) {
    fatalError("Not implemented")
  }

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
      blurContainerView.frame = CGRect(origin: view.frame.origin, size: view.frame.size * 2)
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
    blurView.frame = blurContainerView.bounds
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

      let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
      collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      collectionView.register(AgrumeCell.self)
      collectionView.dataSource = self
      collectionView.delegate = self
      collectionView.isPagingEnabled = true
      collectionView.backgroundColor = .clear
      collectionView.delaysContentTouches = false
      collectionView.showsHorizontalScrollIndicator = false
      if #available(iOS 11.0, *) {
        collectionView.contentInsetAdjustmentBehavior = .never
      }
      _collectionView = collectionView
    }
    return _collectionView!
  }
  private var _spinner: UIActivityIndicatorView?
  private var spinner: UIActivityIndicatorView {
    if _spinner == nil {
      let indicatorStyle: UIActivityIndicatorView.Style
      switch background {
      case let .blurred(style):
        indicatorStyle = style == .dark ? .whiteLarge : .gray
      case let .colored(color):
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
  // Container for the collection view. Fixes an RTL display bug
  private lazy var containerView = with(UIView(frame: view.bounds)) { containerView in
    containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
  }

  private var downloadTask: URLSessionDataTask?

  /// Present Agrume
  ///
  /// - Parameters:
  ///   - viewController: The UIViewController to present from
  public func show(from viewController: UIViewController) {
    view.isUserInteractionEnabled = false
    addSubviews()
    present(from: viewController)
  }

  /// Update image at index
  /// - Parameters:
  ///   - index: The target index
  ///   - image: The replacement UIImage
  ///   - newTitle: The new title, if nil then no change
  public func updateImage(at index: Int, with image: UIImage, newTitle: NSAttributedString? = nil) {
    assert(images.count > index)
    let replacement = with(images[index]) {
      $0.url = nil
      $0.image = image
      if let newTitle = newTitle {
        $0.title = newTitle
      }
    }
    
    markAsUpdatingSameCell(at: index)
    images[index] = replacement
    reload()
  }

  /// Update image at a specific index
  /// - Parameters:
  ///   - index: The target index
  ///   - url: The replacement URL
  ///   - newTitle: The new title, if nil then no change
  public func updateImage(at index: Int, with url: URL, newTitle: NSAttributedString? = nil) {
    assert(images.count > index)
    let replacement = with(images[index]) {
      $0.image = nil
      $0.url = url
      if let newTitle = newTitle {
        $0.title = newTitle
      }
    }
    
    markAsUpdatingSameCell(at: index)
    images[index] = replacement
    reload()
  }
  
  private func markAsUpdatingSameCell(at index: Int) {
    collectionView.visibleCells.forEach { cell in
      if let cell = cell as? AgrumeCell, cell.index == index {
        cell.updatingImageOnSameCell = true
      }
    }
  }
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    addSubviews()

    if onLongPress != nil {
      let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
      view.addGestureRecognizer(longPress)
    }
  }

  @objc
  func didLongPress(_ gesture: UIGestureRecognizer) {
    guard case .began = gesture.state else {
      return
    }
    fetchImage(forIndex: currentIndex) { [weak self] image in
      guard let self = self else {
        return
      }
      self.onLongPress?(image, self)
    }
  }

  private func addSubviews() {
    view.autoresizingMask = [.flexibleHeight, .flexibleWidth]

    if case .blurred = background {
      blurContainerView.addSubview(blurView)
    }
    view.addSubview(blurContainerView)
    view.addSubview(containerView)
    containerView.addSubview(collectionView)
    view.addSubview(spinner)
  }
  
  private func present(from viewController: UIViewController) {
    DispatchQueue.main.async {
      self.blurContainerView.alpha = 1
      self.containerView.alpha = 0
      let scale: CGFloat = .initialScaleToExpandFrom

      viewController.present(self, animated: false) {
        // Transform the container view, not the collection view to prevent an RTL display bug
        self.containerView.transform = CGAffineTransform(scaleX: scale, y: scale)
        
        UIView.animate(
          withDuration: .transitionAnimationDuration,
          delay: 0,
          options: .beginFromCurrentState,
          animations: {
            self.containerView.alpha = 1
            self.containerView.transform = .identity
            self.addOverlayView()
          },
          completion: { _ in
            self.view.isUserInteractionEnabled = true
          }
        )
      }
    }
  }
  
  private func addOverlayView() {
    switch (dismissal, overlayView) {
    case let (.withButton(button), _), let (.withPanAndButton(_, button), _):
      let overlayView = AgrumeCloseButtonOverlayView(closeButton: button)
      overlayView.delegate = self
      overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      overlayView.frame = view.bounds
      view.addSubview(overlayView)
      self.overlayView = overlayView
    case (.withPan, let overlayView?):
      overlayView.alpha = 1
      overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      overlayView.frame = view.bounds
      view.addSubview(overlayView)
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

  public override var keyCommands: [UIKeyCommand]? {
    return [
      UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(escPressed))
    ]
  }

  @objc
  func escPressed() {
    dismiss()
  }
  
  public func dismiss() {
    dismissAfterFlick()
  }

  public func showImage(atIndex index: Int, animated: Bool = true) {
    scrollToImage(atIndex: index, animated: animated)
  }

  public func reload() {
    DispatchQueue.main.async {
      self.collectionView.reloadData()
    }
  }
  
  override public var prefersStatusBarHidden: Bool {
    hideStatusBar
  }
  
  private func scrollToImage(atIndex index: Int, animated: Bool = false) {
    collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: animated)
  }
  
  private func currentlyVisibleCellIndex() -> Int {
    let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
    let visiblePoint = CGPoint(x: visibleRect.minX, y: visibleRect.minY)
    return collectionView.indexPathForItem(at: visiblePoint)?.item ?? startIndex
  }
  
  override public func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    layout.itemSize = view.bounds.size
    layout.invalidateLayout()
    
    spinner.center = view.center
    
    if currentIndex != currentlyVisibleCellIndex() {
      scrollToImage(atIndex: currentIndex)
    }
  }
  
  override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    let indexToRotate = currentIndex
    let rotationHandler: ((UIViewControllerTransitionCoordinatorContext) -> Void) = { _ in
      self.scrollToImage(atIndex: indexToRotate)
      self.collectionView.visibleCells.forEach { cell in
        (cell as! AgrumeCell).recenterDuringRotation(size: size)
      }
    }
    coordinator.animate(alongsideTransition: rotationHandler, completion: rotationHandler)
    super.viewWillTransition(to: size, with: coordinator)
  }
}

extension Agrume: AgrumeDataSource {
  
  public var numberOfImages: Int {
    images.count
  }
  
  public func image(forIndex index: Int, completion: @escaping (UIImage?) -> Void) {
    let downloadHandler = download ?? AgrumeServiceLocator.shared.downloadHandler
    if let handler = downloadHandler, let url = images[index].url {
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
    dataSource?.numberOfImages ?? 0
  }

  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell: AgrumeCell = collectionView.dequeue(indexPath: indexPath)

    cell.tapBehavior = tapBehavior
    switch dismissal {
    case .withPan(let physics), .withPanAndButton(let physics, _):
      cell.panPhysics = physics
    case .withButton:
      cell.panPhysics = nil
    // Backward compatibility
    case .withPhysics, .withPhysicsAndButton:
      cell.panPhysics = .standard
    }

    spinner.alpha = 1
    fetchImage(forIndex: indexPath.item) { [weak self] image in
      cell.index = indexPath.item
      cell.image = image
      self?.spinner.alpha = 0
    }
    // Only allow panning if horizontal swiping fails. Horizontal swiping is only active for zoomed in images
    collectionView.panGestureRecognizer.require(toFail: cell.swipeGesture)
    cell.delegate = self
    return cell
  }

  private func fetchImage(forIndex index: Int, handler: @escaping (UIImage?) -> Void) {
    dataSource?.image(forIndex: index) { image in
      DispatchQueue.main.async {
        handler(image)
      }
    }
  }

}

extension Agrume: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  public func collectionView(_ collectionView: UICollectionView,
                             layout collectionViewLayout: UICollectionViewLayout,
                             insetForSectionAt section: Int) -> UIEdgeInsets {
    // Center cells horizontally
    let cellWidth = view.bounds.width
    let totalWidth = cellWidth * CGFloat(dataSource?.numberOfImages ?? 0)
    let leftRightEdgeInset = max(0, (collectionView.bounds.width - totalWidth) / 2)
    return UIEdgeInsets(top: 0, left: leftRightEdgeInset, bottom: 0, right: leftRightEdgeInset)
  }

  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    didScroll?(currentlyVisibleCellIndex())
  }
  
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let center = CGPoint(x: scrollView.contentOffset.x + (scrollView.frame.width / 2), y: (scrollView.frame.height / 2))
    if let indexPath = collectionView.indexPathForItem(at: center) {
      currentIndex = indexPath.row
    }
  }
  
}

extension Agrume: AgrumeCellDelegate {

  var isSingleImageMode: Bool {
    dataSource?.numberOfImages == 1
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
    self.willDismiss?()
    UIView.animate(
      withDuration: .transitionAnimationDuration,
      delay: 0,
      options: .beginFromCurrentState,
      animations: {
        self.collectionView.alpha = 0
        self.blurContainerView.alpha = 0
        self.overlayView?.alpha = 0
      },
      completion: dismissCompletion
    )
  }
  
  func dismissAfterTap() {
    view.isUserInteractionEnabled = false

    self.willDismiss?()
    UIView.animate(
      withDuration: .transitionAnimationDuration,
      delay: 0,
      options: .beginFromCurrentState,
      animations: {
        self.collectionView.alpha = 0
        self.blurContainerView.alpha = 0
        self.overlayView?.alpha = 0
        let scale: CGFloat = .maxScaleForExpandingOffscreen
        self.collectionView.transform = CGAffineTransform(scaleX: scale, y: scale)
      },
      completion: dismissCompletion
    )
  }

  func toggleOverlayVisibility() {
    UIView.animate(
      withDuration: .transitionAnimationDuration,
      delay: 0,
      options: .beginFromCurrentState,
      animations: {
        if let overlayView = self.overlayView {
          overlayView.alpha = overlayView.alpha < 0.5 ? 1 : 0
        }
      },
      completion: nil
    )
  }
}

extension Agrume: AgrumeCloseButtonOverlayViewDelegate {

  func agrumeOverlayViewWantsToClose(_ view: AgrumeCloseButtonOverlayView) {
    dismiss()
  }

}
