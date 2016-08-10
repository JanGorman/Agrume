//
//  UIViewExtensions.swift
//  Agrume
//

import UIKit

extension UIView {

  final func snapshot() -> UIImage {
    UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0)
    drawViewHierarchyInRect(bounds, afterScreenUpdates: true)
    let snapshot = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return snapshot
  }

}
