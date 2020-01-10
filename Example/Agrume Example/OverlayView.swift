//
//  Copyright © 2020 Schnaub. All rights reserved.
//

import UIKit
import Agrume

protocol OverlayViewDelegate: AnyObject {
  func overlayView(_ overlayView: OverlayView, didSelectAction action: String)
}

/// Example custom image overlay
class OverlayView: AgrumeOverlayView {
  lazy var toolbar: UIToolbar = {
    let toolbar = UIToolbar()
    toolbar.translatesAutoresizingMaskIntoConstraints = false
    
    toolbar.setItems([
      UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(selectShare)),
      UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(selectDelete)),
      UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(selectDone))
    ], animated: false)
    
    return toolbar
  }()
  
  lazy var navigationBar: UINavigationBar = {
    let navigationBar = UINavigationBar()
    navigationBar.translatesAutoresizingMaskIntoConstraints = false
    navigationBar.pushItem(UINavigationItem(title: ""), animated: false)
    return navigationBar
  }()
  
  var portableSafeLayoutGuide: UILayoutGuide {
    if #available(iOS 11.0, *) {
      return safeAreaLayoutGuide
    }
    return layoutMarginsGuide
  }
  
  weak var delegate: OverlayViewDelegate?

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    addSubview(toolbar)

    NSLayoutConstraint.activate([
      toolbar.bottomAnchor.constraint(equalTo: portableSafeLayoutGuide.bottomAnchor),
      toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
      toolbar.trailingAnchor.constraint(equalTo: trailingAnchor)
    ])
    
    addSubview(navigationBar)
    
    NSLayoutConstraint.activate([
      navigationBar.topAnchor.constraint(equalTo: portableSafeLayoutGuide.topAnchor),
      navigationBar.leadingAnchor.constraint(equalTo: leadingAnchor),
      navigationBar.trailingAnchor.constraint(equalTo: trailingAnchor)
    ])
  }
  
  @objc
  private func selectShare() {
    delegate?.overlayView(self, didSelectAction: "share")
  }
  
  @objc
  private func selectDelete() {
    delegate?.overlayView(self, didSelectAction: "delete")
  }
  
  @objc
  private func selectDone() {
    delegate?.overlayView(self, didSelectAction: "done")
  }
}
