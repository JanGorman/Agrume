//
//  Copyright © 2018 Schnaub. All rights reserved.
//

import UIKit

/// The background type
///
/// - colored: Overlay with a color
/// - blurred: Overlay with a UIBlurEffectStyle
public enum Background {
  case colored(UIColor)
  case blurred(UIBlurEffect.Style)
}

/// Control the way Agrume is dismissed
///
/// - withPhysics: Allow dragging the images and "throwing" them off screen to dismiss Agrume
/// - withButton: Overlay with a close button. Pass an optional `UIBarButtonItem` to control the look
/// - withPhysicsAndButton: Combines both behaviours. Physics and the close button all in one
public enum Dismissal {
  case withPhysics
  case withButton(UIBarButtonItem?)
  case withPhysicsAndButton(UIBarButtonItem?)
}
