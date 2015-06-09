[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# Agrume

An iOS image viewer written in Swift with support for multiple images.

## Requirements

- iOS 8.0+
- Xcode 6.3+

## Installation

The easiest way is through [CocoaPods](http://cocoapods.org). Simply add the dependency to your `Podfile` and then `pod install`:

```ruby
pod 'Agrume', '~> 1'
```

Or [Carthage](https://github.com/Carthage/Carthage). Add the depdency to your `Cartfile` and then `carthage update`:

```ogdl
github "JanGorman/Agrume" >= 1
```

## How

There are multiple ways you can use the image viewer (and the included Example project shows them all).

For just a single image it's as easy as

```swift
import Agrume

@IBAction func openImage(sender: AnyObject) {
	if let image = UIImage(named: "…") {
		let agrume = Agrume(image: image)
		agrume.showFrom(self)	
	}
}
```

You can also pass in an `NSURL` and Agrume will take care of the download for you.

If you're displaying a `UICollectionView` and want to add support for zooming, you can also call Agrume with an array of either images or URLs.

```swift
let agrume = Agrume(images: images, startIndex: indexPath.row, backgroundBlurStyle: .Light)
agrume.didScroll = {
	[unowned self] index in
    self.collectionView?.scrollToItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0),
    	atScrollPosition: .allZeros,
        animated: false)
}
agrume.showFrom(self)
```

This shows a way of keeping the zoomed library and the one in the background synced.

If you want to take control of downloading images (e.g. for caching), you can also set a download closure that calls back to Agrume to set the image. I can recommend [MapleBacon](https://github.com/zalando/MapleBacon).

```swift
import Agrume
import MapleBacon

@IBAction func openURL(sender: AnyObject) {
	let agrume = Agrume(imageURL: NSURL(string: "https://dl.dropboxusercontent.com/u/512759/MapleBacon.png")!, backgroundBlurStyle: .Light)
	agrume.download = {
		url, completion in
		let manager = ImageManager.sharedManager
		manager.downloadImageAtURL(url) {
			imageInstance, error in
			if error == nil {
				completion(image: imageInstance.image)
			} else {
				completion(image: nil)
			}
		}
	}
	agrume.showFrom(self)
}
```

## Acknowledgements

Agrume was inspired by the phenomal work done by Jared Sinclair on [JTSImageViewController](https://github.com/jaredsinclair/JTSImageViewController). This project wouldn't have seen the light of day as quickly without it.

## Licence

Agrume is released under the MIT license. See LICENSE for details
