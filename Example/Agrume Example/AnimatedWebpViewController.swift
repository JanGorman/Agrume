//
//  AnimatedWebpViewController.swift
//  Agrume Example
//
//  Created by kakao on 2022/04/28.
//  Copyright © 2022 Schnaub. All rights reserved.
//

import UIKit
import SDWebImage
import Agrume

final class AnimatedWebpViewController: UIViewController {
    @IBAction func openImageButtonTapped(_ sender: Any) {
      // SDWebImage에서 Webp를 사용하려면 SDWebImageWebPCoder디펜던시 추가 및 AppDelegate에서 코더를 등록해주어야합니다.
      let image = try! SDAnimatedImage(named: "animated_webp.webp")
      
      let agrume = Agrume(image: image!, background: .blurred(.regular))
      agrume.show(from: self)
    }
}
