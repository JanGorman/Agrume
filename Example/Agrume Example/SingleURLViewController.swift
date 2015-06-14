//
//  SingleURLViewController.swift
//  Agrume Example
//

import UIKit
import Agrume

final class SingleURLViewController: UIViewController {

    @IBAction func openURL(sender: AnyObject) {
        let agrume = Agrume(imageURL: NSURL(string: "https://dl.dropboxusercontent.com/u/512759/MapleBacon.png")!,
                backgroundBlurStyle: .Light)
        agrume.showFrom(self)
    }

}
