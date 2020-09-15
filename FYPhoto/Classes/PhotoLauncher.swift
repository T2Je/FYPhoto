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

public protocol PhotoLauncherDelegate: class {
    func selectedPhotosInPhotoLauncher(_ photos: [UIImage])
//    func selectedPhotosInPhotoLauncher(_ photos: [Photo])
}

@objc public class PhotoLauncher: NSObject {
    public typealias ImagePickerContainer = UIViewController & UINavigationControllerDelegate & UIImagePickerControllerDelegate

//    @objc public static var shared: PhotoLauncher = PhotoLauncher()
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

    func verifyAndLaunchForPhotoLibrary(in container: ImagePickerContainer,_ maximumNumberCanChoose: Int, isOnlyImages: Bool = true) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            launchPhotoLibrary(in: container, maximumNumberCanChoose, isOnlyImages: isOnlyImages)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                switch status {
                case .authorized:
                    DispatchQueue.main.async {
                        self.launchPhotoLibrary(in: container, maximumNumberCanChoose, isOnlyImages: isOnlyImages)
                    }
                default: break
                }
            }
        default: break
        }
    }

    func launchPhotoLibrary(in container: ImagePickerContainer, _ maximumNumberCanChoose: Int, isOnlyImages: Bool) {
        let gridVC = AssetGridViewController(maximumToSelect: maximumNumberCanChoose, isOnlyImages: isOnlyImages)
        gridVC.selectedPhotos = { [weak self] images in
            print("selected \(images.count) photos: \(images)")
            self?.delegate?.selectedPhotosInPhotoLauncher(images)
        }

        let navi = UINavigationController(rootViewController: gridVC)
        navi.modalPresentationStyle = .fullScreen
        container.present(navi, animated: true, completion: nil)
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
