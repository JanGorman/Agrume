//
//  Copyright © 2021 Schnaub. All rights reserved.
//

import SwiftUI
import UIKit

@available(iOS 14.0, *)
public struct AgrumeView: View {

  private let images: [UIImage]
  private let background: Background
  private let dismissal: Dismissal
  private let enableLiveText: Bool
  @Binding private var binding: Bool
  @Namespace var namespace

  public init(
    image: UIImage,
    background: Background = .colored(.black),
    dismissal: Dismissal = .withPan(.standard),
    enableLiveText: Bool = false,
    isPresenting: Binding<Bool>
  ) {
    self.init(
      images: [image],
      background: background,
      dismissal: dismissal,
      enableLiveText: enableLiveText,
      isPresenting: isPresenting
    )
  }

  public init(
    images: [UIImage],
    background: Background = .colored(.black),
    dismissal: Dismissal = .withPan(.standard),
    enableLiveText: Bool = false,
    isPresenting: Binding<Bool>
  ) {
    self.images = images
    self.background = background
    self.dismissal = dismissal
    self.enableLiveText = enableLiveText
    self._binding = isPresenting
  }

  public var body: some View {
    WrapperAgrumeView(
      images: images,
      background: background,
      dismissal: dismissal,
      enableLiveText: enableLiveText,
      isPresenting: $binding
    )
      .matchedGeometryEffect(id: "AgrumeView", in: namespace, properties: .frame, isSource: binding)
      .ignoresSafeArea()
  }
}

@available(iOS 13.0, *)
struct WrapperAgrumeView: UIViewControllerRepresentable {

  private let images: [UIImage]
  private let background: Background
  private let dismissal: Dismissal
  private let enableLiveText: Bool
  @Binding private var binding: Bool

  public init(
    images: [UIImage],
    background: Background,
    dismissal: Dismissal,
    enableLiveText: Bool,
    isPresenting: Binding<Bool>
  ) {
    self.images = images
    self.background = background
    self.dismissal = dismissal
    self.enableLiveText = enableLiveText
    self._binding = isPresenting
  }

  public func makeUIViewController(context: UIViewControllerRepresentableContext<WrapperAgrumeView>) -> UIViewController {
    let agrume = Agrume(
      images: images,
      background: background,
      dismissal: dismissal,
      enableLiveText: enableLiveText,
      presentedAsSwiftUI: true
    )
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
