//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import Foundation

public class AgrumeServiceLocator {

  public static let shared = AgrumeServiceLocator()
  
  public typealias DownloadHandler = ((_ url: URL, _ completion: @escaping Agrume.DownloadCompletion) -> Void)

  var downloadHandler: DownloadHandler?

  /// Register a download handler with the service locator.
  /// Agrume will use this handler for all downloads. This can be overriden on a per call basis
  /// by passing in a different handler for said call.
  ///
  /// – Parameter handler: The download handler
  public func setDownloadHandler(_ handler: @escaping DownloadHandler) {
    downloadHandler = handler
  }
  
  /// Remove the global handler.
  public func removeDownloadHandler() {
    downloadHandler = nil
  }

}
