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

public protocol PhotoLauncherDelegate: class {
    func selectedPhotosInPhotoLauncher(_ photos: [UIImage])
//    func selectedPhotosInPhotoLauncher(_ photos: [Photo])
}

@objc public class PhotoLauncher: NSObject {
    public typealias ImagePickerContainer = UIViewController & UINavigationControllerDelegate & UIImagePickerControllerDelegate

    public weak var delegate: PhotoLauncherDelegate?

    var captureVideoImagePicker: UIImagePickerController?

    deinit {
        print(#function, #file)
    }

    public override init() {
        super.init()
    }

    /// Show imagePicker or camera action sheet
    /// - Parameters:
    ///   - container: camera container. For capturing video in limited duration by custom overlay, container should comform to VideoCaptureOverlayDelegate
    ///   - sourceRect: the rectangle in the specified view in which to anchor the popover(for iPad).
    ///   - maximumNumberCanChoose: You can choose the maximum number of photos, default 6.
    ///   - isOnlyImages: true => image, false => image & video. If camera action is choosed,
    ///    this flag determines whether camera can capture video.
    public func showImagePickerAlertSheet(in container: ImagePickerContainer,
                                          sourceRect: CGRect,
                                          maximumNumberCanChoose: Int = 6,
                                          isOnlyImages: Bool = true) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let photo = UIAlertAction(title: "photo".photoTablelocalized, style: .default) { (_) in
            self.verifyAndLaunchForPhotoLibrary(in: container, maximumNumberCanChoose, isOnlyImages: isOnlyImages)
        }
        let camera = UIAlertAction(title: "camera".photoTablelocalized, style: .default) { (_) in
            if isOnlyImages {
                self.verifyAndLaunchForCapture(in: container)
            } else {
                self.verifyAndLaunchForCapture(in: container, isOnlyImages: isOnlyImages)
            }
        }

        let cancel = UIAlertAction(title: "cancel", style: .cancel, handler: nil)

        alert.addAction(photo)
        alert.addAction(camera)
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceView = container.view
        alert.popoverPresentationController?.sourceRect = sourceRect
        container.present(alert, animated: true, completion: nil)
    }

    @objc public func verifyAndLaunchForCapture(in viewController: ImagePickerContainer, isOnlyImages: Bool = true) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            // launch picker
            launchCamera(in: viewController, isOnlyImages: isOnlyImages)
        case .notDetermined:
            // requset
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted {
                    DispatchQueue.main.async {
                        self.launchCamera(in: viewController, isOnlyImages: isOnlyImages)
                    }
                } else {
                    print("denied capture authorization")
                }
            }
        case .denied, .restricted:
            // .denied: The user has previously denied access
            break
        @unknown default:
            fatalError()
        }
    }

    @objc public func verifyAndLaunchForPhotoLibrary(in viewController: UIViewController,_ maximumNumberCanChoose: Int, isOnlyImages: Bool = true) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            launchPhotoLibrary(in: viewController, maximumNumberCanChoose, isOnlyImages: isOnlyImages)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                switch status {
                case .authorized:
                    DispatchQueue.main.async {
                        self.launchPhotoLibrary(in: viewController, maximumNumberCanChoose, isOnlyImages: isOnlyImages)
                    }
                default: break
                }
            }
        default: break
        }
    }

    func launchPhotoLibrary(in viewController: UIViewController, _ maximumNumberCanChoose: Int, isOnlyImages: Bool) {
        let gridVC = AssetGridViewController(maximumToSelect: maximumNumberCanChoose, isOnlyImages: isOnlyImages)
        gridVC.selectedPhotos = { [weak self] images in
            print("selected \(images.count) photos: \(images)")
            self?.delegate?.selectedPhotosInPhotoLauncher(images)
        }

        let navi = UINavigationController(rootViewController: gridVC)
        navi.modalPresentationStyle = .fullScreen
        viewController.present(navi, animated: true, completion: nil)
    }

    @objc public func previousDeniedCaptureAuthorization() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied:
            return true
        default:
            return false
        }
    }

    func launchCamera(in container: ImagePickerContainer, isOnlyImages: Bool = true) {
        let imageController = UIImagePickerController()
        imageController.sourceType = .camera
        if UIImagePickerController.isCameraDeviceAvailable(.rear) {
            imageController.cameraDevice = .rear
        } else {
            imageController.cameraDevice = .front
        }
        if isOnlyImages {
            imageController.cameraCaptureMode = .photo
            imageController.allowsEditing = false
            imageController.mediaTypes = [kUTTypeImage] as [String]
        } else {
            imageController.videoMaximumDuration = 15
            imageController.allowsEditing = true
//            imageController.mediaTypes = ["public.image", "public.movie"]
            imageController.mediaTypes = [kUTTypeMovie, kUTTypeImage] as [String]
            imageController.cameraCaptureMode = .video
            addVideoCaptureOverlay(on: imageController)
            self.captureVideoImagePicker = imageController
        }
        imageController.delegate = container
        container.modalPresentationStyle = .overFullScreen
        container.present(imageController, animated: true, completion: nil)
    }

    func addVideoCaptureOverlay(on imagePickerController: UIImagePickerController) {
        let frame = imagePickerController.cameraOverlayView?.frame ?? UIScreen.main.bounds

        let overlay = VideoCaptureOverlay(videoMaximumDuration: imagePickerController.videoMaximumDuration, frame: frame)
        overlay.delegate = self
        imagePickerController.showsCameraControls = false
        imagePickerController.cameraOverlayView = overlay
    }
}

extension PhotoLauncher: VideoCaptureOverlayDelegate {
    public func dismissVideoCapture() {
        captureVideoImagePicker?.dismiss(animated: true, completion: nil)
    }

    public func takePicture() {
        guard let imagePicker = captureVideoImagePicker else { return }
        imagePicker.cameraCaptureMode = .photo
        imagePicker.takePicture()
    }

    public func startVideoCapturing() {
        guard let imagePicker = captureVideoImagePicker else { return }
        imagePicker.cameraCaptureMode = .video
        imagePicker.startVideoCapture()
    }

    public func stopVideoCapturing(_ isCancel: Bool) {
        guard let imagePicker = captureVideoImagePicker else { return }
        print(#function)
        imagePicker.stopVideoCapture()
    }

    public func switchCamera() {
        guard let imagePicker = captureVideoImagePicker else { return }
        print(#function)
        if imagePicker.cameraDevice == .rear {
            imagePicker.cameraDevice = .front
        } else {
            imagePicker.cameraDevice = .rear
        }
    }
}

@available(iOS 14, *)
extension PhotoLauncher: PHPickerViewControllerDelegate {

    public func showSystemPhotoPickerAletSheet(in container: ImagePickerContainer,
                                               sourceRect: CGRect,
                                               maximumNumberCanChoose: Int = 6,
                                               isOnlyImages: Bool = true) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let photo = UIAlertAction(title: "photo".photoTablelocalized, style: .default) { (_) in
            self.launchSystemPhotoPicker(in: container, maximumNumberCanChoose: maximumNumberCanChoose, isOnlyImages: isOnlyImages)
        }
        let camera = UIAlertAction(title: "camera".photoTablelocalized, style: .default) { (_) in
            if isOnlyImages {
                self.verifyAndLaunchForCapture(in: container, isOnlyImages: true)
            } else {
                self.verifyAndLaunchForCapture(in: container, isOnlyImages: false)
            }
        }

        let cancel = UIAlertAction(title: "cancel".photoTablelocalized, style: .cancel, handler: nil)

        alert.addAction(photo)
        alert.addAction(camera)
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceView = container.view
        alert.popoverPresentationController?.sourceRect = sourceRect
        container.present(alert, animated: true, completion: nil)
    }

    public func launchSystemPhotoPicker(in viewController: UIViewController, maximumNumberCanChoose: Int = 6, isOnlyImages: Bool = true) {
        var configuration = PHPickerConfiguration()
        let filter: PHPickerFilter
        if isOnlyImages {
            filter = PHPickerFilter.images
        } else {
            filter = PHPickerFilter.any(of: [.images, .videos])
        }
        configuration.filter = filter
        configuration.selectionLimit = maximumNumberCanChoose
        let pickerController = PHPickerViewController(configuration: configuration)
        pickerController.delegate = self
        viewController.present(pickerController, animated: true, completion: nil)
    }

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        parsePickerFetchResults(results) { (images) in
            self.delegate?.selectedPhotosInPhotoLauncher(images)
        }
        picker.dismiss(animated: true, completion: nil)
    }

    func parsePickerFetchResults(_ results: [PHPickerResult], completion: @escaping (([UIImage]) -> Void)) {
        guard !results.isEmpty else {
            completion([])
            return
        }

        var images: [UIImage] = []
        let group = DispatchGroup()

        results.forEach { result in
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    group.leave()
                    if let image = image as? UIImage {
                        images.append(image)
                    } else {
                        if let placeholder = "cover_placeholder".photoImage {
                            images.append(placeholder)
                        }
                        print("Couldn't load image with error: \(error?.localizedDescription ?? "unknown error")")
                    }
                }
            }
        }

        group.notify(queue: .main) {
            completion(images)
        }
    }

}
