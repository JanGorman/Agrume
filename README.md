[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# Agrume

An iOS image viewer written in Swift with support for multiple images.

## Requirements

- iOS 8.0+
- Xcode 6.3+

## Installation

The easiest way is through [CocoaPods](http://cocoapods.org). Simply add the dependency to your `Podfile` and then `pod install`:

```ruby
pod `Agrume`, `~> 1`
```

Or [Carthage](https://github.com/Carthage/Carthage). Add the depdency to your `Cartfile` and then `carthage update`:

```ogdl
github "JanGorman/Carthage" >= 1
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

## Acknowledgements

Agrume was inspired by the phenomal work done by Jared Sinclair on [JTSImageViewController](https://github.com/jaredsinclair/JTSImageViewController). This project wouldn't have seen the light of day as quickly without it.

## Licence

Agrume is released under the MIT license. See LICENSE for details
