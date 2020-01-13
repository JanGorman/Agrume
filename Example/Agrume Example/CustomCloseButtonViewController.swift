//
//  Copyright © 2018 Schnaub. All rights reserved.
//

import Agrume
import UIKit

final class CustomCloseButtonViewController: UIViewController {
 
  private lazy var agrume: Agrume = {
    let button = UIBarButtonItem(barButtonSystemItem: .stop, target: nil, action: nil)
    button.tintColor = .red
    return Agrume(image: UIImage(named: "MapleBacon")!, background: .blurred(.regular), dismissal: .withButton(button))
  }()
  
  @IBAction private func showImage() {
    agrume.show(from: self)
  }
  
}
