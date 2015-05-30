//
//  ImageDownloader.swift
//  Agrume
//
//  Created by Jan Gorman on 28/05/15.
//  Copyright (c) 2015 Schnaub. All rights reserved.
//

import Foundation

class ImageDownloader {
    
    class func downloadImage(url: NSURL, completion: (image: UIImage?) -> Void) -> NSURLSessionDataTask {
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: url)
        let dataTask = session.dataTaskWithRequest(request) {
            data, response, error in
            if error != nil {
                completion(image: nil)
                return
            }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                if let image = UIImage(data: data) {
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