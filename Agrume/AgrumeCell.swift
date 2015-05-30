//
//  AgrumeCell.swift
//  Agrume
//
//  Created by Jan Gorman on 30/05/15.
//  Copyright (c) 2015 Schnaub. All rights reserved.
//

import UIKit

class AgrumeCell: UICollectionViewCell {
    
    private static let TargetZoomForDoubleTap: CGFloat = 3
    private static let MinFlickDismissalVelocity: CGFloat = 800
    private static let HighScrollVelocity: CGFloat = 1600
    
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!
    
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
        
        scrollView = UIScrollView(frame: contentView.bounds)
        scrollView.delegate = self
        scrollView.zoomScale = 1
        scrollView.maximumZoomScale = 8
        scrollView.scrollEnabled = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        contentView.addSubview(scrollView)
        
        imageView = UIImageView(frame: contentView.bounds)
        imageView.contentMode = .ScaleAspectFit
        imageView.userInteractionEnabled = true
        imageView.clipsToBounds = true
        imageView.layer.allowsEdgeAntialiasing = true
        imageView.image = image
        scrollView.addSubview(imageView)
        
        setupGestureRecognizers()
        
        animator = UIDynamicAnimator(referenceView: scrollView)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func prepareForReuse() {
        scrollView.zoomScale = 1
        updateScrollViewAndImageViewForCurrentMetrics()
    }
    
    private var singleTapGesture: UITapGestureRecognizer!
    private var doubleTapGesture: UITapGestureRecognizer!
    private var panGesture: UIPanGestureRecognizer!
    var swipeGesture: UISwipeGestureRecognizer!
    
    private var flickedToDismiss: Bool = false
    private var isDraggingImage: Bool = false
    private var imageDragStartingPoint: CGPoint!
    private var imageDragOffsetFromActualTranslation: UIOffset!
    private var imageDragOffsetFromImageCenter: UIOffset!
    private var animator: UIDynamicAnimator!
    private var attachmentBehavior: UIAttachmentBehavior?
    
    private func setupGestureRecognizers() {
        doubleTapGesture = UITapGestureRecognizer(target: self, action: Selector("doubleTap:"))
        doubleTapGesture.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTapGesture)
        
        singleTapGesture = UITapGestureRecognizer(target: self, action: Selector("singleTap:"))
        singleTapGesture.requireGestureRecognizerToFail(doubleTapGesture)
        singleTapGesture.delegate = self
        
        contentView.addGestureRecognizer(singleTapGesture)
        
        panGesture = UIPanGestureRecognizer(target: self, action: Selector("dismissPan:"))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        scrollView.addGestureRecognizer(panGesture)
        
        swipeGesture = UISwipeGestureRecognizer(target: self, action:  nil)
        swipeGesture.direction = .Left | .Right
        swipeGesture.delegate = self
        
        contentView.addGestureRecognizer(swipeGesture)
    }
    
}

extension AgrumeCell: UIGestureRecognizerDelegate {
    
    // MARK: UIGestureRecognizerDelegate
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer where scrollView.zoomScale == 1 {
            let velocity = pan.velocityInView(scrollView)
            return abs(velocity.y) > abs(velocity.x)
        } else if let swipe = gestureRecognizer as? UISwipeGestureRecognizer where scrollView.zoomScale == 1 {
            return false
        } else if let tap = gestureRecognizer as? UITapGestureRecognizer where tap == singleTapGesture && scrollView.zoomScale != 1 {
            return false
        }
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            return scrollView.zoomScale == 1
        }
        return true
    }
    
    func doubleTap(sender: UITapGestureRecognizer) {
        let rawLocation = sender.locationInView(sender.view)
        let point = scrollView.convertPoint(rawLocation, fromView: sender.view)
        
        let targetZoom: CGRect
        let targetInsets: UIEdgeInsets
        if scrollView.zoomScale == 1 {
            let zoomWidth = CGRectGetWidth(contentView.bounds) / AgrumeCell.TargetZoomForDoubleTap
            let zoomHeight = CGRectGetHeight(contentView.bounds) / AgrumeCell.TargetZoomForDoubleTap
            targetZoom = CGRect(x: point.x - zoomWidth / 2, y: point.y / zoomWidth / 2, width: zoomWidth, height: zoomHeight)
            targetInsets = contentInsetForScrollView(atScale: AgrumeCell.TargetZoomForDoubleTap)
        } else {
            let zoomWidth = CGRectGetWidth(contentView.bounds) * scrollView.zoomScale
            let zoomHeight = CGRectGetHeight(contentView.bounds) * scrollView.zoomScale
            targetZoom = CGRect(x: point.x - zoomWidth / 2, y: point.y / zoomWidth / 2, width: zoomWidth, height: zoomHeight)
            targetInsets = contentInsetForScrollView(atScale: 1)
        }
        
        contentView.userInteractionEnabled = false
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            [weak self] in
            self?.scrollView.contentInset = targetInsets
            self?.contentView.userInteractionEnabled = true
        }
        scrollView.zoomToRect(targetZoom, animated: true)
        CATransaction.commit()
    }
    
    private func contentInsetForScrollView(#atScale: CGFloat) -> UIEdgeInsets {
        let boundsWidth = CGRectGetWidth(scrollView.bounds)
        let boundsHeight = CGRectGetHeight(scrollView.bounds)
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
        if minContentWidth > CGRectGetWidth(contentView.bounds) && minContentHeight > CGRectGetHeight(contentView.bounds) {
            inset = UIEdgeInsetsZero
        } else {
            let verticalDiff = max(boundsHeight - minContentHeight, 0)
            let horizontalDiff = max(boundsWidth - minContentWidth, 0)
            inset = UIEdgeInsets(top: verticalDiff / 2, left: horizontalDiff / 2, bottom: verticalDiff / 2, right: horizontalDiff / 2)
        }
        return inset
    }
    
    func singleTap(gesture: UITapGestureRecognizer) {
        dismiss()
    }
    
    private func dismiss() {
        if flickedToDismiss {
            dismissAfterFlick()
        } else {
            dismissByExpanding()
        }
    }
    
    func dismissPan(gesture: UIPanGestureRecognizer) {
        var translation = gesture.translationInView(gesture.view!)
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
        push.action = {
            [unowned self] in
            if self.isImageViewOffscreen() {
                self.animator.removeAllBehaviors()
                self.attachmentBehavior = nil
                self.imageView.removeFromSuperview()
                self.dismiss()
            }
        }
        animator.removeBehavior(attachmentBehavior)
        animator.addBehavior(push)
    }
    
    func isImageViewOffscreen() -> Bool {
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
                options: .AllowUserInteraction | .BeginFromCurrentState,
                animations: {
                    if !self.isDraggingImage {
                        self.imageView.transform = CGAffineTransformIdentity
                        if !self.scrollView.dragging && !self.scrollView.decelerating {
                            self.imageView.center = CGPoint(x: self.scrollView.contentSize.width / 2,
                                y: self.scrollView.contentSize.height / 2)
                            self.updateScrollViewAndImageViewForCurrentMetrics()
                        }
                    }
                },
                completion: nil)
        }
    }
    
    private func updateScrollViewAndImageViewForCurrentMetrics() {
        let supressAdjustments = false
        if !supressAdjustments {
            if let image = self.imageView.image {
                imageView.frame = resizedFrameForSize(image.size)
            }
            scrollView.contentSize = imageView.frame.size
            scrollView.contentInset = contentInsetForScrollView(atScale: scrollView.zoomScale)
        }
    }
    
    private func resizedFrameForSize(imageSize: CGSize) -> CGRect {
        var frame = contentView.bounds
        let screenWidth = CGRectGetWidth(frame) * scrollView.zoomScale
        let screenHeight = CGRectGetHeight(frame) * scrollView.zoomScale
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
        animator.addBehavior(attachmentBehavior)
        
        let modifier = UIDynamicItemBehavior(items: [imageView])
        modifier.angularResistance = angularResistance(view: imageView)
        modifier.density = density(view: imageView)
        animator.addBehavior(modifier)
    }
    
    private func angularResistance(#view: UIView) -> CGFloat {
        let defaultResistance: CGFloat = 4
        return appropriateValue(defaultValue: defaultResistance) * factor(forView: view)
    }
    
    private func density(#view: UIView) -> CGFloat {
        let defaultDensity: CGFloat = 0.5
        return appropriateValue(defaultValue: defaultDensity) * factor(forView: view)
    }
    
    private func appropriateValue(#defaultValue: CGFloat) -> CGFloat {
        let screenWidth = CGRectGetWidth(UIScreen.mainScreen().bounds)
        let screenHeight = CGRectGetHeight(UIScreen.mainScreen().bounds)
        return defaultValue * ((320 * 480) / (screenWidth * screenHeight))
    }
    
    private func factor(forView view: UIView) -> CGFloat {
        let actualArea = CGRectGetHeight(contentView.bounds) * CGRectGetWidth(view.bounds)
        let referenceArea = CGRectGetHeight(contentView.bounds) * CGRectGetWidth(contentView.bounds)
        return referenceArea / actualArea
    }
    
}

extension AgrumeCell: UIScrollViewDelegate {
    
    // MARK: UIScrollViewDelegate
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        scrollView.contentInset = contentInsetForScrollView(atScale: scrollView.zoomScale)
        
        if !scrollView.scrollEnabled {
            scrollView.scrollEnabled = true
        }
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView!, atScale scale: CGFloat) {
        scrollView.scrollEnabled = scale > 1
        scrollView.contentInset = contentInsetForScrollView(atScale: scale)
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let highVelocity = AgrumeCell.HighScrollVelocity
        let velocity = scrollView.panGestureRecognizer.velocityInView(scrollView.panGestureRecognizer.view)
        if scrollView.zoomScale == 1 && (fabs(velocity.x) > highVelocity || fabs(velocity.y) > highVelocity) {
            dismiss()
        }
    }
    
}
