//
//  PhotoEditorCropViewController.swift
//  FYPhoto_Example
//
//  Created by xiaoyang on 2021/4/16.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

public class PhotoEditorCropViewController: UIViewController {
    let rotateButton = UIButton()
    let resetButton = UIButton()
    let aspectRatioButton = UIButton()
    let topStackView = UIStackView()
    
    let cropView: CropView
    
    let cancelButton = UIButton()
    let doneButton = UIButton()
    let bottomStackView = UIStackView()
    
    var orientation: UIInterfaceOrientation {
        get {
            if #available(iOS 13, macOS 10.13, *) {
                return (UIApplication.shared.windows.first?.windowScene?.interfaceOrientation)!
            } else {
                return UIApplication.shared.statusBarOrientation
            }
        }
    }
    
    public init(image: UIImage = UIImage(named: "sunflower")!) {
        let viewModel = CropViewModel(image: image)
        cropView = CropView(viewModel: viewModel)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupCropView()
        
        setupTopStackView()
        setupBottomToolView()
        
        makeConstraints()
    }
    
    var initialLayout = false
    
    func setupTopStackView() {
        topStackView.distribution = .equalSpacing
        topStackView.addArrangedSubview(rotateButton)
        topStackView.addArrangedSubview(resetButton)
        topStackView.addArrangedSubview(aspectRatioButton)
        
        rotateButton.setImage(Asset.Crop.rotate.image, for: .normal)
        rotateButton.tintColor = .systemGray
        rotateButton.addTarget(self, action: #selector(rotatePhotoBy90DegreeClicked(_:)), for: .touchUpInside)
        
        resetButton.setTitle(L10n.resetPhoto, for: .normal)
        resetButton.addTarget(self, action: #selector(resetPhotoButtonClicked(_:)), for: .touchUpInside)
        resetButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        
        aspectRatioButton.setImage(Asset.Crop.aspectratio.image, for: .normal)
        aspectRatioButton.tintColor = .systemGray
        aspectRatioButton.addTarget(self, action: #selector(aspectRatioButtonClicked(_:)), for: .touchUpInside)
        
        view.addSubview(topStackView)
        
    }
    
    func setupCropView() {
        view.addSubview(cropView)
    }
    
    func setupBottomToolView() {
        bottomStackView.addArrangedSubview(cancelButton)
        bottomStackView.addArrangedSubview(doneButton)
        bottomStackView.distribution = .equalSpacing
        
        cancelButton.setTitle(L10n.cancel, for: .normal)
        doneButton.setTitle(L10n.done, for: .normal)
        
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        
        cancelButton.addTarget(self, action: #selector(cancelButtonClicked(_:)), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(doneButtonClicked(_:)), for: .touchUpInside)
        
        view.addSubview(bottomStackView)
        
    }
    
    func makeConstraints() {
        topStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            topStackView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            topStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            topStackView.heightAnchor.constraint(equalToConstant: 45),
            topStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor)
        ])
        
        cropView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cropView.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: 0),
            cropView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            cropView.bottomAnchor.constraint(equalTo: bottomStackView.topAnchor, constant: 0),
            cropView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
        ])
        
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomStackView.heightAnchor.constraint(equalToConstant: 45),
            bottomStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            bottomStackView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            bottomStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor)
        ])
    }
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !initialLayout {
            initialLayout = true
            cropView.updateViews()
        }
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        print(#function)
        hanleRotate()
    }
    
    func hanleRotate() {
//        if UIDevice.current.userInterfaceIdiom == .phone && orientation == .portraitUpsideDown {
//            return
//        }
        // When it is embedded in a container, the timing of viewDidLayoutSubviews
        // is different with the normal mode.
        // So delay the execution to make sure handleRotate runs after the final
        // viewDidLayoutSubviews
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.cropView.handleDeviceRotate()
        }
    }
    
    @objc func rotatePhotoBy90DegreeClicked(_ sender: UIButton) {
        cropView.counterclockRotate90Degree()
    }
    
    @objc func resetPhotoButtonClicked(_ sender: UIButton) {
        // TODO: 😴zZ
    }
    
    @objc func aspectRatioButtonClicked(_ sender: UIButton) {
        // TODO: 😴zZ
    }
    
    @objc func cancelButtonClicked(_ sender: UIButton) {
        // TODO: 😴zZ reminder
        dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonClicked(_ sender: UIButton) {
        // TODO: 😴zZ
    }
}
