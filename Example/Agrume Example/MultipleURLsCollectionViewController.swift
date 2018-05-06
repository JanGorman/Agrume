//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import UIKit
import Agrume

final class MultipleURLsCollectionViewController: UICollectionViewController {

  private let identifier = "Cell"
  
  private struct ImageWithURL {
    let image: UIImage
    let url: URL
  }
  
  private let images = [
    ImageWithURL(image: #imageLiteral(resourceName: "MapleBacon"), url: URL(string: "https://www.dropbox.com/s/mlquw9k6ogvspox/MapleBacon.png?raw=1")!),
    ImageWithURL(image: #imageLiteral(resourceName: "EvilBacon"), url: URL(string: "https://www.dropbox.com/s/fwjbsuonhv1wrqu/EvilBacon.png?raw=1")!)
  ]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let layout = collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
    layout.itemSize = CGSize(width: view.bounds.width, height: view.bounds.height)
  }
  
  // MARK: UICollectionViewDataSource
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return images.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! DemoCell
    cell.imageView.image = images[indexPath.item].image
    return cell
  }
  
  // MARK: UICollectionViewDelegate
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let urls = images.map { $0.url }
    let agrume = Agrume(urls: urls, startIndex: indexPath.item, background: .blurred(.extraLight))
    agrume.didScroll = { [unowned self] index in
      self.collectionView?.scrollToItem(at: IndexPath(item: index, section: 0), at: [], animated: false)
    }
    agrume.show(from: self)
  }
  
}
