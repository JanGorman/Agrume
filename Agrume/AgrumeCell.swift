//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import SwiftyGif
import UIKit

protocol AgrumeCellDelegate: AnyObject {

  var isSingleImageMode: Bool { get }

  func dismissAfterFlick()
  func dismissAfterTap()
  func toggleOverlayVisibility()
}

final class AgrumeCell: UICollectionViewCell {

  var tapBehavior: Agrume.TapBehavior = .dismissIfZoomedOut
  /// Specifies dismissal physics behavior; if `nil` then no physics is used for dismissal.
  var panPhysics: Dismissal.Physics? = .standard

  private lazy var scrollView = with(UIScrollView()) { scrollView in
    scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    scrollView.delegate = self
    scrollView.zoomScale = 1
    scrollView.maximumZoomScale = 8
    scrollView.isScrollEnabled = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false
  }
  private lazy var imageView = with(UIImageView()) { imageView in
    imageView.contentMode = .scaleAspectFit
    imageView.clipsToBounds = true
    imageView.layer.allowsEdgeAntialiasing = true
  }
  private lazy var singleTapGesture = with(UITapGestureRecognizer(target: self, action: #selector(singleTap))) { gesture in
    gesture.require(toFail: doubleTapGesture)
    gesture.delegate = self
  }
  private lazy var doubleTapGesture = with(UITapGestureRecognizer(target: self, action: #selector(doubleTap))) { gesture in
    gesture.numberOfTapsRequired = 2
  }
  private lazy var panGesture = with(UIPanGestureRecognizer(target: self, action: #selector(dismissPan))) { gesture in
    gesture.maximumNumberOfTouches = 1
    gesture.delegate = self
  }

  private var animator: UIDynamicAnimator?
  private var flickedToDismiss = false
  private var isDraggingImage = false
  private var imageDragStartingPoint: CGPoint!
  private var imageDragOffsetFromActualTranslation: UIOffset!
  private var imageDragOffsetFromImageCenter: UIOffset!
  private var attachmentBehavior: UIAttachmentBehavior?
  
  // index of the cell in the collection view
  var index: Int?
  
  // if set to true, it means we are updating image on the same cell, so we want to reserve the zoom level & position
  var updatingImageOnSameCell = false
  
  var image: UIImage? {
    didSet {
      if image?.imageData != nil, let image = image {
        imageView.setGifImage(image)
      } else {
        imageView.image = image
      }
      if !updatingImageOnSameCell {
        updateScrollViewAndImageViewForCurrentMetrics()
      }
      updatingImageOnSameCell = false
    }
  }
  weak var delegate: AgrumeCellDelegate?

  private(set) lazy var swipeGesture = with(UISwipeGestureRecognizer(target: self, action: nil)) { gesture in
    gesture.direction = [.left, .right]
    gesture.delegate = self
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = .clear
    contentView.addSubview(scrollView)
    scrollView.addSubview(imageView)
    setupGestureRecognizers()
    if panPhysics != nil {
      animator = UIDynamicAnimator(referenceView: scrollView)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    if !updatingImageOnSameCell {
      imageView.image = nil
      scrollView.zoomScale = 1
      updateScrollViewAndImageViewForCurrentMetrics()
    }
  }

  private func setupGestureRecognizers() {
    contentView.addGestureRecognizer(singleTapGesture)
    contentView.addGestureRecognizer(doubleTapGesture)
    scrollView.addGestureRecognizer(panGesture)
    contentView.addGestureRecognizer(swipeGesture)
  }

  func cleanup() {
    animator = nil
  }

}

extension AgrumeCell: UIGestureRecognizerDelegate {

  private var notZoomed: Bool {
    scrollView.zoomScale == 1
  }

  private var isImageViewOffscreen: Bool {
    let visibleRect = scrollView.convert(contentView.bounds, from: contentView)
    return animator?.items(in: visibleRect).isEmpty == true
  }

  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if notZoomed, let pan = gestureRecognizer as? UIPanGestureRecognizer {
      let velocity = pan.velocity(in: scrollView)
      if delegate?.isSingleImageMode == true {
        return true
      }
      return abs(velocity.y) > abs(velocity.x)
    } else if notZoomed, gestureRecognizer as? UISwipeGestureRecognizer != nil {
      return false
    }
    return true
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    if gestureRecognizer as? UIPanGestureRecognizer != nil {
      return notZoomed
    }
    return true
  }

  @objc
  private func doubleTap(_ sender: UITapGestureRecognizer) {
    let point = scrollView.convert(sender.location(in: sender.view), from: sender.view)
    
    if notZoomed {
      zoom(to: point, scale: .targetZoomForDoubleTap)
    } else {
      zoom(to: .zero, scale: 1)
    }
  }
  
  private func zoom(to point: CGPoint, scale: CGFloat) {
    let factor = 1 / scrollView.zoomScale
    let translatedZoom = CGPoint(
      x: (point.x + scrollView.contentOffset.x) * factor,
      y: (point.y + scrollView.contentOffset.y) * factor
    )

    let width = scrollView.frame.width / scale
    let height = scrollView.frame.height / scale
    let destination = CGRect(x: translatedZoom.x - width / 2, y: translatedZoom.y - height / 2, width: width, height: height)

    contentView.isUserInteractionEnabled = false
    
    CATransaction.begin()
    CATransaction.setCompletionBlock { [unowned self] in
      self.contentView.isUserInteractionEnabled = true
    }
    scrollView.zoom(to: destination, animated: true)
    CATransaction.commit()
  }

  private func contentInsetForScrollView(atScale: CGFloat) -> UIEdgeInsets {
    let boundsWidth = scrollView.bounds.width
    let boundsHeight = scrollView.bounds.height
    let contentWidth = max(image?.size.width ?? 0, boundsWidth)
    let contentHeight = max(image?.size.height ?? 0, boundsHeight)

    var minContentWidth: CGFloat
    var minContentHeight: CGFloat

    if contentHeight > contentWidth {
      if boundsHeight / boundsWidth < contentHeight / contentWidth {
        minContentHeight = boundsHeight
        minContentWidth = contentWidth * (minContentHeight / contentHeight)
      } else {
        minContentWidth = boundsWidth
        minContentHeight = contentHeight * (minContentWidth / contentWidth)
      }
    } else {
      if boundsWidth / boundsHeight < contentWidth / contentHeight {
        minContentWidth = boundsWidth
        minContentHeight = contentHeight * (minContentWidth / contentWidth)
      } else {
        minContentHeight = boundsHeight
        minContentWidth = contentWidth * (minContentHeight / contentHeight)
      }
    }
    minContentWidth *= atScale
    minContentHeight *= atScale

    if minContentWidth > contentView.bounds.width && minContentHeight > contentView.bounds.height {
      return .zero
    } else {
      let verticalDiff = max(boundsHeight - minContentHeight, 0) / 2
      let horizontalDiff = max(boundsWidth - minContentWidth, 0) / 2
      return UIEdgeInsets(top: verticalDiff, left: horizontalDiff, bottom: verticalDiff, right: horizontalDiff)
    }
  }

  @objc
  private func singleTap() {
    switch tapBehavior {
    case .dismissIfZoomedOut:
      if notZoomed {
        dismiss()
      }
    case .dismissAlways:
      dismiss()
    case .zoomOut where notZoomed:
      dismiss()
    case .zoomOut:
      zoom(to: .zero, scale: 1)
    case .toggleOverlayVisibility:
      delegate?.toggleOverlayVisibility()
    }
  }

  private func dismiss() {
    if flickedToDismiss {
      delegate?.dismissAfterFlick()
    } else {
      delegate?.dismissAfterTap()
    }
  }

  @objc
  private func dismissPan(_ gesture: UIPanGestureRecognizer) {
    guard let panPhysics = panPhysics else { return }

    let translation = gesture.translation(in: gesture.view)
    let locationInView = gesture.location(in: gesture.view)
    let velocity = gesture.velocity(in: gesture.view)
    let vectorDistance: CGFloat
    switch panPhysics.permittedDirections {
    case .horizontalAndVertical:
      vectorDistance = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2))
    case .verticalOnly:
      vectorDistance = velocity.y
    }

    if case .began = gesture.state {
      isDraggingImage = imageView.frame.contains(locationInView)
      if isDraggingImage {
        startImageDragging(locationInView, translationOffset: .zero)
      }
    } else if case .changed = gesture.state {
      if isDraggingImage {
        var newAnchor = imageDragStartingPoint
        if panPhysics.permittedDirections == .horizontalAndVertical {
          // Only include x component if panning along both axes is allowed
          newAnchor?.x += translation.x + imageDragOffsetFromActualTranslation.horizontal
        }
        newAnchor?.y += translation.y + imageDragOffsetFromActualTranslation.vertical
        attachmentBehavior?.anchorPoint = newAnchor!
      } else {
        isDraggingImage = imageView.frame.contains(locationInView)
        if isDraggingImage {
          let translationOffset: UIOffset
          switch panPhysics.permittedDirections {
          case .horizontalAndVertical:
            translationOffset = UIOffset(horizontal: -1 * translation.x, vertical: -1 * translation.y)
          case .verticalOnly:
            translationOffset = UIOffset(horizontal: 0, vertical: -1 * translation.y)
          }
          startImageDragging(locationInView, translationOffset: translationOffset)
        }
      }
    } else {
      if vectorDistance > .minFlickDismissalVelocity {
        if isDraggingImage {
          dismissWithFlick(velocity)
        } else {
          dismiss()
        }
      } else {
        cancelCurrentImageDrag(true)
      }
    }
  }

  private func dismissWithFlick(_ velocity: CGPoint) {
    guard let panPhysics = panPhysics else { return }

    flickedToDismiss = true

    let push = UIPushBehavior(items: [imageView], mode: .instantaneous)
    switch panPhysics.permittedDirections {
    case .horizontalAndVertical:
      push.pushDirection = CGVector(dx: velocity.x * 0.1, dy: velocity.y * 0.1)
    case .verticalOnly:
      push.pushDirection = CGVector(dx: 0, dy: velocity.y * 0.1)
    }
    if let pushMagnitude = panPhysics.pushMagnitude {
      push.magnitude = pushMagnitude
    }
    push.setTargetOffsetFromCenter(imageDragOffsetFromImageCenter, for: imageView)
    push.action = pushAction
    if let attachmentBehavior = attachmentBehavior {
      animator?.removeBehavior(attachmentBehavior)
    }
    animator?.addBehavior(push)
  }
  
  private func pushAction() {
    if isImageViewOffscreen {
      animator?.removeAllBehaviors()
      attachmentBehavior = nil
      imageView.removeFromSuperview()
      dismiss()
    }
  }

  private func cancelCurrentImageDrag(_ animated: Bool, duration: TimeInterval = 0.7) {
    animator?.removeAllBehaviors()
    attachmentBehavior = nil
    isDraggingImage = false

    if !animated {
      imageView.transform = .identity
      recenterImage(size: scrollView.contentSize)
    } else {
      UIView.animate(
        withDuration: duration,
        delay: 0,
        usingSpringWithDamping: 0.7,
        initialSpringVelocity: 0,
        options: [.allowUserInteraction, .beginFromCurrentState],
        animations: {
          if self.isDraggingImage {
            return
          }

          self.imageView.transform = .identity
          if !self.scrollView.isDragging && !self.scrollView.isDecelerating {
            self.recenterImage(size: self.scrollView.contentSize)
            self.updateScrollViewAndImageViewForCurrentMetrics()
          }
        }
      )
    }
  }
  
  func recenterDuringRotation(size: CGSize) {
    self.recenterImage(size: size)
    self.updateScrollViewAndImageViewForCurrentMetrics()
  }
  
  func recenterImage(size: CGSize) {
    imageView.center = CGPoint(x: size.width / 2, y: size.height / 2)
  }

  private func updateScrollViewAndImageViewForCurrentMetrics() {
    scrollView.frame = contentView.frame
    if let image = imageView.image ?? imageView.currentImage {
      imageView.frame = resizedFrame(forSize: image.size)
    }
    scrollView.contentSize = imageView.bounds.size
    scrollView.contentInset = contentInsetForScrollView(atScale: scrollView.zoomScale)
  }

  private func resizedFrame(forSize size: CGSize) -> CGRect {
    var frame = contentView.bounds
    let screenWidth = frame.width * scrollView.zoomScale
    let screenHeight = frame.height * scrollView.zoomScale
    var targetWidth = screenWidth
    var targetHeight = screenHeight
    let nativeWidth = max(size.width, screenWidth)
    let nativeHeight = max(size.height, screenHeight)

    if nativeHeight > nativeWidth {
      if screenHeight / screenWidth < nativeHeight / nativeWidth {
        targetWidth = screenHeight / (nativeHeight / nativeWidth)
      } else {
        targetHeight = screenWidth / (nativeWidth / nativeHeight)
      }
    } else {
      if screenWidth / screenHeight < nativeWidth / nativeHeight {
        targetHeight = screenWidth / (nativeWidth / nativeHeight)
      } else {
        targetWidth = screenHeight / (nativeHeight / nativeWidth)
      }
    }

    frame.size = CGSize(width: targetWidth, height: targetHeight)
    return frame.integral
  }

  private func startImageDragging(_ locationInView: CGPoint, translationOffset: UIOffset) {
    imageDragStartingPoint = locationInView
    imageDragOffsetFromActualTranslation = translationOffset

    let anchor = imageDragStartingPoint
    let imageCenter = imageView.center
    let offset = UIOffset(horizontal: locationInView.x - imageCenter.x, vertical: locationInView.y - imageCenter.y)
    imageDragOffsetFromImageCenter = offset

    if let panPhysics = panPhysics {
      attachmentBehavior = UIAttachmentBehavior(item: imageView, offsetFromCenter: offset, attachedToAnchor: anchor!)
      animator!.addBehavior(attachmentBehavior!)
      
      let modifier = UIDynamicItemBehavior(items: [imageView])
      modifier.angularResistance = angularResistance(in: imageView)
      modifier.density = density(in: imageView)
      modifier.allowsRotation = panPhysics.allowsRotation
      animator!.addBehavior(modifier)
    }
  }

  private func angularResistance(in view: UIView) -> CGFloat {
    let defaultResistance: CGFloat = 4
    return appropriateValue(defaultValue: defaultResistance) * factor(forView: view)
  }

  private func density(in view: UIView) -> CGFloat {
    let defaultDensity: CGFloat = 0.5
    return appropriateValue(defaultValue: defaultDensity) * factor(forView: view)
  }

  private func appropriateValue(defaultValue: CGFloat) -> CGFloat {
    let screenWidth = UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width
    let screenHeight = UIApplication.shared.windows.first?.bounds.height ?? UIScreen.main.bounds.height
    // Default value that works well for the screenSize adjusted for the actual size of the device
    return defaultValue * ((320 * 480) / (screenWidth * screenHeight))
  }

  private func factor(forView view: UIView) -> CGFloat {
    let actualArea = view.bounds.width * view.bounds.height
    let referenceArea = contentView.bounds.height * contentView.bounds.width
    return referenceArea / actualArea
  }

}

extension AgrumeCell: UIScrollViewDelegate {

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    imageView
  }

  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    scrollView.contentInset = contentInsetForScrollView(atScale: scrollView.zoomScale)

    if !scrollView.isScrollEnabled {
      scrollView.isScrollEnabled = true
    }
  }

  func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
    scrollView.isScrollEnabled = scale > 1
    scrollView.contentInset = contentInsetForScrollView(atScale: scale)
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    let highVelocity: CGFloat = .highScrollVelocity
    let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView.panGestureRecognizer.view)
    if notZoomed && (abs(velocity.x) > highVelocity || abs(velocity.y) > highVelocity) {
      dismiss()
    }
  }
}
