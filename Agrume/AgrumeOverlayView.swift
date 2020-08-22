//
//  Copyright © 2018 Schnaub. All rights reserved.
//

import UIKit

protocol AgrumeCloseButtonOverlayViewDelegate: AnyObject {
  func agrumeOverlayViewWantsToClose(_ view: AgrumeCloseButtonOverlayView)
}

/// A base class for a user defined view that will overlay the image.
///
/// An overlay view can be used to add navigation, actions, or information over the image.
open class AgrumeOverlayView: UIView {
  override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    if let view = super.hitTest(point, with: event), view != self {
      return view
    }
    return nil
  }
}

final class AgrumeCloseButtonOverlayView: AgrumeOverlayView {
  
  weak var delegate: AgrumeCloseButtonOverlayViewDelegate?

  private lazy var navigationBar = with(UINavigationBar()) { navigationBar in
    navigationBar.usesAutoLayout(true)
    navigationBar.backgroundColor = .clear
    navigationBar.isTranslucent = true
    navigationBar.shadowImage = UIImage()
    navigationBar.setBackgroundImage(UIImage(), for: .default)
    navigationBar.items = [navigationItem]
  }
  
  private lazy var navigationItem = UINavigationItem(title: "")
  private lazy var defaultCloseButton = UIBarButtonItem(
    title: NSLocalizedString("Close", comment: "Close image view"),
    style: .plain, target: self, action: #selector(close)
  )
  
  init(closeButton: UIBarButtonItem?) {
    super.init(frame: .zero)

    addSubview(navigationBar)

    if let closeButton = closeButton {
      closeButton.target = self
      closeButton.action = #selector(close)
      navigationItem.leftBarButtonItem = closeButton
    } else {
      navigationItem.leftBarButtonItem = defaultCloseButton
    }
    
    NSLayoutConstraint.activate([
      navigationBar.topAnchor.constraint(equalTo: portableSafeTopInset),
      navigationBar.widthAnchor.constraint(equalTo: widthAnchor),
      navigationBar.centerXAnchor.constraint(equalTo: centerXAnchor)
    ])
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @objc
  private func close() {
    delegate?.agrumeOverlayViewWantsToClose(self)
  }
  
}
