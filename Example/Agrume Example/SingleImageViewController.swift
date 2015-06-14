//
//  SingleImageViewController.swift
//  Agrume Example
//

import UIKit
import Agrume

final class SingleImageViewController: UIViewController {

    @IBAction func openImage(sender: AnyObject) {
        let agrume = Agrume(image: UIImage(named: "MapleBacon")!)
        agrume.showFrom(self)
    }

}
