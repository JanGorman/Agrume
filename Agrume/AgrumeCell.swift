//
//  AgrumeCell.swift
//  Agrume
//

import UIKit

final class AgrumeCell: UICollectionViewCell {

  private static let TargetZoomForDoubleTap: CGFloat = 3
  private static let MinFlickDismissalVelocity: CGFloat = 800
  private static let HighScrollVelocity: CGFloat = 1600

  private lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView(frame: self.contentView.bounds)
    scrollView.delegate = self
    scrollView.zoomScale = 1
    scrollView.maximumZoomScale = 8
    scrollView.scrollEnabled = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false
    return scrollView
  }()
  private lazy var imageView: UIImageView = {
    let imageView = UIImageView(frame: self.contentView.bounds)
    imageView.contentMode = .ScaleAspectFit
    imageView.userInteractionEnabled = true
    imageView.clipsToBounds = true
    imageView.layer.allowsEdgeAntialiasing = true
    return imageView
  }()
  private var animator: UIDynamicAnimator!

  var image: UIImage? {
    didSet {
      imageView.image = image
      updateScrollViewAndImageViewForCurrentMetrics()
    }
  }
  var dismissAfterFlick: (() -> Void)!
  var dismissByExpanding: (() -> Void)!

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = UIColor.clearColor()

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

  private lazy var singleTapGesture: UITapGestureRecognizer = {
    let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(AgrumeCell.singleTap(_:)))
    singleTapGesture.requireGestureRecognizerToFail(self.doubleTapGesture)
    singleTapGesture.delegate = self
    return singleTapGesture
  }()
  private lazy var doubleTapGesture: UITapGestureRecognizer = {
    let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(AgrumeCell.doubleTap(_:)))
    doubleTapGesture.numberOfTapsRequired = 2
    return doubleTapGesture
  }()
  private lazy var panGesture: UIPanGestureRecognizer = {
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(AgrumeCell.dismissPan(_:)))
    panGesture.maximumNumberOfTouches = 1
    panGesture.delegate = self
    return panGesture
  }()
  lazy var swipeGesture: UISwipeGestureRecognizer = {
    let swipeGesture = UISwipeGestureRecognizer(target: self, action: nil)
    swipeGesture.direction = [.Left, .Right]
    swipeGesture.delegate = self
    return swipeGesture
  }()

  private var flickedToDismiss: Bool = false
  private var isDraggingImage: Bool = false
  private var imageDragStartingPoint: CGPoint!
  private var imageDragOffsetFromActualTranslation: UIOffset!
  private var imageDragOffsetFromImageCenter: UIOffset!
  private var attachmentBehavior: UIAttachmentBehavior?

  private func setupGestureRecognizers() {
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

  override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let pan = gestureRecognizer as? UIPanGestureRecognizer where notZoomed() {
      let velocity = pan.velocityInView(scrollView)
      return abs(velocity.y) > abs(velocity.x)
    } else if let _ = gestureRecognizer as? UISwipeGestureRecognizer where notZoomed() {
      return false
    } else if let tap = gestureRecognizer as? UITapGestureRecognizer where tap == singleTapGesture && !notZoomed() {
      return false
    }
    return true
  }

  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
    if let _ = gestureRecognizer as? UIPanGestureRecognizer {
      return notZoomed()
    }
    return true
  }

  @objc private func doubleTap(sender: UITapGestureRecognizer) {
    let point = scrollView.convertPoint(sender.locationInView(sender.view), fromView: sender.view)
    let targetZoom: CGRect
    let targetInsets: UIEdgeInsets
    if notZoomed() {
      let zoomWidth = contentView.bounds.width / AgrumeCell.TargetZoomForDoubleTap
      let zoomHeight = contentView.bounds.height / AgrumeCell.TargetZoomForDoubleTap
      targetZoom = CGRect(x: point.x - zoomWidth / 2, y: point.y / zoomWidth / 2, width: zoomWidth, height: zoomHeight)
      targetInsets = contentInsetForScrollView(atScale: AgrumeCell.TargetZoomForDoubleTap)
    } else {
      let zoomWidth = contentView.bounds.width * scrollView.zoomScale
      let zoomHeight = contentView.bounds.height * scrollView.zoomScale
      targetZoom = CGRect(x: point.x - zoomWidth / 2, y: point.y / zoomWidth / 2, width: zoomWidth, height: zoomHeight)
      targetInsets = contentInsetForScrollView(atScale: 1)
    }

    contentView.userInteractionEnabled = false

    CATransaction.begin()
    CATransaction.setCompletionBlock { [weak self] in
      self?.scrollView.contentInset = targetInsets
      self?.contentView.userInteractionEnabled = true
    }
    scrollView.zoomToRect(targetZoom, animated: true)
    CATransaction.commit()
  }

  private func contentInsetForScrollView(atScale atScale: CGFloat) -> UIEdgeInsets {
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

    let inset: UIEdgeInsets
    if minContentWidth > contentView.bounds.width && minContentHeight > contentView.bounds.height {
      inset = UIEdgeInsetsZero
    } else {
      let verticalDiff = max(boundsHeight - minContentHeight, 0)
      let horizontalDiff = max(boundsWidth - minContentWidth, 0)
      inset = UIEdgeInsets(top: verticalDiff / 2, left: horizontalDiff / 2, bottom: verticalDiff / 2, right: horizontalDiff / 2)
    }
    return inset
  }

  @objc private func singleTap(gesture: UITapGestureRecognizer) {
    dismiss()
  }

  private func dismiss() {
    if flickedToDismiss {
      dismissAfterFlick()
    } else {
      dismissByExpanding()
    }
  }

  @objc private func dismissPan(gesture: UIPanGestureRecognizer) {
    let translation = gesture.translationInView(gesture.view!)
    let locationInView = gesture.locationInView(gesture.view)
    let velocity = gesture.velocityInView(gesture.view)
    let vectorDistance = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2))

    if gesture.state == .Began {
      isDraggingImage = CGRectContainsPoint(imageView.frame, locationInView)
      if isDraggingImage {
        startImageDragging(locationInView, translationOffset: UIOffsetZero)
      }
    } else if gesture.state == .Changed {
      if isDraggingImage {
        var newAnchor = imageDragStartingPoint
        newAnchor.x += translation.x + imageDragOffsetFromActualTranslation.horizontal
        newAnchor.y += translation.y + imageDragOffsetFromActualTranslation.vertical
        attachmentBehavior?.anchorPoint = newAnchor
      } else {
        isDraggingImage = CGRectContainsPoint(imageView.frame, locationInView)
        if isDraggingImage {
          let translationOffset = UIOffset(horizontal: -1 * translation.x, vertical: -1 * translation.y)
          startImageDragging(locationInView, translationOffset: translationOffset)
        }
      }
    } else {
      if vectorDistance > AgrumeCell.MinFlickDismissalVelocity {
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

  private func dismissWithFlick(velocity: CGPoint) {
    flickedToDismiss = true

    let push = UIPushBehavior(items: [imageView], mode: .Instantaneous)
    push.pushDirection = CGVector(dx: velocity.x * 0.1, dy: velocity.y * 0.1)
    push.setTargetOffsetFromCenter(imageDragOffsetFromImageCenter, forItem: imageView)
    push.action = pushAction
    animator.removeBehavior(attachmentBehavior!)
    animator.addBehavior(push)
  }
  
  private func pushAction() {
    if self.isImageViewOffscreen() {
      self.animator.removeAllBehaviors()
      self.attachmentBehavior = nil
      self.imageView.removeFromSuperview()
      self.dismiss()
    }
  }

  private func isImageViewOffscreen() -> Bool {
    let visibleRect = scrollView.convertRect(contentView.bounds, fromView: contentView)
    return animator.itemsInRect(visibleRect).count == 0
  }

  private func cancelCurrentImageDrag(animated: Bool) {
    animator.removeAllBehaviors()
    attachmentBehavior = nil
    isDraggingImage = false

    if !animated {
      imageView.transform = CGAffineTransformIdentity
      imageView.center = CGPoint(x: scrollView.contentSize.width / 2, y: scrollView.contentSize.height / 2)
    } else {
      UIView.animateWithDuration(0.7,
                                 delay: 0,
                                 usingSpringWithDamping: 0.7,
                                 initialSpringVelocity: 0,
                                 options: [.AllowUserInteraction, .BeginFromCurrentState],
                                 animations: {
                                  if !self.isDraggingImage {
                                    self.imageView.transform = CGAffineTransformIdentity
                                    if !self.scrollView.dragging && !self.scrollView.decelerating {
                                      self.imageView.center = CGPoint(x: self.scrollView.contentSize.width / 2,
                                        y: self.scrollView.contentSize.height / 2)
                                      self.updateScrollViewAndImageViewForCurrentMetrics()
                                    }
                                  }
                                }, completion: nil)
      }
  }

  func updateScrollViewAndImageViewForCurrentMetrics() {
    scrollView.frame = contentView.bounds
    if let image = self.imageView.image {
      imageView.frame = resizedFrameForSize(image.size)
    }
    scrollView.contentSize = imageView.frame.size
    scrollView.contentInset = contentInsetForScrollView(atScale: scrollView.zoomScale)
  }

  private func resizedFrameForSize(imageSize: CGSize) -> CGRect {
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
    frame.origin = CGPointZero
    return frame
  }

  private func startImageDragging(locationInView: CGPoint, translationOffset: UIOffset) {
    imageDragStartingPoint = locationInView
    imageDragOffsetFromActualTranslation = translationOffset

    let anchor = imageDragStartingPoint
    let imageCenter = imageView.center
    let offset = UIOffset(horizontal: locationInView.x - imageCenter.x, vertical: locationInView.y - imageCenter.y)
    imageDragOffsetFromImageCenter = offset
    attachmentBehavior = UIAttachmentBehavior(item: imageView, offsetFromCenter: offset, attachedToAnchor: anchor)
    animator.addBehavior(attachmentBehavior!)

    let modifier = UIDynamicItemBehavior(items: [imageView])
    modifier.angularResistance = angularResistance(view: imageView)
    modifier.density = density(view: imageView)
    animator.addBehavior(modifier)
  }

  private func angularResistance(view view: UIView) -> CGFloat {
    let defaultResistance: CGFloat = 4
    return appropriateValue(defaultValue: defaultResistance) * factor(forView: view)
  }

  private func density(view view: UIView) -> CGFloat {
    let defaultDensity: CGFloat = 0.5
    return appropriateValue(defaultValue: defaultDensity) * factor(forView: view)
  }

  private func appropriateValue(defaultValue defaultValue: CGFloat) -> CGFloat {
    let screenWidth = UIScreen.mainScreen().bounds.width
    let screenHeight = UIScreen.mainScreen().bounds.height
    // Default value that works well for the screenSize adjusted for the actual size of the device
    return defaultValue * ((320 * 480) / (screenWidth * screenHeight))
  }

  private func factor(forView view: UIView) -> CGFloat {
    let actualArea = contentView.bounds.height * view.bounds.height
    let referenceArea = contentView.bounds.height * contentView.bounds.width
    return referenceArea / actualArea
  }

}

extension AgrumeCell: UIScrollViewDelegate {

  func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
    return imageView
  }

  func scrollViewDidZoom(scrollView: UIScrollView) {
    scrollView.contentInset = contentInsetForScrollView(atScale: scrollView.zoomScale)

    if !scrollView.scrollEnabled {
      scrollView.scrollEnabled = true
    }
  }

  func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
    scrollView.scrollEnabled = scale > 1
    scrollView.contentInset = contentInsetForScrollView(atScale: scale)
  }

  func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    let highVelocity = AgrumeCell.HighScrollVelocity
    let velocity = scrollView.panGestureRecognizer.velocityInView(scrollView.panGestureRecognizer.view)
    if notZoomed() && (fabs(velocity.x) > highVelocity || fabs(velocity.y) > highVelocity) {
      dismiss()
    }
  }

}
