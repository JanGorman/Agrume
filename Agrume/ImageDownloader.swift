//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import Foundation

final class ImageDownloader {

  class func downloadImage(_ url: URL, completion: @escaping (_ image: UIImage?) -> Void) -> URLSessionDataTask? {
    let dataTask = URLSession.shared.dataTask(with: url) { data, _, error in
      guard error == nil else {
        completion(nil)
        return
      }

      DispatchQueue.global(qos: .userInitiated).async {
        var image: UIImage?
        defer {
          DispatchQueue.main.async {
            completion(image)
          }
        }
        guard let data = data else { return }
        image = UIImage(data: data)
      }
    }
    dataTask.resume()
    return dataTask
  }

}
