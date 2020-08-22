//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import ImageIO
import MobileCoreServices
import SwiftyGif
import UIKit

final class ImageDownloader {

  static func downloadImage(_ url: URL, completion: @escaping (_ image: UIImage?) -> Void) -> URLSessionDataTask? {
    let session = URLSession(configuration: newConfiguration())
    let task = session.dataTask(with: url) { data, _, error in
      var image: UIImage?
      defer {
        DispatchQueue.main.async {
          completion(image)
        }
      }
      guard let data = data, error == nil else {
        return
      }
      if isAnimatedImage(data) {
        image = try? UIImage(gifData: data)
      } else {
        image = UIImage(data: data)
      }
    }
    task.resume()
    return task
  }
  
  private static func newConfiguration() -> URLSessionConfiguration {
    let configuration = URLSessionConfiguration.default
    if #available(iOS 11.0, *) {
      configuration.waitsForConnectivity = true
    }
    return configuration
  }
  
  private static func isAnimatedImage(_ data: Data) -> Bool {
    guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
          let imageType = CGImageSourceGetType(imageSource) else {
            return false
          }
    return UTTypeConformsTo(imageType, kUTTypeGIF)
  }

}
