//
//  Copyright © 2018 Schnaub. All rights reserved.
//

import Agrume
import UIKit
import SDWebImage

final class AnimatedGifViewController: UIViewController {

  @IBAction private func openImage(_ sender: Any?) {
    let image = try! SDAnimatedImage(named: "animated.gif")
    
    let agrume = Agrume(image: image!, background: .blurred(.regular))
    agrume.show(from: self)
  }
  
}
