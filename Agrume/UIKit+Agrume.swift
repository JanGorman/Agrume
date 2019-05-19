//
//  Copyright © 2018 Schnaub. All rights reserved.
//

import UIKit

extension CGFloat {
  
  static let initialScaleToExpandFrom: CGFloat = 0.6
  static let maxScaleForExpandingOffscreen: CGFloat = 1.25
  static let targetZoomForDoubleTap: CGFloat = 3
  static let minFlickDismissalVelocity: CGFloat = 800
  static let highScrollVelocity: CGFloat = 1600
  
}

extension UIView {
  
  final func snapshot() -> UIImage {
    UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0)
    drawHierarchy(in: bounds, afterScreenUpdates: true)
    let snapshot = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return snapshot!
  }
  
  func snapshotView() -> UIView? {
    UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, 0)
    defer {
      UIGraphicsEndImageContext()
    }
    guard let context = UIGraphicsGetCurrentContext() else {
      return nil
    }
    layer.render(in: context)
    return UIImageView(image: UIGraphicsGetImageFromCurrentImageContext())
  }
  
  func usesAutoLayout(_ useAutoLayout: Bool) {
    translatesAutoresizingMaskIntoConstraints = !useAutoLayout
  }
  
  var portableSafeTopInset: NSLayoutYAxisAnchor {
    if #available(iOS 11.0, *) {
      return safeAreaLayoutGuide.topAnchor
    }
    return topAnchor
  }

}

extension UIColor {
  
  var isLight: Bool {
    var white: CGFloat = 0
    getWhite(&white, alpha: nil)
    return white > 0.5
  }

}

extension UICollectionView {
  
  func dequeue<T: UICollectionViewCell>(indexPath: IndexPath) -> T {
    let id = String(describing: T.self)
    return dequeue(id: id, indexPath: indexPath)
  }
  
  func dequeue<T: UICollectionViewCell>(id: String, indexPath: IndexPath) -> T {
    return dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! T
  }

}
