[![Build Status](https://travis-ci.org/JanGorman/Agrume.svg?branch=master)](https://travis-ci.org/JanGorman/Agrume) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/Agrume.svg?style=flat)](http://cocoapods.org/pods/Agrume)
[![License](https://img.shields.io/cocoapods/l/Agrume.svg?style=flat)](http://cocoapods.org/pods/Agrume)
[![Platform](https://img.shields.io/cocoapods/p/Agrume.svg?style=flat)](http://cocoapods.org/pods/Agrume)

# Agrume

An iOS image viewer written in Swift with support for multiple images.

![bloggif_56c29473a93fb](https://cloud.githubusercontent.com/assets/6511079/13066215/95c8186a-d418-11e5-81df-19f0c831d099.gif)


## Requirements

- Swift 3.0
- iOS 8.0+
- Xcode 8+

## Installation

The easiest way is through [CocoaPods](http://cocoapods.org). Simply add the dependency to your `Podfile` and then `pod install`:

```ruby
pod 'Agrume', :git => 'https://github.com/JanGorman/Agrume.git'
```

Or [Carthage](https://github.com/Carthage/Carthage). Add the dependency to your `Cartfile` and then `carthage update`:

```ogdl
github "JanGorman/Agrume"
```

## How

There are multiple ways you can use the image viewer (and the included Example project shows them all).

For just a single image it's as easy as

### Basic

```swift
import Agrume

@IBAction func openImage(_ sender: AnyObject) {
  if let image = UIImage(named: "…") {
	let agrume = Agrume(image: image)
	agrume.showFrom(self)	
  }
}
```

You can also pass in an `NSURL` and Agrume will take care of the download for you.

### Multiple Images

If you're displaying a `UICollectionView` and want to add support for zooming, you can also call Agrume with an array of either images or URLs.

```swift
let agrume = Agrume(images: images, startIndex: indexPath.row, backgroundBlurStyle: .light)
agrume.didScroll = { [unowned self] index in
  self.collectionView?.scrollToItem(at: IndexPath(row: index, section: 0),
                                    at: [],
                                    animated: false)
}
agrume.showFrom(self)
```

This shows a way of keeping the zoomed library and the one in the background synced.

### Custom Download Handler

If you want to take control of downloading images (e.g. for caching), you can also set a download closure that calls back to Agrume to set the image. I can recommend [MapleBacon](https://github.com/zalando/MapleBacon).

```swift
import Agrume
import MapleBacon

@IBAction func openURL(_ sender: AnyObject) {
  let agrume = Agrume(imageUrl: URL(string: "https://dl.dropboxusercontent.com/u/512759/MapleBacon.png")!, backgroundBlurStyle: .light)
	agrume.download = { url, completion in
	  ImageDownloader.downloadImage(url) { image in
		if let image = image {
		  completion(image)
		} else {
		  completion(nil)
		}
	}
  }
  agrume.showFrom(self)
}
```

### Global Custom Download Handler

Instead of having to define a handler on a per instance basis you can instead set a handler on the `AgrumeServiceLocator`. Agrume will use this handler for all downloads unless overriden on an instance as described above:

```swift
import Agrume

AgrumeServiceLocator.shared.setDownloadHandler { url, completion in
  // Download data, cache it and remember to call the completion
}

// Some other place
agrume.showFrom(self)

```

### Custom Data Source

For more dynamic library needs you can implement the `AgrumeDataSource` protocol that supplies images to Agrume. Agrume will query the data source for the number of images and if that number changes, reload it's scrolling image view.

```swift
import Agrume

let dataSource: AgrumeDataSource = MyDataSourceImplementation()
let agrume = Agrume(dataSource: dataSource)

agrume.showFrom(self)

```

### Custom Background Snapshot

When showing the Agrume view controller, it'll default to taking a snapshot of the root view and blurring that. You can customize this behaviour by passing in a different view that it will blur and display:

```swift
let agrume = Agrume(image: image)
agrume.showFrom(self, backgroundSnapshotVC: self)

```

### Status Bar Appearance

You can customize the status bar appearance when displaying the zoomed in view. `Agrume` has a `statusBarStyle` property:

```swift
let agrume = Agrume(image: image)
agrume.statusBarStyle = .lightContent
agrume.showFrom(self)
```

## Licence

Agrume is released under the MIT license. See LICENSE for details
