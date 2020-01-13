//
//  Copyright © 2020 Schnaub. All rights reserved.
//

import Agrume
import UIKit

final class MultipleImagesCustomOverlayView: UICollectionViewController {

  private let identifier = "Cell"

  private let images = [
    UIImage(named: "MapleBacon")!,
    UIImage(named: "EvilBacon")!
  ]
  
  private var agrume: Agrume?
  
  private lazy var overlayView: OverlayView = {
    let overlay = OverlayView()
    overlay.delegate = self
    return overlay
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    let layout = collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
    layout.itemSize = CGSize(width: view.frame.width, height: view.frame.height)
  }

  // MARK: UICollectionViewDataSource

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    images.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! DemoCell
    cell.imageView.image = images[indexPath.item]
    return cell
  }

  // MARK: UICollectionViewDelegate

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    overlayView.navigationBar.topItem?.title = "Image \(indexPath.item + 1)"
    
    agrume = Agrume(images: images, startIndex: indexPath.item, background: .blurred(.regular), overlayView: overlayView)
    agrume?.tapBehavior = .toggleOverlayVisibility
    agrume?.didScroll = { [unowned self] index in
      self.collectionView?.scrollToItem(at: IndexPath(item: index, section: 0), at: [], animated: false)
      self.overlayView.navigationBar.topItem?.title = "Image \(index + 1)"
    }
    
    agrume?.show(from: self)
  }
}

extension MultipleImagesCustomOverlayView: OverlayViewDelegate {
  func overlayView(_ overlayView: OverlayView, didSelectAction action: String) {
    let alert = UIAlertController(title: nil,
                                  message: "You selected \(action) for image \((agrume?.currentIndex ?? 0) + 1)",
                                  preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    agrume?.present(alert, animated: true)
  }
}
