//
//  Copyright © 2021 Schnaub. All rights reserved.
//

import SwiftUI
import UIKit

@available(iOS 14.0, *)
public struct AgrumeView: View {

  private let images: [UIImage]
  @Binding private var binding: Bool
  @Namespace var namespace

  public init(image: UIImage, isPresenting: Binding<Bool>) {
    self.init(images: [image], isPresenting: isPresenting)
  }

  public init(images: [UIImage], isPresenting: Binding<Bool>) {
    self.images = images
    self._binding = isPresenting
  }

  public var body: some View {
    WrapperAgrumeView(images: images, isPresenting: $binding)
      .matchedGeometryEffect(id: "AgrumeView", in: namespace, properties: .frame, isSource: binding)
      .ignoresSafeArea()
  }
}

@available(iOS 13.0, *)
struct WrapperAgrumeView: UIViewControllerRepresentable {

  private let images: [UIImage]
  @Binding private var binding: Bool

  public init(images: [UIImage], isPresenting: Binding<Bool>) {
    self.images = images
    self._binding = isPresenting
  }

  public func makeUIViewController(context: UIViewControllerRepresentableContext<WrapperAgrumeView>) -> UIViewController {
    let agrume = Agrume(images: images)
    agrume.view.backgroundColor = .clear
    agrume.addSubviews()
    agrume.addOverlayView()
    agrume.willDismiss = {
      withAnimation {
        binding = false
      }
    }
    return agrume
  }

  public func updateUIViewController(_ uiViewController: UIViewController,
                                     context: UIViewControllerRepresentableContext<WrapperAgrumeView>) {
  }
}
