//
//  MultipleImagesCollectionViewController.swift
//  Agrume Example
//

import UIKit
import Agrume

final class MultipleImagesCollectionViewController: UICollectionViewController {

    private let identifier = "Cell"

    private let images = [
            UIImage(named: "MapleBacon")!,
            UIImage(named: "EvilBacon")!
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        let layout = collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: CGRectGetWidth(view.bounds), height: CGRectGetHeight(view.bounds))
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! DemoCell
        cell.imageView.image = images[indexPath.row]
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let agrume = Agrume(images: images, startIndex: indexPath.row, backgroundBlurStyle: .Light)
        agrume.didScroll = {
            [unowned self] index in
            self.collectionView?.scrollToItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0),
                    atScrollPosition: [],
                    animated: false)
        }
        agrume.showFrom(self)
    }

}
