//
//  Copyright © 2018 Schnaub. All rights reserved.
//

import Agrume
import UIKit

final class CloseButtonViewController: UIViewController {
  
  private lazy var agrume = Agrume(image: UIImage(named: "MapleBacon")!, background: .blurred(.regular), dismissal: .withButton(nil))
  
  @IBAction private func showImage() {
    agrume.show(from: self)
  }
  
}
