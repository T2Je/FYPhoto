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

class ViewController: UIViewController {

    var stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

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

        photosViewBtn.setTitle("浏览全部照片", for: .normal)
        suishoupaiBtn.setTitle("随手拍", for: .normal)

        photosViewBtn.setTitleColor(.systemBlue, for: .normal)
        suishoupaiBtn.setTitleColor(.systemBlue, for: .normal)

        photosViewBtn.addTarget(self, action: #selector(photosViewButtonClicked(_:)), for: .touchUpInside)
        suishoupaiBtn.addTarget(self, action: #selector(suiShouPaiButtonClicked(_:)), for: .touchUpInside)

        stackView.addArrangedSubview(photosViewBtn)
        stackView.addArrangedSubview(suishoupaiBtn)

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
                    let gridVC = AssetGridViewController(maximumToSelect: 6, isOnlyImages: false)
                    gridVC.selectedPhotos = { [weak self] images in
                        print("selected \(images.count) photos: \(images)")
                    }
//                    let navi = CustomTransitionNavigationController(rootViewController: gridVC)
//                    let navi = UINavigationController(rootViewController: gridVC)
//                    navi.modalPresentationStyle = .fullScreen
//                    self.present(navi, animated: true, completion: nil)
                    
                    self.navigationController?.pushViewController(gridVC, animated: true)

                case .denied, .restricted, .notDetermined:
                    print("⚠️ without authorization! ⚠️")
                @unknown default:
                    fatalError()
                }
            }

        }
    }

    @objc func suiShouPaiButtonClicked(_ sender: UIButton) {
        PHPhotoLibrary.requestAuthorization { (status) in
                    DispatchQueue.main.async {
                        switch status {
                        case .authorized:
                            let addPhotoVC = AddPhotoBlogViewController()
                            addPhotoVC.selectedImageArray = []
                            let navi = CustomTransitionNavigationController(rootViewController: addPhotoVC)
                            navi.modalPresentationStyle = .fullScreen
                            
                            self.present(navi, animated: true, completion: nil)
                        case .denied, .restricted, .notDetermined:
                            print("⚠️ without authorization! ⚠️")
                        @unknown default:
                            fatalError()
                        }
                    }

                }
    }

    @objc func screenshotTaken(_ noti: Notification) {
        print("screenshot taken!")
        print(noti)

    }
}

