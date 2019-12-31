//
//  Copyright © 2018 Schnaub. All rights reserved.
//

import UIKit

public struct AgrumeImage: Equatable {
  
  public var image: UIImage?
  public var url: URL?
  public var title: NSAttributedString?
  
  private init(image: UIImage?, url: URL?, title: NSAttributedString?) {
    self.image = image
    self.url = url
    self.title = title
  }
  
  public init(image: UIImage, title: NSAttributedString? = nil) {
    self.init(image: image, url: nil, title: title)
  }
  
  public init(url: URL, title: NSAttributedString? = nil) {
    self.init(image: nil, url: url, title: title)
  }
  
}
