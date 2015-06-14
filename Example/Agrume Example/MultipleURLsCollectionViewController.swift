//
//  MultipleURLsCollectionViewController.swift
//  Agrume Example
//

import UIKit
import Agrume

final class MultipleURLsCollectionViewController: UICollectionViewController {

    private let identifier = "Cell"

    private struct ImageWithURL {
        let image: UIImage
        let URL: NSURL
    }

    private let images = [
        ImageWithURL(image: UIImage(named: "MapleBacon")!, URL: NSURL(string: "https://dl.dropboxusercontent.com/u/512759/MapleBacon.png")!),
        ImageWithURL(image: UIImage(named: "EvilBacon")!, URL: NSURL(string: "https://dl.dropboxusercontent.com/u/512759/EvilBacon.png")!)
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
        cell.imageView.image = images[indexPath.row].image
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let URLs = images.map { $0.URL }
        let agrume = Agrume(imageURLs: URLs, startIndex: indexPath.row, backgroundBlurStyle: .ExtraLight)
        agrume.didScroll = {
            [unowned self] index in
            self.collectionView?.scrollToItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0),
                    atScrollPosition: [],
                    animated: false)
        }
        agrume.showFrom(self)
    }

}
