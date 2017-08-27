//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import UIKit
import Agrume

final class SingleImageModalViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationController?.navigationBar.barTintColor = .red
  }
  
  @IBAction func openImage(_ sender: Any) {
    let agrume = Agrume(image: #imageLiteral(resourceName: "MapleBacon"))
    agrume.showFrom(self)
  }
  
  @IBAction func close(_ sender: Any) {
    presentingViewController?.dismiss(animated: true, completion: nil)
  }

}
