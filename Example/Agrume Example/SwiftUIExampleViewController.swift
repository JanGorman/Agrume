//
//  Copyright © 2022 Schnaub. All rights reserved.
//

import Agrume
import SwiftUI
import UIKit

final class SwiftUIExampleViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    let hostingView = UIHostingController(
      rootView: SwiftUIHostingExample(
        images: [
          UIImage(named: "MapleBacon")!,
          UIImage(named: "EvilBacon")!
        ]
      )
    )
    addChild(hostingView)
    hostingView.view.frame = view.frame
    view.addSubview(hostingView.view)
    hostingView.didMove(toParent: self)
  }

}

struct SwiftUIHostingExample: View {

  let images: [UIImage]

  @State var showAgrume = false

  var body: some View {
    VStack {
      // Hide the presenting button (or other view) whenever Agrume is shown
      if !showAgrume {
        Button("Launch Agrume from SwiftUI") {
          withAnimation {
            showAgrume = true
          }
        }
      }

      if showAgrume {
        AgrumeView(images: images, isPresenting: $showAgrume)
      }
    }
  }
}
