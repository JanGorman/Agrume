//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import UIKit
import Agrume

final class MultipleImagesCollectionViewController: UICollectionViewController {

  private let identifier = "Cell"

  private let images = [
    #imageLiteral(resourceName: "MapleBacon"),
    #imageLiteral(resourceName: "EvilBacon")
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    let layout = collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
    layout.itemSize = CGSize(width: view.frame.width, height: view.frame.height)
  }

  // MARK: UICollectionViewDataSource

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return images.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! DemoCell
    cell.imageView.image = images[indexPath.item]
    return cell
  }

  // MARK: UICollectionViewDelegate

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let agrume = Agrume(images: images, startIndex: indexPath.item, background: .blurred(.regular))
    agrume.didScroll = { [unowned self] index in
      self.collectionView?.scrollToItem(at: IndexPath(item: index, section: 0), at: [], animated: false)
    }
    agrume.show(from: self)
  }

}
