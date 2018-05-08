# Agrume

[![Build Status](https://travis-ci.org/JanGorman/Agrume.svg?branch=master)](https://travis-ci.org/JanGorman/Agrume) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/Agrume.svg?style=flat)](http://cocoapods.org/pods/Agrume)
[![License](https://img.shields.io/cocoapods/l/Agrume.svg?style=flat)](http://cocoapods.org/pods/Agrume)
[![Platform](https://img.shields.io/cocoapods/p/Agrume.svg?style=flat)](http://cocoapods.org/pods/Agrume)

An iOS image viewer written in Swift with support for multiple images.

![Agrume](https://www.dropbox.com/s/bdt6sphcyloa38u/Agrume.gif?raw=1)

## Requirements

- Swift 4.1 (for Swift 3 support, use version 3.x)
- iOS 9.0+
- Xcode 9+

## Installation

The easiest way is via [CocoaPods](http://cocoapods.org). Add the dependency to your `Podfile` and then run `pod install`:

```ruby
pod 'Agrume', :git => 'https://github.com/JanGorman/Agrume.git'
```

Or [Carthage](https://github.com/Carthage/Carthage). Add the dependency to your `Cartfile` and then run `carthage update`:

```ogdl
github "JanGorman/Agrume"
```

## How

There are multiple ways you can use the image viewer (and the included sample project shows them all).

For just a single image it's as easy as

### Basic

```swift

import Agrume

@IBAction func openImage(_ sender: Any) {
  let agrume = Agrume(image: UIImage(named: "…")!)
  agrume.show(from: self)
}

```

You can also pass in a `URL` and Agrume will take care of the download for you.

### Background Configuration

Agrume has different background configurations. You can have it blur the view it's covering or supply a background color:

```swift

let agrume = Agrume(image: UIImage(named: "…")!, background: .blurred(.regular))
// or
let agrume = Agrume(image: UIImage(named: "…")!, background: .colored(.green))

```

### Multiple Images

If you're displaying a `UICollectionView` and want to add support for zooming, you can also call Agrume with an array of either images or URLs.

```swift

// In case of an array of [UIImage]:
let agrume = Agrume(images: images, startIndex: indexPath.item, background: .blurred(.light))
// Or an array of [URL]:
// let agrume = Agrume(urls: urls, startIndex: indexPath.item, background: .blurred(.light))

agrume.didScroll = { [unowned self] index in
  self.collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: [], animated: false)
}
agrume.show(from: self)

```

This shows a way of keeping the zoomed library and the one in the background synced.

### Custom Download Handler

If you want to take control of downloading images (e.g. for caching), you can also set a download closure that calls back to Agrume to set the image. For example, let's use [MapleBacon](https://github.com/JanGorman/MapleBacon).

```swift

import Agrume
import MapleBacon

@IBAction func openURL(_ sender: Any) {
  let agrume = Agrume(url: URL(string: "https://dl.dropboxusercontent.com/u/512759/MapleBacon.png")!)
  agrume.download = { url, completion in
    Downloader.default.download(url) { image in
      completion(image)
    }
  }
  agrume.show(from: self)
}
```

### Global Custom Download Handler

Instead of having to define a handler on a per instance basis you can instead set a handler on the `AgrumeServiceLocator`. Agrume will use this handler for all downloads unless overriden on an instance as described above:

```swift

import Agrume

AgrumeServiceLocator.shared.setDownloadHandler { url, completion in
  // Download data, cache it and call the completion with the resulting UIImage
}

// Some other place
agrume.show(from: self)

```

### Custom Data Source

For more dynamic library needs you can implement the `AgrumeDataSource` protocol that supplies images to Agrume. Agrume will query the data source for the number of images and if that number changes, reload it's scrolling image view.

```swift

import Agrume

let dataSource: AgrumeDataSource = MyDataSourceImplementation()
let agrume = Agrume(dataSource: dataSource)

agrume.show(from: self)

```

### Custom Background Snapshot

When showing the Agrume view controller, it'll default to taking a snapshot of the root view and blurring that. You can customize this behaviour by passing in a different view that it will blur and display:

```swift

let agrume = Agrume(image: image)
agrume.show(from: self, backgroundSnapshotVC: self)

```

### Status Bar Appearance

You can customize the status bar appearance when displaying the zoomed in view. `Agrume` has a `statusBarStyle` property:

```swift

let agrume = Agrume(image: image)
agrume.statusBarStyle = .lightContent
agrume.show(from: self)

```

## Licence

Agrume is released under the MIT license. See LICENSE for details
