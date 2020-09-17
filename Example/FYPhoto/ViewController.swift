//
//  ViewController.swift
//  FYPhoto
//
//  Created by t2je on 07/15/2020.
//  Copyright (c) 2020 t2je. All rights reserved.
//

import UIKit
import FYPhoto
import Photos
import PhotosUI

class ViewController: UIViewController {

    var stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)


        print("PhotosAuthority.isCameraAvailable: \(PhotosAuthority.isCameraAvailable())")
        print("PhotosAuthority.isPhotoLibraryAvailable: \(PhotosAuthority.isPhotoLibraryAvailable())")
        print("PhotosAuthority.doesCameraSupportTakingPhotos: \(PhotosAuthority.doesCameraSupportTakingPhotos())")
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - UI
    fileprivate func setupUI() {
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.distribution = .equalCentering

        let photosViewBtn = UIButton()
        let suishoupaiBtn = UIButton()

        let cameraPhotoBtn = UIButton()

        photosViewBtn.setTitle("浏览全部照片", for: .normal)
        suishoupaiBtn.setTitle("随手拍", for: .normal)
        cameraPhotoBtn.setTitle("照片or相机", for: .normal)

        photosViewBtn.setTitleColor(.systemBlue, for: .normal)
        suishoupaiBtn.setTitleColor(.systemBlue, for: .normal)
        cameraPhotoBtn.setTitleColor(.systemBlue, for: .normal)

        photosViewBtn.addTarget(self, action: #selector(photosViewButtonClicked(_:)), for: .touchUpInside)
        suishoupaiBtn.addTarget(self, action: #selector(suiShouPaiButtonClicked(_:)), for: .touchUpInside)
        cameraPhotoBtn.addTarget(self, action: #selector(cameraPhotoButtonClicked(_:)), for: .touchUpInside)

        stackView.addArrangedSubview(photosViewBtn)
        stackView.addArrangedSubview(suishoupaiBtn)
        stackView.addArrangedSubview(cameraPhotoBtn)

        self.view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                stackView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 300),
                stackView.widthAnchor.constraint(equalToConstant: 200),
                stackView.heightAnchor.constraint(equalToConstant: 200)
            ])
        } else {
            // Fallback on earlier versions
            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                stackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 300),
                stackView.widthAnchor.constraint(equalToConstant: 200),
                stackView.heightAnchor.constraint(equalToConstant: 200)
            ])
        }

//        let imageController = UIImagePickerController()
//        imageController.sourceType = .camera
//        imageController.cameraCaptureMode = .photo
//        print("available media types: \(UIImagePickerController.availableMediaTypes(for: .camera))")
    }

// MARK: - Button action
    @objc func photosViewButtonClicked(_ sender: UIButton) {
        

        PHPhotoLibrary.requestAuthorization { (status) in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    let gridVC = AssetGridViewController(maximumToSelect: 6, isOnlyImages: true)
                    gridVC.selectedPhotos = { [weak self] images in
                        print("selected \(images.count) photos: \(images)")
                    }
//                    let navi = CustomNavigationController(rootViewController: gridVC)
                    let navi = UINavigationController(rootViewController: gridVC)
                    navi.modalPresentationStyle = .fullScreen
                    self.present(navi, animated: true, completion: nil)
//                    self.navigationController?.navigationBar.tintColor = .white
//                    self.navigationController?.pushViewController(gridVC, animated: true)

                case .denied, .restricted, .notDetermined:
                    print("⚠️ without authorization! ⚠️")
                case .limited:
                    print("limited")
                @unknown default:
                    fatalError()
                }
            }

        }
    }

    @objc func suiShouPaiButtonClicked(_ sender: UIButton) {
        if #available(iOS 14, *) {
            let addPhotoVC = AddPhotoBlogViewController()
            addPhotoVC.selectedImageArray = []
            self.navigationController?.pushViewController(addPhotoVC, animated: true)
        } else {
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        let addPhotoVC = AddPhotoBlogViewController()
                        addPhotoVC.selectedImageArray = []
                        self.navigationController?.pushViewController(addPhotoVC, animated: true)
                        //                            let navi = CustomTransitionNavigationController(rootViewController: addPhotoVC)
                        //                            navi.modalPresentationStyle = .fullScreen
                    //                            self.present(navi, animated: true, completion: nil)
                    case .denied, .restricted, .notDetermined:
                        print("⚠️ without authorization! ⚠️")
                    @unknown default:
                        fatalError()
                    }
                }

            }

        }

    }

    @objc func cameraPhotoButtonClicked(_ sender: UIButton) {
        let photoLanucher = PhotoLauncher()
        photoLanucher.delegate = self
        if #available(iOS 14, *) {
            photoLanucher.showSystemPhotoPickerAletSheet(in: self, sourceRect: sender.frame, maximumNumberCanChoose: 6, isOnlyImages: false)
        } else {
            photoLanucher.showImagePickerAlertSheet(in: self, sourceRect: sender.frame, maximumNumberCanChoose: 6, isOnlyImages: false)
        }

    }

    @objc func screenshotTaken(_ noti: Notification) {
        print("screenshot taken!")
        print(noti)

    }
}

extension ViewController: PhotoLauncherDelegate {
    func selectedPhotosInPhotoLauncher(_ photos: [UIImage]) {
        print("selected \(photos.count) images")
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

}

@available(iOS 14, *)
extension ViewController: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        print("selected totol \(results.count) photos")
        parsePickerFetchResults(results)
        picker.dismiss(animated: true, completion: nil)
    }

    func parsePickerFetchResults(_ results: [PHPickerResult]) {
        guard !results.isEmpty else {
            return
        }
        var images: [UIImage] = []

        results.forEach { result in
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
//                        guard let self = self else { return }
                        if let image = image as? UIImage {
                            images.append(image)
                        } else {
                            images.append(UIImage(named: "add_photo")!)
                            print("Couldn't load image with error: \(error?.localizedDescription ?? "unknown error")")
                        }
                    }
                }
            }
        }
    }
}
