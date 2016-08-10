//
//  ImageDownloader.swift
//  Agrume
//

import Foundation

final class ImageDownloader {

  class func downloadImage(url: NSURL, completion: (image: UIImage?) -> Void) -> NSURLSessionDataTask? {
    let session = NSURLSession.sharedSession()
    let request = NSURLRequest(URL: url)
    let dataTask = session.dataTaskWithRequest(request) { data, _, error in
      guard error == nil else {
        completion(image: nil)
        return
      }
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
        if let data = data, image = UIImage(data: data) {
          dispatch_async(dispatch_get_main_queue()) {
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
