// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal static let browserErrorLoading = ImageAsset(name: "Browser-ErrorLoading")
  internal enum Crop {
    internal static let aspectratio = ImageAsset(name: "aspectratio")
    internal static let icons8EditImage = ImageAsset(name: "icons8-edit-image")
    internal static let rotate = ImageAsset(name: "rotate")
  }
  internal static let flipCamera = ImageAsset(name: "FlipCamera")
  internal static let imageError = ImageAsset(name: "ImageError")
  internal static let imageSelectedOff = ImageAsset(name: "ImageSelectedOff")
  internal static let imageSelectedOn = ImageAsset(name: "ImageSelectedOn")
  internal static let imageSelectedSmallOff = ImageAsset(name: "ImageSelectedSmallOff")
  internal static let imageSelectedSmallOn = ImageAsset(name: "ImageSelectedSmallOn")
  internal static let playButtonOverlayLarge = ImageAsset(name: "PlayButtonOverlayLarge")
  internal static let playButtonOverlayLargeTap = ImageAsset(name: "PlayButtonOverlayLargeTap")
  internal static let uiBarButtonItemArrowLeft = ImageAsset(name: "UIBarButtonItemArrowLeft")
  internal static let uiBarButtonItemArrowRight = ImageAsset(name: "UIBarButtonItemArrowRight")
  internal static let albumArrow = ImageAsset(name: "albumArrow")
  internal static let back = ImageAsset(name: "back")
  internal static let coverPlaceholder = ImageAsset(name: "cover_placeholder")
  internal static let icons8FlashOff = ImageAsset(name: "icons8-flash-off")
  internal static let icons8FlashOn = ImageAsset(name: "icons8-flash-on")
  internal static let icons8Pause = ImageAsset(name: "icons8-pause")
  internal static let icons8Play = ImageAsset(name: "icons8-play")
  internal static let photoImageCamera = ImageAsset(name: "photo_image_camera")
  internal static let photoVideoCamera = ImageAsset(name: "photo_video_camera")
  internal static let playButton = ImageAsset(name: "play_button")
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
}

internal extension ImageAsset.Image {
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    guard let url = Bundle(for: BundleToken.self).url(forResource: "FYPhoto", withExtension: "bundle") else {
        return .main
    }
    return Bundle(url: url) ?? .main
	#endif
  }()
}
// swiftlint:enable convenience_type

