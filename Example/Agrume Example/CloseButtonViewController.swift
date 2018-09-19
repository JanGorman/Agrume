//
//  Copyright © 2018 Schnaub. All rights reserved.
//

import UIKit
import Agrume

final class CloseButtonViewController: UIViewController {
  
  private lazy var agrume: Agrume = {
    return Agrume(image: #imageLiteral(resourceName: "MapleBacon"), background: .blurred(.regular), dismissal: .withButton(nil))
  }()
  
  @IBAction private func showImage() {
    agrume.show(from: self)
  }
  
}
