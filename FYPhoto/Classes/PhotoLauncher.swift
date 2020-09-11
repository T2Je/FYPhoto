//
//  PhotoPickerHelper.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/8/4.
//

import Foundation
import AVFoundation
import Photos

public protocol PhotoLauncherDelegate: class {
    func selectedPhotosInPhotoLauncher(_ photos: [UIImage])
//    func selectedPhotosInPhotoLauncher(_ photos: [Photo])
}

@objc public class PhotoLauncher: NSObject {
    public typealias ImagePickerContainer = UIViewController & UINavigationControllerDelegate & UIImagePickerControllerDelegate

//    @objc public static var shared: PhotoLauncher = PhotoLauncher()
    public weak var delegate: PhotoLauncherDelegate?

    deinit {
        print(#function, #file)
    }

    public override init() {
        super.init()
    }

    @objc public func verifyAndLaunchForCapture(in viewController: ImagePickerContainer, mediaTypes: [String] = ["public.image"]) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            // launch picker
            launchCamera(in: viewController, mediaTypes: mediaTypes)
        case .notDetermined:
            // requset
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted {
                    DispatchQueue.main.async {
                        self.launchCamera(in: viewController, mediaTypes: mediaTypes)
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

    func launchCamera(in container: ImagePickerContainer, mediaTypes: [String] = ["public.image"]) {
        let imageController = UIImagePickerController()
        imageController.sourceType = .camera
        imageController.cameraCaptureMode = .photo
        if UIImagePickerController.isCameraDeviceAvailable(.rear) {
            imageController.cameraDevice = .rear
        } else {
            imageController.cameraDevice = .front
        }
        imageController.mediaTypes = mediaTypes
        imageController.delegate = container
        container.modalPresentationStyle = .overFullScreen
        container.present(imageController, animated: true, completion: nil)
    }

    /// Show imagePicker or camera action sheet
    /// - Parameters:
    ///   - container: camera container
    ///   - sourceRect: the rectangle in the specified view in which to anchor the popover(for iPad).
    ///   - maximumNumberCanChoose: You can choose the maximum number of photos, default 6.
    ///   - isOnlyImages: true => image, false => image & video. If camera action is choosed,
    ///    this flag determines whether camera can capture video.
    public func showImagePickerAlertSheet(in container: ImagePickerContainer,
                                          sourceRect: CGRect,
                                          _ maximumNumberCanChoose: Int = 6,
                                          isOnlyImages: Bool = true) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let photo = UIAlertAction(title: "photo".photoTablelocalized, style: .default) { (_) in
            self.verifyAndLaunchForPhotoLibrary(in: container, maximumNumberCanChoose, isOnlyImages: isOnlyImages)
        }
        let camera = UIAlertAction(title: "camera".photoTablelocalized, style: .default) { (_) in
            if isOnlyImages {
                self.verifyAndLaunchForCapture(in: container)
            } else {
                self.verifyAndLaunchForCapture(in: container, mediaTypes: ["public.image", "public.movie"])
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
}
