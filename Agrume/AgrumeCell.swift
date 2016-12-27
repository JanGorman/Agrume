//
//  AgrumeCell.swift
//  Agrume
//

import UIKit

protocol AgrumeCellDelegate: class {
  
  func dismissAfterFlick()
  func dismissAfterTap()
  
}

final class AgrumeCell: UICollectionViewCell {

  fileprivate static let targetZoomForDoubleTap: CGFloat = 3
  fileprivate static let minFlickDismissalVelocity: CGFloat = 800
  fileprivate static let highScrollVelocity: CGFloat = 1600

  fileprivate lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView(frame: self.contentView.bounds)
    scrollView.delegate = self
    scrollView.zoomScale = 1
    scrollView.maximumZoomScale = 8
    scrollView.isScrollEnabled = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false
    return scrollView
  }()
  fileprivate lazy var imageView: UIImageView = {
    let imageView = UIImageView(frame: self.contentView.bounds)
    imageView.contentMode = .scaleAspectFit
    imageView.isUserInteractionEnabled = true
    imageView.clipsToBounds = true
    imageView.layer.allowsEdgeAntialiasing = true
    return imageView
  }()
  fileprivate var animator: UIDynamicAnimator!

  var image: UIImage? {
    didSet {
      imageView.image = image
      updateScrollViewAndImageViewForCurrentMetrics()
    }
  }
  weak var delegate: AgrumeCellDelegate?

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = UIColor.clear
    contentView.addSubview(scrollView)
    scrollView.addSubview(imageView)
    setupGestureRecognizers()
    animator = UIDynamicAnimator(referenceView: scrollView)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override func prepareForReuse() {
    imageView.image = nil
    scrollView.zoomScale = 1
    updateScrollViewAndImageViewForCurrentMetrics()
  }

  fileprivate lazy var singleTapGesture: UITapGestureRecognizer = {
    let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTap))
    singleTapGesture.require(toFail: self.doubleTapGesture)
    singleTapGesture.delegate = self
    return singleTapGesture
  }()
  fileprivate lazy var doubleTapGesture: UITapGestureRecognizer = {
    let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
    doubleTapGesture.numberOfTapsRequired = 2
    return doubleTapGesture
  }()
  fileprivate lazy var panGesture: UIPanGestureRecognizer = {
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(dismissPan))
    panGesture.maximumNumberOfTouches = 1
    panGesture.delegate = self
    return panGesture
  }()
  lazy var swipeGesture: UISwipeGestureRecognizer = {
    let swipeGesture = UISwipeGestureRecognizer(target: self, action: nil)
    swipeGesture.direction = [.left, .right]
    swipeGesture.delegate = self
    return swipeGesture
  }()

  fileprivate var flickedToDismiss = false
  fileprivate var isDraggingImage = false
  fileprivate var imageDragStartingPoint: CGPoint!
  fileprivate var imageDragOffsetFromActualTranslation: UIOffset!
  fileprivate var imageDragOffsetFromImageCenter: UIOffset!
  fileprivate var attachmentBehavior: UIAttachmentBehavior?

  fileprivate func setupGestureRecognizers() {
    contentView.addGestureRecognizer(singleTapGesture)
    contentView.addGestureRecognizer(doubleTapGesture)
    scrollView.addGestureRecognizer(panGesture)
    contentView.addGestureRecognizer(swipeGesture)
  }

}

extension AgrumeCell: UIGestureRecognizerDelegate {

  func notZoomed() -> Bool {
    return scrollView.zoomScale == 1
  }

  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let pan = gestureRecognizer as? UIPanGestureRecognizer, notZoomed() {
      let velocity = pan.velocity(in: scrollView)
      return abs(velocity.y) > abs(velocity.x)
    } else if let _ = gestureRecognizer as? UISwipeGestureRecognizer, notZoomed() {
      return false
    } else if let tap = gestureRecognizer as? UITapGestureRecognizer, tap == singleTapGesture && !notZoomed() {
      return false
    }
    return true
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    if let _ = gestureRecognizer as? UIPanGestureRecognizer {
      return notZoomed()
    }
    return true
  }

  @objc fileprivate func doubleTap(_ sender: UITapGestureRecognizer) {
    let point = scrollView.convert(sender.location(in: sender.view), from: sender.view)
    
    if notZoomed() {
      zoom(to: point, scale: AgrumeCell.targetZoomForDoubleTap)
    } else {
      zoom(to: .zero, scale: 1)
    }
  }
  
  private func zoom(to point: CGPoint, scale: CGFloat) {
    let factor = 1 / scrollView.zoomScale
    let translatedZoom = CGPoint(x: (point.x + scrollView.contentOffset.x) * factor,
                                 y: (point.y + scrollView.contentOffset.y) * factor)

    let width = scrollView.frame.width / scale
    let height = scrollView.frame.height / scale
    let destination = CGRect(x: translatedZoom.x - width  / 2, y: translatedZoom.y - height / 2, width: width, height: height)

    contentView.isUserInteractionEnabled = false
    
    CATransaction.begin()
    CATransaction.setCompletionBlock { [unowned self] in
      self.contentView.isUserInteractionEnabled = true
    }
    scrollView.zoom(to: destination, animated: true)
    CATransaction.commit()
  }

  fileprivate func contentInsetForScrollView(atScale: CGFloat) -> UIEdgeInsets {
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

  @objc fileprivate func singleTap(_ gesture: UITapGestureRecognizer) {
    dismiss()
  }

  fileprivate func dismiss() {
    if flickedToDismiss {
      delegate?.dismissAfterFlick()
    } else {
      delegate?.dismissAfterTap()
    }
  }

  @objc fileprivate func dismissPan(_ gesture: UIPanGestureRecognizer) {
    let translation = gesture.translation(in: gesture.view!)
    let locationInView = gesture.location(in: gesture.view)
    let velocity = gesture.velocity(in: gesture.view)
    let vectorDistance = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2))

    if gesture.state == .began {
      isDraggingImage = imageView.frame.contains(locationInView)
      if isDraggingImage {
        startImageDragging(locationInView, translationOffset: .zero)
      }
    } else if gesture.state == .changed {
      if isDraggingImage {
        var newAnchor = imageDragStartingPoint
        newAnchor?.x += translation.x + imageDragOffsetFromActualTranslation.horizontal
        newAnchor?.y += translation.y + imageDragOffsetFromActualTranslation.vertical
        attachmentBehavior?.anchorPoint = newAnchor!
      } else {
        isDraggingImage = imageView.frame.contains(locationInView)
        if isDraggingImage {
          let translationOffset = UIOffset(horizontal: -1 * translation.x, vertical: -1 * translation.y)
          startImageDragging(locationInView, translationOffset: translationOffset)
        }
      }
    } else {
      if vectorDistance > AgrumeCell.minFlickDismissalVelocity {
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

  fileprivate func dismissWithFlick(_ velocity: CGPoint) {
    flickedToDismiss = true

    let push = UIPushBehavior(items: [imageView], mode: .instantaneous)
    push.pushDirection = CGVector(dx: velocity.x * 0.1, dy: velocity.y * 0.1)
    push.setTargetOffsetFromCenter(imageDragOffsetFromImageCenter, for: imageView)
    push.action = pushAction
    animator.removeBehavior(attachmentBehavior!)
    animator.addBehavior(push)
  }
  
  fileprivate func pushAction() {
    if isImageViewOffscreen() {
      animator.removeAllBehaviors()
      attachmentBehavior = nil
      imageView.removeFromSuperview()
      dismiss()
    }
  }

  fileprivate func isImageViewOffscreen() -> Bool {
    let visibleRect = scrollView.convert(contentView.bounds, from: contentView)
    return animator.items(in: visibleRect).count == 0
  }

  fileprivate func cancelCurrentImageDrag(_ animated: Bool) {
    animator.removeAllBehaviors()
    attachmentBehavior = nil
    isDraggingImage = false

    if !animated {
      imageView.transform = .identity
      imageView.center = CGPoint(x: scrollView.contentSize.width / 2, y: scrollView.contentSize.height / 2)
    } else {
      UIView.animate(withDuration: 0.7,
                     delay: 0,
                     usingSpringWithDamping: 0.7,
                     initialSpringVelocity: 0,
                     options: [.allowUserInteraction, .beginFromCurrentState],
                     animations: { [unowned self] in
                      guard !self.isDraggingImage else { return }
                      
                      self.imageView.transform = CGAffineTransform.identity
                      if !self.scrollView.isDragging && !self.scrollView.isDecelerating {
                        self.imageView.center = CGPoint(x: self.scrollView.contentSize.width / 2,
                                                        y: self.scrollView.contentSize.height / 2)
                        self.updateScrollViewAndImageViewForCurrentMetrics()
                      }
        }, completion: nil)
      }
  }

  func updateScrollViewAndImageViewForCurrentMetrics() {
    scrollView.frame = contentView.bounds
    if let image = imageView.image {
      imageView.frame = resizedFrameForSize(image.size)
    }
    scrollView.contentSize = imageView.frame.size
    scrollView.contentInset = contentInsetForScrollView(atScale: scrollView.zoomScale)
  }

  fileprivate func resizedFrameForSize(_ imageSize: CGSize) -> CGRect {
    var frame = contentView.bounds
    let screenWidth = frame.width * scrollView.zoomScale
    let screenHeight = frame.height * scrollView.zoomScale
    var targetWidth = screenWidth
    var targetHeight = screenHeight
    let nativeWidth = max(imageSize.width, screenWidth)
    let nativeHeight = max(imageSize.height, screenHeight)

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
    frame.origin = .zero
    return frame
  }

  fileprivate func startImageDragging(_ locationInView: CGPoint, translationOffset: UIOffset) {
    imageDragStartingPoint = locationInView
    imageDragOffsetFromActualTranslation = translationOffset

    let anchor = imageDragStartingPoint
    let imageCenter = imageView.center
    let offset = UIOffset(horizontal: locationInView.x - imageCenter.x, vertical: locationInView.y - imageCenter.y)
    imageDragOffsetFromImageCenter = offset
    attachmentBehavior = UIAttachmentBehavior(item: imageView, offsetFromCenter: offset, attachedToAnchor: anchor!)
    animator.addBehavior(attachmentBehavior!)

    let modifier = UIDynamicItemBehavior(items: [imageView])
    modifier.angularResistance = angularResistance(view: imageView)
    modifier.density = density(view: imageView)
    animator.addBehavior(modifier)
  }

  fileprivate func angularResistance(view: UIView) -> CGFloat {
    let defaultResistance: CGFloat = 4
    return appropriateValue(defaultValue: defaultResistance) * factor(forView: view)
  }

  fileprivate func density(view: UIView) -> CGFloat {
    let defaultDensity: CGFloat = 0.5
    return appropriateValue(defaultValue: defaultDensity) * factor(forView: view)
  }

  fileprivate func appropriateValue(defaultValue: CGFloat) -> CGFloat {
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    // Default value that works well for the screenSize adjusted for the actual size of the device
    return defaultValue * ((320 * 480) / (screenWidth * screenHeight))
  }

  fileprivate func factor(forView view: UIView) -> CGFloat {
    let actualArea = contentView.bounds.height * view.bounds.height
    let referenceArea = contentView.bounds.height * contentView.bounds.width
    return referenceArea / actualArea
  }

}

extension AgrumeCell: UIScrollViewDelegate {

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageView
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
    let highVelocity = AgrumeCell.highScrollVelocity
    let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView.panGestureRecognizer.view)
    if notZoomed() && (fabs(velocity.x) > highVelocity || fabs(velocity.y) > highVelocity) {
      dismiss()
    }
  }

}
