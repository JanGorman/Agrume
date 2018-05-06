//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import UIKit
import Agrume

final class SingleImageBackgroundColorViewController: UIViewController {
  
  var agrume: Agrume!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    agrume = Agrume(image: #imageLiteral(resourceName: "MapleBacon"), background: .colored(.black))
    agrume.hideStatusBar = true
  }

  @IBAction private func openImage(_ sender: Any) {
    agrume.showFrom(self)
  }
  
}
