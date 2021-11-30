//
//  AgrumeView.swift
//
//  Created by Xun Gong on 11/30/21.
//

import SwiftUI

struct AgrumeView: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: UIViewControllerRepresentableContext<AgrumeView>) -> Agrume {
        let agrume = Agrume(image: self.image)
        agrume.addSubviews()
        agrume.addOverlayView()
        agrume.willDismiss = {
            agrume.view.superview?.backgroundColor = .clear
            agrume.view.superview?.superview?.backgroundColor = .clear
        }
        return agrume
    }

    func updateUIViewController(_ uiViewController: Agrume,
                                context: UIViewControllerRepresentableContext<AgrumeView>)
    {}
}
