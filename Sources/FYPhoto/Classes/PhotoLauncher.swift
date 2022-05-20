//
//  PhotoPickerHelper.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/8/4.
//

import Foundation
import AVFoundation
import Photos
import MobileCoreServices
import PhotosUI

public protocol PhotoLauncherDelegate: AnyObject {
    func selectedPhotosInPhotoLauncher(_ photos: [SelectedImage])
    func selectedVideoInPhotoLauncher(_ video: Result<SelectedVideo, Error>)
}

public extension PhotoLauncherDelegate {
    func selectedPhotosInPhotoLauncher(_ photos: [SelectedImage]) {}
    func selectedVideoInPhotoLauncher(_ video: Result<SelectedVideo, Error>) {}
}

/// A helper class to launch photo picker and camera.
@objc public class PhotoLauncher: NSObject {
    public struct PhotoLauncherConfig {
        /// the rectangle in the specified view in which to anchor the popover(for iPad).
        public var sourceRect: CGRect = .zero
        /// You can choose the maximum number of photos, default 6.
        public var maximumNumberCanChoose: Int = 6
        /// mediaOptions contain image, video. If camera action is choosed,
        /// this value determines camera can either capture video or image or both.
        /// Default video format is mp4.
        public var mediaOptions: MediaOptions = .image
        /// maximum video capture duration. Default 15s
        public var videoMaximumDuration: TimeInterval = 15
        /// url extension, e.g., xxx.mp4
        public var videoPathExtension: String = "mp4"

        public init() {}
    }

    public typealias CameraContainer = UIViewController & UINavigationControllerDelegate & CameraViewControllerDelegate

    public weak var delegate: PhotoLauncherDelegate?

    var captureVideoImagePicker: UIImagePickerController?

    deinit {
        print(#function, #file)
    }

    public override init() {
        super.init()
    }

    @available(swift, deprecated: 1.0.0, message: "Use PhotoPickerViewController instead")
    /// Show PhotoPicker or Camera action sheet. This is for CUSTOM photo picker, if you want to use SYSTEM photo picker,
    /// use
    /// `showSystemPhotoPickerAletSheet(in:, sourceRect:, maximumNumberCanChoose:, isOnlyImages:)`
    /// instead.
    /// CUSTOM PhotoPicker need Authority.
    /// - Parameters:
    ///   - container: camera container.
    ///   - config: launcher config. Default config:
    ///     sourceRect = .zero, maximumNumberCanChoose = 6, isOnlyImages = true, videoMaximumDuration = 15, videoPathExtension = mp4
    public func showCustomPhotoPickerCameraAlertSheet(in container: CameraContainer, config: PhotoLauncherConfig = PhotoLauncherConfig()) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let photo = UIAlertAction(title: L10n.photo, style: .default) { (_) in
            self.launchCustomPhotoLibrary(in: container, maximumNumberCanChoose: config.maximumNumberCanChoose, mediaOptions: config.mediaOptions)
        }
        let camera = UIAlertAction(title: L10n.camera, style: .default) { (_) in
            if config.mediaOptions == .image {
                self.launchCamera(in: container,
                                  captureMode: .image,
                                  videoMaximumDuration: config.videoMaximumDuration)
            } else if config.mediaOptions == .video {
                self.launchCamera(in: container,
                                  captureMode: .video,
                                  moviePathExtension: config.videoPathExtension,
                                  videoMaximumDuration: config.videoMaximumDuration)
            } else {
                self.launchCamera(in: container,
                                  captureMode: [.image, .video],
                                  moviePathExtension: config.videoPathExtension,
                                  videoMaximumDuration: config.videoMaximumDuration)
            }
        }

        let cancel = UIAlertAction(title: L10n.cancel, style: .cancel, handler: nil)

        alert.addAction(photo)
        alert.addAction(camera)
        alert.addAction(cancel)
        
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = container.view
                popoverController.sourceRect = config.sourceRect
            }
        }
        container.present(alert, animated: true, completion: nil)
    }

    /// launch camera for capturing media
    /// - Parameters:
    ///   - viewController: container comforms to some protocols.
    ///   - captureModes: image / movie
    ///   - moviePathExtension: movie extension, default is mp4.
    ///   - videoMaximumDuration: video capture duration. Default 15s
    public func launchCamera(in viewController: CameraContainer,
                             captureMode: MediaOptions = .image,
                             moviePathExtension: String? = nil,
                             videoMaximumDuration: TimeInterval = 15) {
        let cameraVC = CameraViewController()
        cameraVC.captureMode = captureMode
        cameraVC.videoMaximumDuration = videoMaximumDuration
        cameraVC.moviePathExtension = moviePathExtension ?? "mp4"
        cameraVC.delegate = viewController
        cameraVC.modalPresentationStyle = .fullScreen
        viewController.present(cameraVC, animated: true, completion: nil)
    }

    public func launchCustomPhotoLibrary(in viewController: UIViewController,
                                         maximumNumberCanChoose: Int,
                                         mediaOptions: MediaOptions = .image) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized, .limited:
            launchPhotoLibrary(in: viewController, maximumNumberCanChoose, mediaOptions: mediaOptions)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                switch status {
                case .authorized:
                    DispatchQueue.main.async {
                        self.launchPhotoLibrary(in: viewController, maximumNumberCanChoose, mediaOptions: mediaOptions)
                    }
                default: break
                }
            }
        default: break
        }
    }

    func launchPhotoLibrary(in viewController: UIViewController, _ maximumNumberCanChoose: Int, mediaOptions: MediaOptions) {
        var configuration = FYPhotoPickerConfiguration()
        configuration.selectionLimit = maximumNumberCanChoose
        configuration.supportCamera = false
//        configuration.filterdMedia = mediaOptions
        configuration.mediaFilter = mediaOptions

        let photoPicker = PhotoPickerViewController(configuration: configuration)

        photoPicker.selectedPhotos = { [weak self] images in
            self?.delegate?.selectedPhotosInPhotoLauncher(images)
        }
        photoPicker.selectedVideo = { [weak self] video in
            self?.delegate?.selectedVideoInPhotoLauncher(video)
        }

        viewController.present(photoPicker, animated: true, completion: nil)
    }

    @objc public func previousDeniedCaptureAuthorization() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied:
            return true
        default:
            return false
        }
    }
}

@available(iOS 14, *)
extension PhotoLauncher: PHPickerViewControllerDelegate {

    /// Show PhotoPicker or Camera action sheet. This is for SYSTEM photo picker, if you want to use CUSTOM photo picker,
    /// use
    /// `showCustomPhotoPickerAletSheet(in:, sourceRect:, maximumNumberCanChoose:, isOnlyImages:)`
    /// instead.
    /// SYSTEM PhotoPicker do not need Authority.
    /// - Parameters:
    ///   - container: camera container.
    ///   - config: launcher config. Default config:
    ///     sourceRect = .zero, maximumNumberCanChoose = 6, isOnlyImages = true, videoMaximumDuration = 15, videoPathExtension = mp4
    public func showSystemPhotoPickerCameraAlertSheet(in container: CameraContainer,
                                                      config: PhotoLauncherConfig = PhotoLauncherConfig()) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let photo = UIAlertAction(title: L10n.photo, style: .default) { (_) in
            self.launchSystemPhotoPicker(in: container, maximumNumberCanChoose: config.maximumNumberCanChoose, mediaOptions: config.mediaOptions)
        }
        let camera = UIAlertAction(title: L10n.camera, style: .default) { (_) in
            if config.mediaOptions == .image {
                self.launchCamera(in: container, captureMode: .image, videoMaximumDuration: config.videoMaximumDuration)
            } else if config.mediaOptions == .video {
                self.launchCamera(in: container, captureMode: .video, moviePathExtension: config.videoPathExtension, videoMaximumDuration: config.videoMaximumDuration)
            } else {
                self.launchCamera(in: container, captureMode: [.image, .video], moviePathExtension: config.videoPathExtension, videoMaximumDuration: config.videoMaximumDuration)
            }
        }

        let cancel = UIAlertAction(title: L10n.cancel, style: .cancel, handler: nil)

        alert.addAction(photo)
        alert.addAction(camera)
        alert.addAction(cancel)
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = container.view
                popoverController.sourceRect = config.sourceRect
            }
        }
        container.present(alert, animated: true, completion: nil)
    }

    /// Launch system PhotoPicker with selectionLimit, mediaOptions in viewcontroller
    /// mediaOptions parameter should be ethier `.image` or `.video`.
    ///
    /// - Parameters:
    ///   - viewController: presenting viewController
    ///   - maximumNumberCanChoose: selectionLimit. For `.video` media, 1 always as the selectionLimit
    ///   - mediaOptions: ethier `.image` or `.video`. `.all` value will be reset to `.image`
    public func launchSystemPhotoPicker(in viewController: UIViewController, maximumNumberCanChoose: Int = 1, mediaOptions: MediaOptions = .image) {
        var configuration = PHPickerConfiguration()
        let filter: PHPickerFilter
        if mediaOptions == .image {
            filter = PHPickerFilter.images
            configuration.selectionLimit = maximumNumberCanChoose
        } else if mediaOptions == .video {
            filter = PHPickerFilter.videos
            configuration.selectionLimit = 1
        } else {
            filter = PHPickerFilter.images
            configuration.selectionLimit = maximumNumberCanChoose
//            filter = PHPickerFilter.any(of: [.images, .videos])
        }
        configuration.filter = filter

        let pickerController = PHPickerViewController(configuration: configuration)
        pickerController.delegate = self
        viewController.present(pickerController, animated: true, completion: nil)
    }

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        if picker.configuration.filter == PHPickerFilter.images {
            loadItemFromFetchResults(results) { (images: [SelectedImage]) in
                self.delegate?.selectedPhotosInPhotoLauncher(images)
            }
        } else if picker.configuration.filter == PHPickerFilter.videos {
            loadItemFromFetchResults(results) { (videos: [SelectedVideo]) in
                guard !videos.isEmpty else { return }
                let result = Result<SelectedVideo, Error>.success(videos[0])
                self.delegate?.selectedVideoInPhotoLauncher(result)
            }
        }

        picker.dismiss(animated: true, completion: nil)
    }

    func loadItemFromFetchResults<T>(_ results: [PHPickerResult], completion: @escaping (([T]) -> Void)) {
        guard !results.isEmpty else {
            completion([])
            return
        }

        var items: [T] = []
        let group = DispatchGroup()

        results.forEach { result in
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    if let image = image as? UIImage {
                        var asset: PHAsset?
                        if let id = result.assetIdentifier {
                            asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
                        }
                        if let image = SelectedImage(asset: asset, image: image) as? T {
                            items.append(image)
                        }
                    } else {
                        #if DEBUG
                        print("Couldn't load image with error: \(error?.localizedDescription ?? "unknown error")")
                        #endif
                    }
                    group.leave()
                }
            } else if result.itemProvider.hasRepresentationConforming(toTypeIdentifier: AVFileType.mp4.rawValue, fileOptions: []) {
                group.enter()
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: AVFileType.mp4.rawValue) { (url, error) in
                    if let error = error {
                        #if DEBUG
                        print("❌ Couldn't load video with error: \(error)")
                        #endif
                    } else {
                        guard let url = url else { return }
//                        print("selected video url: \(url)")
//                        print("url exsisted \(FileManager.default.fileExists(atPath: url.path))")
                        let video = SelectedVideo(url: url)
                        if let t = video as? T {
                            url.generateThumbnail(completion: { (result) in
                                video.briefImage = try? result.get()
                            })
                            items.append(t)
                        }
                    }
                    group.leave()
                }
            } else if result.itemProvider.hasRepresentationConforming(toTypeIdentifier: AVFileType.mov.rawValue, fileOptions: []) {
                group.enter()
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: AVFileType.mov.rawValue) { (url, error) in
                    if let error = error {
                        #if DEBUG
                        print("❌ Couldn't load video with error: \(error)")
                        #endif
                    } else {
                        guard let url = url else { return }
//                        print("selected video url: \(url)")
//                        print("url exsisted \(FileManager.default.fileExists(atPath: url.path))")
                        let video = SelectedVideo(url: url)
                        if let t = video as? T {
                            url.generateThumbnail(completion: { (result) in
                                video.briefImage = try? result.get()
                            })
                            items.append(t)
                        }
                    }
                    group.leave()
                }
            } else {
                print("couldn't load item")
            }
        }

        group.notify(queue: .main) {
            completion(items)
        }
    }

}
