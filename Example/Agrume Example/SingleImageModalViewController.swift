//
//  SingleImageModalViewController.swift
//  Agrume Example
//

import UIKit
import Agrume

final class SingleImageModalViewController: UIViewController {

    @IBAction func openImage(sender: AnyObject) {
        let agrume = Agrume(image: UIImage(named: "MapleBacon")!)
        agrume.showFrom(self, backgroundSnapshotVC: navigationController)
    }

    @IBAction func close(sender: AnyObject) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: .None)
    }

}
