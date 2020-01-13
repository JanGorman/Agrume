//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import Agrume
import UIKit

final class SingleURLViewController: UIViewController {

  @IBAction private func openURL(_ sender: Any) {
    let agrume = Agrume(url: URL(string: "https://www.dropbox.com/s/mlquw9k6ogvspox/MapleBacon.png?raw=1")!,
                        background: .blurred(.regular))
    let helper = makeHelper()
    agrume.onLongPress = helper.makeSaveToLibraryLongPressGesture
    agrume.show(from: self)
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
