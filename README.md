## FYPhoto

FYPhoto is an photo/video picker and browser for iOS written in pure Swift. It is feature-rich and highly customizable to match your App's requirements.

[![Version](https://img.shields.io/badge/language-swift%205-f48041.svg?style=flat)](https://developer.apple.com/swift) [![License](https://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](https://github.com/Yummypets/YPImagePicker/blob/master/LICENSE) [![Platform](https://img.shields.io/badge/platform-ios-lightgrey.svg)](http://cocoapods.org/pods/FYPhoto)

## Example
To run the example project, clone the repo, and run `pod install` from the Example directory first.

[Installation](#installation) - [Configuration](#configuration) - [Usage](#usage) - [Languages](#languages) - [UI Customization](#ui-customization)

Give it a quick try :
`pod repo update` then `pod try FYPhoto`

<img src="https://github.com/T2Je/FYPhoto/blob/main/Images/PickerBase.png?raw=true" width="200px" > <img src="https://github.com/T2Je/FYPhoto/blob/main/Images/BrowserBase.png?raw=true" width="200px" > <img src="https://github.com/T2Je/FYPhoto/blob/main/Images/CropImage.png?raw=true" width="200px" > <img src="https://github.com/T2Je/FYPhoto/blob/main/Images/VideoTrimmer.png?raw=true" width="200px" >

Those features are available just with a few lines of code!

## Notable Features

📷 Photo  
🎥 Video  
✂️ Crop  
⚡️ Flash    
📁 Albums  
🔢 Multiple Selection  
📏 Video Trimming  
And many more...

## Installation

#### Using [CocoaPods](http://cocoapods.org/)

First be sure to run `pod repo update` to get the latest version available.

Add `pod 'FYPhoto'` to your `Podfile` and run `pod install`. Also add `use_frameworks!` to the `Podfile`.

```ruby
target 'MyApp'
pod 'FYPhoto'
use_frameworks!
```

## Plist entries

In order for your app to access camera and photo libraries,
you'll need to ad these `plist entries` :

- Privacy - Camera Usage Description (photo/videos)
- Privacy - Photo Library Usage Description (library)
- Privacy - Microphone Usage Description (videos)

```xml
<key>NSCameraUsageDescription</key>
<string>yourWording</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>yourWording</string>
<key>NSMicrophoneUsageDescription</key>
<string>yourWording</string>
```

## Configuration

All the configuration endpoints are in the [FYPhotoPickerConfiguration](https://github.com/T2Je/FYPhoto/blob/main/FYPhoto/Classes/Configuration/FYPhotoPickerConfiguration.swift).
Below are the default value for reference, feel free to play around :)

### Picker
```swift
var pickerConfig = FYPhotoPickerConfiguration()
// [Edit configuration here ...]
// Build a picker with your configuration
let photoPicker = PhotoPickerViewController(configuration: pickerConfig)
```

#### General
```Swift
pickerConfig.selectionLimit = 0
pickerConfig.supportCamera = true
pickerConfig.mediaFilter = [.image, .video]

// Color
let colorConfig = FYColorConfiguration()
colorConfig.topBarColor = FYColorConfiguration.BarColor(itemTintColor: .red,
                                                        itemDisableColor: .gray,
                                                        itemBackgroundColor: .black,
                                                        backgroundColor: .blue)

// Similar setting code for pickerBottomBarColor and browserBottomBarColor

pickerConfig.colorConfiguration = colorConfig

```

#### Video
```swift
pickerConfig.compressedQuality = .mediumQuality
pickerConfig.maximumVideoMemorySize = 40 // MB
pickerConfig.maximumVideoDuration = 15 // Secs
```

### Browser

```swift
let photoBrowser = PhotoBrowserViewController.create(photos: photos, initialIndex: 0)
let photosBrowser = PhotoBrowserViewController.create(photos: [photo],
                                                      initialIndex: 0) {
            $0
                .buildPageControl()
                .buildBottomToolBar()
                .buildNavigationBar()
                .buildCaption()
                .buildThumbnailsForSelection()
                .showDeleteButtonForBrowser()
                .setMaximumCanBeSelected(1)
        }
```

## Usage

First things first `import FYPhoto`.  

### Picker
```swift
let photoPickerVC = PhotoPickerViewController(configuration: pickerConfig)
    
photoPickerVC.selectedPhotos = { [weak self] images in
//            images.forEach {
//                $0.asset
//                $0.data
//                $0.image
//            }
}

photoPickerVC.selectedVideo = { [weak self] selectedResult in
    switch selectedResult {
    case .success(let video):
//                video.briefImage
//                video.url
    case .failure(let error):
        print("selected video error: \(error)")
    }
}
photoPickerVC.modalPresentationStyle = .fullScreen
self.present(photoPickerVC, animated: true, completion: nil)
```

### Browser
```swift
let image = Photo.photoWithURL(url) // Similar init method for asset, image, data
let photoBrowser = PhotoBrowserViewController.create(photos: [image], initialIndex: 0)
// Use `.fyphoto` to easily bring smoothly drag-drop animation to your app.
self.fyphoto.present(photoBrowser, animated: true, completion: nil)
```
That's it !

## Languages
🇺🇸 English, 🇨🇳 Chinese. 

If your language is not supported, you can submit an issue or pull request with your `Localizable.strings` file to add a new language !

## UI Customization
We tried to keep things as native as possible, so this is done mostly through native Apis.

## References

This project references the following projects:
- [Pixel(has been renamed to Brightroom)](https://github.com/muukii/Brightroom)
- [YPImagePicker](https://github.com/Yummypets/YPImagePicker)
- [JXPhotoBrowser](https://github.com/JiongXing/PhotoBrowser)

## Dependency
FYPhoto relies on [SDWebImage](https://github.com/SDWebImage/SDWebImage) to provide async image downloader with cache support, relies on [UICircularProgressRing](https://github.com/luispadron/UICircularProgressRing) to render circular progress rings and timers .

## Obj-C support
Objective-C is not supported and this is not on our roadmap.
Swift is the future and dropping Obj-C is the price to pay to keep our velocity on this library :)

## Plan
Add more features to edit photo, include `Filter`, `Mosaic`, etc.

## License
FYPhoto is released under the MIT license. 

## Swift Version
Swift 5.4.
