//
//  UIViewExtensions.swift
//  Agrume
//
//  Created by Jan Gorman on 28/05/15.
//  Copyright (c) 2015 Schnaub. All rights reserved.
//

import UIKit

extension UIView {
    
    func snapshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0)
        drawViewHierarchyInRect(bounds, afterScreenUpdates: true)
        let snapshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshot
    }

}
