//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import UIKit
import Agrume

final class SingleImageViewController: UIViewController {
  
  var agrume: Agrume!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    agrume = Agrume(image: #imageLiteral(resourceName: "MapleBacon"))
  }

  @IBAction func openImage(_ sender: Any) {
    agrume.showFrom(self)
  }

}
