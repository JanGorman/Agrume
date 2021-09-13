//
//  URLUpdatedToImageViewController.swift
//  Agrume Example
//
//  Created by Bao Lei on 9/13/21.
//  Copyright © 2021 Schnaub. All rights reserved.
//

import Agrume
import UIKit

final class URLUpdatedToImageViewController: UIViewController {

  @IBAction private func openURL(_ sender: Any) {
    let agrume = Agrume(
      url: URL(string: "https://placekitten.com/500/500")!,
      background: .blurred(.regular)
    )
    agrume.show(from: self)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
      agrume.updateImage(at: 0, with: UIImage(named: "MapleBacon")!)
    }
  }
}
