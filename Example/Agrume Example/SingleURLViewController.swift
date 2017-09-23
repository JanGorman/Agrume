//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import UIKit
import Agrume

final class SingleURLViewController: UIViewController {

  @IBAction func openURL(_ sender: Any) {
    let agrume = Agrume(imageUrl: URL(string: "https://www.dropbox.com/s/mlquw9k6ogvspox/MapleBacon.png?raw=1")!,
                        backgroundBlurStyle: .light)
    agrume.showFrom(self)
  }

}
