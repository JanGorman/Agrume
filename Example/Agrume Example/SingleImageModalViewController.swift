//
//  SingleImageModalViewController.swift
//  Agrume Example
//

import UIKit
import Agrume

final class SingleImageModalViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationController?.navigationBar.barTintColor = .redColor()
  }
  
  @IBAction func openImage(sender: AnyObject) {
    let agrume = Agrume(image: UIImage(named: "MapleBacon")!)
    agrume.showFrom(self)
    // Optionally pass in a custom background snapshot VC but the library should pick the correct one for you
//  agrume.showFrom(self, backgroundSnapshotVC: navigationController)
  }

  @IBAction func close(sender: AnyObject) {
      presentingViewController?.dismissViewControllerAnimated(true, completion: .None)
  }

}
