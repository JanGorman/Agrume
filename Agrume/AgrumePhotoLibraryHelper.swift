//
//  Copyright © 2020 Schnaub. All rights reserved.
//

import UIKit

public final class AgrumePhotoLibraryHelper: NSObject {

  private let saveButtonTitle: String
  private let cancelButtonTitle: String
  private let saveToLibraryHandler: (_ error: Error?) -> Void

  /// Initialize photo library helper
  ///
  /// - Parameters:
  ///   - saveButtonTitle: Title text to save photo to library
  ///   - cancelButtonTitle: Cancel text to save photo to library
  ///   - saveToLibraryHandler: saveToLibraryHandler to notify the user if it was successfull.
  public init(saveButtonTitle: String, cancelButtonTitle: String, saveToLibraryHandler: @escaping (_ error: Error?) -> Void) {
    self.saveButtonTitle = saveButtonTitle
    self.cancelButtonTitle = cancelButtonTitle
    self.saveToLibraryHandler = saveToLibraryHandler
  }

  /// Save the current photo shown in the user's photo library using Long Press Gesture
  /// Make sure to have NSPhotoLibraryUsageDescription (ios 10) and NSPhotoLibraryAddUsageDescription (ios 11+) in your info.plist
  public func makeSaveToLibraryLongPressGesture(for image: UIImage?, viewController: UIViewController) {
    guard let image = image else {
      return
    }
    let view = viewController.view!
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    alert.popoverPresentationController?.sourceView = view
    alert.popoverPresentationController?.permittedArrowDirections = .up
    let alertPosition = CGRect(x: view.bounds.midX, y: view.bounds.maxY - view.bounds.midY / 2, width: 0, height: 0)
    alert.popoverPresentationController?.sourceRect = alertPosition
  
    alert.addAction(UIAlertAction(title: saveButtonTitle, style: .default) { _ in
      UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image), nil)
    })
    alert.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: nil))
  
    viewController.present(alert, animated: true)
  }
  
  @objc
  private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
    saveToLibraryHandler(error)
  }
}
