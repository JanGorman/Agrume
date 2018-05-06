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
  
  @IBAction private func openImage(_ sender: Any) {
    let agrume = Agrume(image: #imageLiteral(resourceName: "MapleBacon"), background: .blurred(.regular))
    agrume.show(from: self)
  }
  
  @IBAction private func close(_ sender: Any) {
    presentingViewController?.dismiss(animated: true, completion: nil)
  }

}
