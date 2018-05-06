//
//  Copyright © 2018 Schnaub. All rights reserved.
//

import UIKit

public protocol AgrumeDataSource: AnyObject {
  
  /// The number of images contained in the data source
  var numberOfImages: Int { get }
  
  /// Return the image for the passed in index
  ///
  /// - Parameter index: The index (collection view item) being displayed
  /// - Parameter completion: The completion that returns the image to be shown at the index
  func image(forIndex index: Int, completion: @escaping (UIImage?) -> Void)
  
}
