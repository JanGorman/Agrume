//
//  Copyright © 2016 Schnaub. All rights reserved.
//

import XCTest
@testable import Agrume

class AgrumeServiceLocatorTests: XCTestCase {

  private let mockViewController = UIViewController()
  private var agrume: Agrume!
  
  override func setUp() {
    super.setUp()
    
    agrume = Agrume(imageUrl: URL(string: "https://dl.dropboxusercontent.com/u/512759/MapleBacon.png")!)
  }
  
  override func tearDown() {
    AgrumeServiceLocator.shared.removeDownloadHandler()
    agrume.download = nil

    super.tearDown()
  }

  func testAgrumeUsesDownloadHandlerWhenSet() {
    var callCount = 0
    AgrumeServiceLocator.shared.setDownloadHandler { _, _ in
      callCount += 1
    }
    
    agrume.showFrom(mockViewController)
    
    XCTAssertEqual(1, callCount)
  }
  
  func testAgrumeFallsBackToInternalWhenHandlerUnset() {
    var callCount = 0
    AgrumeServiceLocator.shared.setDownloadHandler { _, _ in
      callCount += 1
    }
    
    AgrumeServiceLocator.shared.removeDownloadHandler()
    agrume.showFrom(mockViewController)
    
    XCTAssertEqual(0, callCount)
  }
  
  func testAgrumePrefersClosureOverServiceLocator() {
    var callCount = 0
    AgrumeServiceLocator.shared.setDownloadHandler { _, _ in
      callCount += 1
    }

    var closureCallCount = 0
    agrume.download = { _, _ in
      closureCallCount += 1
    }
    
    agrume.showFrom(mockViewController)
    
    XCTAssertEqual(0, callCount)
    XCTAssertEqual(1, closureCallCount)
  }

}
