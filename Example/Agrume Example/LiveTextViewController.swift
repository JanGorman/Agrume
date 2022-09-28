//
//  LiveTextViewController.swift
//

import Agrume
import UIKit
import VisionKit

final class LiveTextViewController: UIViewController {
  @IBAction private func openImage(_ sender: Any) {
    if #available(iOS 16, *), ImageAnalyzer.isSupported {
      let agrume = Agrume(
        image: UIImage(named: "TextAndQR")!,
        enableLiveText: true
      )
      agrume.show(from: self)
      return
    }
    
    let alert = UIAlertController(
      title: "Not supported on this device",
      message: """
      Live Text is available for devices with iOS 16 (or above) and A12 (or above)
      Bionic chip (iPhone XS and later, physical device only)
      """,
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
    present(alert, animated: true)
  }
}
