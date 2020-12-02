# Agrume

[![Build Status](https://travis-ci.org/JanGorman/Agrume.svg?branch=master)](https://travis-ci.org/JanGorman/Agrume) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/Agrume.svg?style=flat)](http://cocoapods.org/pods/Agrume)
[![License](https://img.shields.io/cocoapods/l/Agrume.svg?style=flat)](http://cocoapods.org/pods/Agrume)
[![Platform](https://img.shields.io/cocoapods/p/Agrume.svg?style=flat)](http://cocoapods.org/pods/Agrume)
[![SPM](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)

An iOS image viewer written in Swift with support for multiple images.

![Agrume](https://www.dropbox.com/s/bdt6sphcyloa38u/Agrume.gif?raw=1)

## Requirements

- Swift 5.0
- iOS 9.0+
- Xcode 10.2+

## Installation

Use [Swift Package Manager](https://swift.org/package-manager).

Or [CocoaPods](http://cocoapods.org). Add the dependency to your `Podfile` and then run `pod install`:

```ruby
pod "Agrume"
```

Or [Carthage](https://github.com/Carthage/Carthage). Add the dependency to your `Cartfile` and then run `carthage update`:

```ogdl
github "JanGorman/Agrume"
```

## Usage

There are multiple ways you can use the image viewer (and the included sample project shows them all).

For just a single image it's as easy as

### Basic

```swift
import Agrume

private lazy var agrume = Agrume(image: UIImage(named: "…")!)

@IBAction func openImage(_ sender: Any) {
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

### Animated gifs

Agrume bundles [SwiftyGif](https://github.com/kirualex/SwiftyGif) to display animated gifs. You use SwiftyGif's custom `UIImage` initializer:

```swift
let image = UIImage(gifName: "animated.gif")
let agrume = Agrume(image: image)
agrume.display(from: self)

// Or gif using data:

let image = UIImage(gifData: data)
let agrume = Agrume(image: image)

// Or multiple images:

let images = [UIImage(gifName: "animated.gif"), UIImage(named: "foo.png")] // You can pass both animated and regular images at the same time
let agrume = Agrume(images: images)
```

Remote animated gifs (i.e. using the url or urls initializer) are supported. Agrume does the image type detection and displays them properly. If using Agrume from a custom `UIImageView` you may need to rebuild the `UIImage` using the original data to preserve animation vs. using the `UIImage` instance from the image view.

### Close Button

Per default you dismiss the zoomed view by dragging/flicking the image off screen. You can opt out of this behaviour and instead display a close button. To match the look and feel of your app you can pass in a custom `UIBarButtonItem`:

```swift
// Default button that displays NSLocalizedString("Close", …)
let agrume = Agrume(image: UIImage(named: "…")!, .dismissal: .withButton(nil))
// Customise the button any way you like. For example display a system "x" button
let button = UIBarButtonItem(barButtonSystemItem: .stop, target: nil, action: nil)
button.tintColor = .red
let agrume = Agrume(image: UIImage(named: "…")!, .dismissal: .withButton(button))
```

The included sample app shows both cases for reference.

### Custom Download Handler

If you want to take control of downloading images (e.g. for caching), you can also set a download closure that calls back to Agrume to set the image. For example, let's use [MapleBacon](https://github.com/JanGorman/MapleBacon).

```swift
import Agrume
import MapleBacon

private lazy var agrume = Agrume(url: URL(string: "https://dl.dropboxusercontent.com/u/512759/MapleBacon.png")!)

@IBAction func openURL(_ sender: Any) {
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

### Status Bar Appearance

You can customize the status bar appearance when displaying the zoomed in view. `Agrume` has a `statusBarStyle` property:

```swift
let agrume = Agrume(image: image)
agrume.statusBarStyle = .lightContent
agrume.show(from: self)
```

### Long Press Gesture and Downloading Images

If you want to handle long press gestures on the images, there is an optional `onLongPress` closure. This will pass an optional `UIImage` and a reference to the Agrume `UIViewController` as parameters. The project includes a helper class to easily opt into downloading the image to the user's photo library called `AgrumePhotoLibraryHelper`. First, create an instance of the helper:

```swift
private func makeHelper() -> AgrumePhotoLibraryHelper {
  let saveButtonTitle = NSLocalizedString("Save Photo", comment: "Save Photo")
  let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Cancel")
  let helper = AgrumePhotoLibraryHelper(saveButtonTitle: saveButtonTitle, cancelButtonTitle: cancelButtonTitle) { error in
    guard error == nil else {
      print("Could not save your photo")
      return
    }
    print("Photo has been saved to your library")
  }
  return helper
}
```

and then pass this helper's long press handler to `Agrume` as follows:

```swift
let helper = makeHelper()
agrume.onLongPress = helper.makeSaveToLibraryLongPressGesture
```

### Custom Overlay View

You can customise the look and functionality of the image views. To do so, you need create a class that inherits from `AgrumeOverlayView: UIView`. As this is nothing more than a regular `UIView` you can do anything you want with it like add a custom toolbar or buttons to it. The example app shows a detailed example of how this can be achieved.

### Lifecycle

`Agrume` offers the following lifecycle closures that you can optionally set:

- `willDismiss`
- `didDismiss`
- `didScroll`

### Running the Sample Code

The project ships with an example app that shows the different functions documented above. Since there is a dependency on [SwiftyGif](https://github.com/kirualex/SwiftyGif) you will also need to fetch that to run the project. It's included as git submodule. After fetching the repository, from the project's root directory run:

```bash
git submodule update --init
```

## Licence

Agrume is released under the MIT license. See LICENSE for details
