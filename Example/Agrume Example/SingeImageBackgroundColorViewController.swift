//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import UIKit
import Agrume

final class SingleImageBackgroundColorViewController: UIViewController {
  
  var agrume: Agrume!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    agrume = Agrume(image: UIImage(named: "MapleBacon")!, backgroundColor: .black)
    agrume.hideStatusBar = true
		agrume.shouldDismissWithTap = false

  }

  @IBAction private func openImage(_ sender: Any) {
    agrume.showFrom(self)
  }
  
}
