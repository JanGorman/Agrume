//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import UIKit
import Agrume

final class SingleImageBackgroundColorViewController: UIViewController {
  
  private lazy var agrume: Agrume = {
    let agrume = Agrume(image: #imageLiteral(resourceName: "MapleBacon"), background: .colored(.black))
    agrume.hideStatusBar = true
    return agrume
  }()

  @IBAction private func openImage(_ sender: Any) {
    agrume.show(from: self)
  }
  
}
