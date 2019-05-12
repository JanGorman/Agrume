//
//  Copyright © 2018 Schnaub. All rights reserved.
//

import UIKit
import Agrume
import SwiftyGif

final class AnimatedGifViewController: UIViewController {

  @IBAction func openImage(_ sender: Any?) {
    let image = try! UIImage(gifName: "animated.gif")
    let agrume = Agrume(image: image, background: .blurred(.regular))
    agrume.show(from: self)
  }
  
}
