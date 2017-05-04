//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import UIKit

final class ImageDownloader {

  static func downloadImage(_ url: URL, completion: @escaping (_ image: UIImage?) -> Void) -> URLSessionDataTask? {
    let dataTask = URLSession.shared.dataTask(with: url) { data, _, error in
      var image: UIImage?
      defer {
        DispatchQueue.main.async {
          completion(image)
        }
      }
      guard let data = data, error == nil else { return }
      image = UIImage(data: data)
    }
    dataTask.resume()
    return dataTask
  }

}
