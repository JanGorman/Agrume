//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import UIKit
import Agrume

final class SingleURLViewController: UIViewController {

  @IBAction func openURL(_ sender: Any) {
    let agrume = Agrume(url: URL(string: "https://www.dropbox.com/s/mlquw9k6ogvspox/MapleBacon.png?raw=1")!,
                        background: .blurred(.regular))
    agrume.showFrom(self)
  }

}
