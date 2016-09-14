//
//  SingleImageModalViewController.swift
//  Agrume Example
//

import UIKit
import Agrume

final class SingleImageModalViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationController?.navigationBar.barTintColor = .red
  }
  
  @IBAction func openImage(_ sender: AnyObject) {
    let agrume = Agrume(image: UIImage(named: "MapleBacon")!)
    agrume.showFrom(self)
    // Optionally pass in a custom background snapshot VC but the library should pick the correct one for you
    //  agrume.showFrom(self, backgroundSnapshotVC: navigationController)
  }
  
  @IBAction func close(_ sender: AnyObject) {
    presentingViewController?.dismiss(animated: true, completion: nil)
  }

}
