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
    
    let viewModel: CropViewModel
    
    let cropView: CropView
    let guideView = InteractiveCropGuideView()
    
    let maskManager = CropViewMaskManager()
    
    let cancelButton = UIButton()
    let doneButton = UIButton()
    let bottomStackView = UIStackView()
    
    private var isGuideViewZoommingOut = false
    private var guideViewResizeAnimator: UIViewPropertyAnimator?
    
    private var maximumRectKeyValueObservation: NSKeyValueObservation?
    
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
        viewModel = CropViewModel(image: image)
        cropView = CropView(image: image)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupData()
        setupCropView()
        setupBlurredManager()
        setupGuideView()
        setupTopStackView()
        setupBottomToolView()
        
        makeConstraints()
    }
    
    var initialLayout = false
    
    func setupData() {        
        viewModel.statusChanged = { [weak self] status in
            self?.cropViewStatusChanged(status)
        }
        
        maximumRectKeyValueObservation = viewModel.observe(\.maximumGuideViewRect, options: [.new]) { [weak self] (_, change) in
            if let rect = change.newValue {
                self?.guideView.maximumRect = rect
            }
        }
    }
    
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
        
        cropView.scrollViewTouchesBegan = { [weak self] in
            self?.viewModel.status = .touchImage
        }
        
        cropView.scrollViewTouchesCancelled = { [weak self] in
            self?.viewModel.status = .endTouch
        }
        
        cropView.scrollViewTouchesEnd = { [weak self] in
            self?.viewModel.status = .endTouch
        }
        
        cropView.scrollViewWillBeginDragging = { [weak self] in
            self?.viewModel.status = .touchImage
        }
        
        cropView.scrollViewDidEndDragging = { [weak self] in
            self?.viewModel.status = .endTouch
        }
        
        cropView.scrollViewDidEndDecelerating = { [weak self] in
            self?.viewModel.status = .endTouch
        }
    }
    
    func setupGuideView() {
        view.addSubview(guideView)
        
        guideView.resizeBegan = { [weak self] handle in
            self?.viewModel.status = .touchHandle(handle)
        }
        
        guideView.resizeEnded = { [weak self] scaledFrame in
            guard let self = self else { return }
            self.animateGuideViewAfterResizing(scaledFrame)
        }
        
        guideView.resizeCancelled = { [weak self] in
            self?.viewModel.status = .endTouch
        }
    }
    
    func setupBlurredManager() {
        maskManager.reset()
        maskManager.showIn(view)
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
            // set guideView from
            let contentBounds = viewModel.getContentBounds(cropView.bounds, CropView.Constant.padding)
            let guideFrameInCropView = viewModel.getInitialCropGuideViewRect(fromOutside: contentBounds)
            //  initialGuideFrame is related to CropView, should convert to it's subview before setted to guideView
            let converted = cropView.convert(guideFrameInCropView, to: view)
            viewModel.resetInitFrame(converted)
            guideView.frame = converted
            cropView.updateSubViews(guideFrameInCropView)
        }
        if !isGuideViewZoommingOut {
            updateMaskTransparent(guideView.frame, animated: false)
        }        
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        print(#function)
        hanleRotate()
    }
    
    // MARK: - Rotation
    
    func hanleRotate() {
//        if UIDevice.current.userInterfaceIdiom == .phone && orientation == .portraitUpsideDown {
//            return
//        }
        // When it is embedded in a container, the timing of viewDidLayoutSubviews
        // is different with the normal mode.
        // So delay the execution to make sure handleRotate runs after the final
        // viewDidLayoutSubviews
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.cropView.handleDeviceRotate(self.guideView.frame)
        }
    }
    
    /// counterclock rotate image view with degree radian value
    /// - Parameter radians: radian value
    /// - Parameter guideViewFrame: guide view frame
    func updateCropViewRotation(_ radians: Double, _ guideViewFrame: CGRect) {
        viewModel.status = .imageRotation
        var rect = guideViewFrame
        rect.size.width = guideView.frame.height
        rect.size.height = guideView.frame.width
        
        let contentBounds = viewModel.getContentBounds(cropView.bounds, CropView.Constant.padding)
        let newRect = GeometryHelper.getAppropriateRect(fromOutside: contentBounds, inside: rect)
        
        let initGuideFrameInCropView = viewModel.getInitialCropGuideViewRect(fromOutside: contentBounds)
        let convertedInitFrame = cropView.convert(initGuideFrameInCropView, to: view)
        viewModel.resetInitFrame(convertedInitFrame)
                        
        UIView.animate(withDuration: 0.25) {
            let convertedGuideFrame = self.cropView.convert(newRect, to: self.view)
            self.guideView.frame = convertedGuideFrame
            
            var size = newRect.size
            if self.viewModel.rotationDegree == .counterclockwise90 || self.viewModel.rotationDegree == .counterclockwise270 {
                size = CGSize(width: newRect.height, height: newRect.width)
            }
            self.cropView.updateSubviewsRotation(radians, size)
        } completion: { _ in
            self.cropView.completeRotation()
            self.viewModel.status = .endTouch
        }
    }
    
    func cropViewStatusChanged(_ status: CropViewStatus) {
        switch status {
        case .initial:
            
            maskManager.showVisualEffectBackground()
        case .touchImage:            
            maskManager.showDimmingBackground()
            // TODO: 😴zZ
        case .touchHandle(_):
            updateGuideViewMaximumRect()
            maskManager.showDimmingBackground()
        // TODO: 😴zZ
        case .imageRotation:
//            blurredManager.showVisualEffectBackground()
        break
        case .endTouch:
            maskManager.showVisualEffectBackground()
        // TODO: 😴zZ

        }
    }
    
    func updateGuideViewMaximumRect() {
        let intersection = self.cropView.imageViewCropViewIntersection()
        let converted = self.cropView.convert(intersection, to: self.view)
        viewModel.maximumGuideViewRect = converted
    }
    
    // MARK: - GuideView resized
    func guideViewResized(_ scaleFrame: CGRect) {
        viewModel.status = .endTouch
        
        // calculate the zoom area of scroll view
        var scaleFrame = scaleFrame
        if scaleFrame.width >= cropView.scrollView.contentSize.width {
            scaleFrame.size.width = cropView.scrollView.contentSize.width
        }
        if scaleFrame.height >= cropView.scrollView.contentSize.height {
            scaleFrame.size.height = cropView.scrollView.contentSize.height
        }
        
        self.cropView.scrollView.update(with: guideView.frame.size)
        
        let convertedFrame = self.view.convert(scaleFrame, to: self.cropView.imageView)
        
        self.cropView.scrollView.zoom(to: convertedFrame, animated: false)
    }
    
    fileprivate func animateGuideViewAfterResizing(_ scaledFrame: CGRect) {
        let guideViewFrame = GeometryHelper.getAppropriateRect(fromOutside: self.viewModel.initialFrame, inside: scaledFrame)
        
        isGuideViewZoommingOut = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            self.updateMaskTransparent(guideViewFrame, animated: true)
        }
        
        guideViewResizeAnimator?.stopAnimation(true)
        let animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeInOut) {
            self.guideView.frame = guideViewFrame
            self.guideViewResized(scaledFrame)
        }
        self.guideViewResizeAnimator = animator
        
        animator.startAnimation(afterDelay: 1)
        animator.addCompletion { position in
            switch position {
            case .start:
                print("animation starting: guideView: \(self.guideView)")
            case .end:
                self.isGuideViewZoommingOut = false
            default: break
            }
        }
    }
    
    @objc func rotatePhotoBy90DegreeClicked(_ sender: UIButton) {
        viewModel.rotationDegree.counterclockwiseRotate90Degree()
        updateCropViewRotation(-Double.pi/2, guideView.frame)
    }
    
    func updateMaskTransparent(_ rect: CGRect, animated: Bool) {
        let convertedInsideRect = self.view.convert(rect, to: self.view)
        self.maskManager.recreateTransparentRect(convertedInsideRect, animated: animated)
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
