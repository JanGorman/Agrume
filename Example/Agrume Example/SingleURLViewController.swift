//
//  SingleURLViewController.swift
//  Agrume Example
//

import UIKit
import Agrume

final class SingleURLViewController: UIViewController {

    @IBAction func openURL(_ sender: AnyObject) {
        let agrume = Agrume(imageURL: URL(string: "https://dl.dropboxusercontent.com/u/512759/MapleBacon.png")!,
                backgroundBlurStyle: .light)
        agrume.showFrom(self)
    }

}
