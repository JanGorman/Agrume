//
//  Copyright © 2018 Schnaub. All rights reserved.
//

import UIKit

/// The background type
public enum Background {
  /// Overlay with a color
  case colored(UIColor)
  /// Overlay with a UIBlurEffectStyle
  case blurred(UIBlurEffectStyle)
}
