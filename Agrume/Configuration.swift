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
/// - withPan: Allow dragging the images and "throwing" them off screen to dismiss Agrume
/// - withButton: Overlay with a close button. Pass an optional `UIBarButtonItem` to control the look
/// - withPanAndButton: Combines both behaviours. Physics and the close button all in one
public enum Dismissal {
  /// Allowed pan directions.
  ///
  /// - horizontalAndVertical: Allow panning freely along X and Y axes
  /// - verticalOnly: Only allow panning along the Y axis
  public enum PanDirections {
    case horizontalAndVertical
    case verticalOnly
  }

  public struct Physics {
    /// Directions in which panning will work during flick gesture.
    let permittedDirections: PanDirections
    /// Magnitude of the push an image receives after flicking to dismiss. The `nil` value is equivalent to no force, see
    /// `UIPushBehavior.magnitude` documentation for the intuition behind non-`nil` values.
    let pushMagnitude: CGFloat?
    /// Enables or disables image rotation during flicking.
    let allowsRotation: Bool
    /// Physics with standard (all default) settings.
    public static let standard = Physics()

    public init(permittedDirections: PanDirections = .horizontalAndVertical, pushMagnitude: CGFloat? = nil, allowsRotation: Bool = true) {
      self.permittedDirections = permittedDirections
      self.pushMagnitude = pushMagnitude
      self.allowsRotation = allowsRotation
    }
  }

  case withPan(Physics)
  case withButton(UIBarButtonItem?)
  case withPanAndButton(Physics, UIBarButtonItem?)
  @available(*, deprecated, message: "Use .withPan(.standard) instead.")
  case withPhysics
  @available(*, deprecated, message: "Use .withPanAndButton(.standard, ...) instead.")
  case withPhysicsAndButton(UIBarButtonItem?)
}
