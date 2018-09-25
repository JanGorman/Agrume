//
//  Copyright © 2018 Schnaub. All rights reserved.
//

import UIKit
import Agrume
import Zoetrope

final class AnimatedGifViewController: UIViewController {

  @IBAction func openImage(_ sender: Any?) {
    guard let image = UIImage(gifName: "animated.gif") else {
      return
    }
    let agrume = Agrume(image: image, background: .blurred(.regular))
    agrume.show(from: self)
  }
  
}
