//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import Agrume
import UIKit

final class MultipleURLsCollectionViewController: UICollectionViewController {

  private let identifier = "Cell"
  
  private struct ImageWithURL {
    let image: UIImage
    let url: URL
  }
  
  private let images = [
    ImageWithURL(image: UIImage(named: "MapleBacon")!, url: URL(string: "https://www.dropbox.com/s/mlquw9k6ogvspox/MapleBacon.png?raw=1")!),
    ImageWithURL(image: UIImage(named: "EvilBacon")!, url: URL(string: "https://www.dropbox.com/s/fwjbsuonhv1wrqu/EvilBacon.png?raw=1")!)
  ]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let layout = collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
    layout.itemSize = CGSize(width: view.bounds.width, height: view.bounds.height)
  }
  
  // MARK: UICollectionViewDataSource
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    images.count
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
    let helper = makeHelper()
    agrume.onLongPress = helper.makeSaveToLibraryLongPressGesture
    agrume.show(from: self)
  }
  
  private func makeHelper() -> AgrumePhotoLibraryHelper {
    let saveButtonTitle = NSLocalizedString("Save Photo", comment: "Save Photo")
    let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Cancel")
    let helper = AgrumePhotoLibraryHelper(saveButtonTitle: saveButtonTitle, cancelButtonTitle: cancelButtonTitle) { error in
      guard error == nil else {
        print("Could not save your photo")
        return
      }
      print("Photo has been saved to your library")
    }
    return helper
  }
}
