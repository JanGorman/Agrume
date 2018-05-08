//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import UIKit
import Agrume

final class SingleImageViewController: UIViewController {
  
  private lazy var agrume: Agrume = {
    return Agrume(image: #imageLiteral(resourceName: "MapleBacon"), background: .blurred(.regular))
  }()

  @IBAction private func openImage(_ sender: Any) {
    agrume.show(from: self)
  }

}
