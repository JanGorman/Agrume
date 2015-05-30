//
//  MultipleURLsCollectionViewController.swift
//  Agrume Example
//

import UIKit
import Agrume

class MultipleURLsCollectionViewController: UICollectionViewController {

    private let identifier = "Cell"
    
    private let images = [
        UIImage(named: "MapleBacon")! : NSURL(string: "https://dl.dropboxusercontent.com/u/512759/MapleBacon.png")!,
        UIImage(named: "EvilBacon")! : NSURL(string: "https://dl.dropboxusercontent.com/u/512759/EvilBacon.png")!
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
        cell.imageView.image = Array(images.keys)[indexPath.row]
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let agrume = Agrume(imageURLs: Array(images.values), startIndex: indexPath.row, backgroundBlurStyle: .ExtraLight)
        agrume.didScroll = {
            [unowned self] index in
            self.collectionView?.scrollToItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0),
                atScrollPosition: .allZeros,
                animated: false)
        }
        agrume.showFrom(self)
    }

}
