//
//  PhotoPickerHelper.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/8/4.
//

import Foundation
import AVFoundation
import Photos

@objc public class PhotoPickerHelper: NSObject {
    public typealias ImagePickerContainer = UIViewController & UINavigationControllerDelegate & UIImagePickerControllerDelegate

    @objc public static var shared: PhotoPickerHelper = PhotoPickerHelper()

    private override init() {
        super.init()
    }

    @objc public func verifyAndLaunchForCapture(in viewController: ImagePickerContainer) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            // launch picker
            launchCamera(in: viewController)
        case .notDetermined:
            // requset
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted {
                    DispatchQueue.main.async {
                        self.launchCamera(in: viewController)
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

    @objc public func previousDeniedCaptureAuthorization() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied:
            return true
        default:
            return false
        }
    }

    func launchCamera(in viewController: ImagePickerContainer) {
        let imageController = UIImagePickerController()
        imageController.sourceType = .camera
        imageController.cameraCaptureMode = .photo
        if UIImagePickerController.isCameraDeviceAvailable(.rear) {
            imageController.cameraDevice = .rear
        } else {
            imageController.cameraDevice = .front
        }
        imageController.mediaTypes = ["public.image"]
        imageController.delegate = viewController
        viewController.modalPresentationStyle = .overFullScreen
        viewController.present(imageController, animated: true, completion: nil)
    }
}
