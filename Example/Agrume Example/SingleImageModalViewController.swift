//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import Agrume
import UIKit

final class SingleImageModalViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationController?.navigationBar.barTintColor = .red
  }
  
  @IBAction private func openImage(_ sender: Any) {
    let agrume = Agrume(image: UIImage(named: "MapleBacon")!, background: .blurred(.regular))
    let helper = makeHelper()
    agrume.onLongPress = helper.makeSaveToLibraryLongPressGesture
    agrume.show(from: self)
  }
  
  @IBAction private func close(_ sender: Any) {
    presentingViewController?.dismiss(animated: true)
  }

  private func makeHelper() -> AgrumePhotoLibraryHelper {
    let saveButtonTitle = NSLocalizedString("Save Photo", comment: "Save Photo")
    let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Cancel")
    let helper = AgrumePhotoLibraryHelper(saveButtonTitle: saveButtonTitle, cancelButtonTitle: cancelButtonTitle) { error in
      guard error == nil else {
        print("Could not save your photo")
        return
      }
      print("Photo has been saved to your library")
    }
    return helper
  }
}
