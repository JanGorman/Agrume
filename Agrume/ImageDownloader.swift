//
//  ImageDownloader.swift
//  Agrume
//

import Foundation

final class ImageDownloader {

  class func downloadImage(_ url: URL, completion: (image: UIImage?) -> Void) -> URLSessionDataTask? {
    let session = URLSession.shared
    let request = URLRequest(url: url)
    let dataTask = session.dataTask(with: request) { data, _, error in
      guard error == nil else {
        completion(image: nil)
        return
      }
      DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async {
        if let data = data, image = UIImage(data: data) {
          DispatchQueue.main.async {
              completion(image: image)
          }
        } else {
          completion(image: nil)
        }
      }
    }
    dataTask.resume()
    return dataTask
  }

}
