//
//  Copyright © 2018 Schnaub. All rights reserved.
//

import UIKit

extension UIView {
  
  final func snapshot() -> UIImage {
    UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0)
    drawHierarchy(in: bounds, afterScreenUpdates: true)
    let snapshot = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return snapshot!
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
