//
//  Copyright © 2019 Schnaub. All rights reserved.
//

import Foundation

public func with<T>(_ value: T, _ modifier: (inout T) -> Void) -> T {
  var value = value
  modifier(&value)
  return value
}
