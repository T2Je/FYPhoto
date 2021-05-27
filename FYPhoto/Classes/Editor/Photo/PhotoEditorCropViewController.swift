//
//  PhotoEditorCropViewController.swift
//  FYPhoto_Example
//
//  Created by xiaoyang on 2021/4/16.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

public class PhotoEditorCropViewController: UIViewController {
    public enum CropImageError: Error, LocalizedError {
        case invalidImage
        
        public var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "invalid image"
            }
        }
    }
    
    public var croppedImage: ((Result<UIImage, Error>) -> Void)?
    
    let viewModel: CropViewModel
    
    let rotateButton = UIButton()
    let resetButton = UIButton()
    let aspectRatioButton = UIButton()
    let topStackView = UIStackView()
    
    let cropView: CropView
    let guideView = InteractiveCropGuideView()
    
    lazy var aspectRatioBar: AspectRatioBar = {
        let ratioBarItems = aspectRatioManager.items.map { AspectRatioButtonItem(title: $0.title, ratio: $0.value) }
        let bar = AspectRatioBar(items: ratioBarItems)
        return bar
    }()
    
    let cancelButton = UIButton()
    let doneButton = UIButton()
    let bottomStackView = UIStackView()
    
    let maskManager = CropViewMaskManager()
    
    private var isGuideViewZoomingOut = false
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
    
    let customRatio: [RatioItem]
    
    public init(image: UIImage, customRatio: [RatioItem] = []) {
        viewModel = CropViewModel(image: image)
        cropView = CropView(image: image)
        self.customRatio = customRatio
        
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
        setupAspectRatioBar()
        
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
        guideView.translatesAutoresizingMaskIntoConstraints = false // fix guideView's subviews constraints warning
        
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
    
    func setupAspectRatioBar() {
        view.addSubview(aspectRatioBar)
        aspectRatioBar.isHidden = true
        aspectRatioBar.didSelectedRatio = { [weak self] ratio in
            guard let self = self else { return }
            self.updateCropRatio(ratio)
        }
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
    
    var aspectRatioManager: RatioManager {
        let original = viewModel.getImageRatio()
        let isHorizontal = viewModel.rotation == .counterclockwise90 || viewModel.rotation == .counterclockwise270
        return RatioManager(ratioOptions: .all, custom: customRatio, original: original, isHorizontal: isHorizontal)
    }
    
    func makeConstraints() {
        topStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            topStackView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            topStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 10),
            topStackView.heightAnchor.constraint(equalToConstant: 45),
            topStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -10)
        ])
        
        cropView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cropView.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: 0),
            cropView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            cropView.bottomAnchor.constraint(equalTo: aspectRatioBar.topAnchor, constant: 0),
            cropView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
        ])
        
        aspectRatioBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            aspectRatioBar.heightAnchor.constraint(equalToConstant: 45),
            aspectRatioBar.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            aspectRatioBar.bottomAnchor.constraint(equalTo: bottomStackView.topAnchor),
            aspectRatioBar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor)
        ])
        
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomStackView.heightAnchor.constraint(equalToConstant: 45),
            bottomStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 10),
            bottomStackView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            bottomStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -10)
        ])
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !initialLayout {
            guideView.translatesAutoresizingMaskIntoConstraints = true            
            initialLayout = true
            
            let contentBounds = viewModel.getContentBounds(cropView.bounds, CropView.Constant.padding)
            let guideFrameInCropView = viewModel.getInitialCropGuideViewRect(fromOutside: contentBounds)
            //  initialGuideFrame is under CropView, should convert it to viewController's view before being set to guideView
            let converted = cropView.convert(guideFrameInCropView, to: view)
            viewModel.resetInitFrame(converted)
            guideView.frame = converted
            cropView.updateSubViews(guideFrameInCropView, currRotation: viewModel.rotation)
        }
        if !isGuideViewZoomingOut {
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
            self.cropView.handleDeviceRotate(self.guideView.frame, currRotation: self.viewModel.rotation)
        }
    }
    
    /// Rotate image counterclockwise at a degree
    /// - Parameter radians: degree radian value
    /// - Parameter guideViewFrame: current guide view frame
    func updateCropViewRotation(_ radians: CGFloat, _ guideViewFrame: CGRect, completion: @escaping (() -> Void)) {
        viewModel.status = .imageRotation
        var rect = guideViewFrame
        rect.size.width = guideView.frame.height
        rect.size.height = guideView.frame.width
        
        let contentBounds = viewModel.getContentBounds(cropView.bounds, CropView.Constant.padding)
        let newRect = GeometryHelper.getAppropriateRect(fromOutside: contentBounds, inside: rect)
        let convertedGuideFrame = cropView.convert(newRect, to: self.view)
        
        let initGuideFrameInCropView = viewModel.getInitialCropGuideViewRect(fromOutside: contentBounds)
        let convertedInitFrame = cropView.convert(initGuideFrameInCropView, to: view)
        viewModel.resetInitFrame(convertedInitFrame)
                        
        UIView.animate(withDuration: 0.25) {
            self.guideView.frame = convertedGuideFrame
            self.cropView.updateSubviewsRotation(radians, dstGuideViewSize: convertedGuideFrame.size, currRotation: self.viewModel.rotation)
        } completion: { _ in
            completion()
        }
    }
    
    func cropViewStatusChanged(_ status: CropViewStatus) {
        switch status {
        case .initial:
            maskManager.showVisualEffectBackground()
        case .touchImage:            
            maskManager.showDimmingBackground()
        case .touchHandle(_):
            cropView.scrollView.isUserInteractionEnabled = false
            updateGuideViewMaximumRect()
            maskManager.showDimmingBackground()
        case .imageRotation:
            break
        case .endTouch:
            maskManager.showVisualEffectBackground()
            cropView.scrollView.isUserInteractionEnabled = true
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
        
        if scaleFrame.width > cropView.scrollView.contentSize.width {
            scaleFrame.size.width = cropView.scrollView.contentSize.width
        }
        if scaleFrame.height > cropView.scrollView.contentSize.height {
            scaleFrame.size.height = cropView.scrollView.contentSize.height
        }
                
        var rotationSize = guideView.frame.size
        if viewModel.rotation == .counterclockwise90 || viewModel.rotation == .counterclockwise270 {
            rotationSize = CGSize(width: guideView.frame.size.height, height: guideView.frame.size.width)
        }
        self.cropView.scrollView.updateBounds(with: rotationSize)

        let convertedFrame = self.view.convert(scaleFrame, to: self.cropView.imageView)
        self.cropView.scrollView.zoom(to: convertedFrame, animated: false)
    }
    
    fileprivate func animateGuideViewAfterResizing(_ scaledFrame: CGRect) {
        let contentBounds = viewModel.getContentBounds(cropView.bounds, CropView.Constant.padding)
        var guideViewFrame = GeometryHelper.getAppropriateRect(fromOutside: contentBounds, inside: scaledFrame)
        guideViewFrame = cropView.convert(guideViewFrame, to: view)
        
        isGuideViewZoomingOut = true
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
                self.cropView.updateScrollViewMinZoomScale()
                self.isGuideViewZoomingOut = false
            default: break
            }
        }
    }
    
    @objc func rotatePhotoBy90DegreeClicked(_ sender: UIButton) {
        updateCropViewRotation(-CGFloat.pi/2, guideView.frame) {
            self.viewModel.rotation.counterclockwiseRotate90Degree()
            self.viewModel.status = .endTouch
            self.cropView.completeRotation()
        }
        
    }
    
    func updateMaskTransparent(_ rect: CGRect, animated: Bool) {
        let convertedInsideRect = self.view.convert(rect, to: self.view)
        self.maskManager.recreateTransparentRect(convertedInsideRect, animated: animated)
    }
    
    func updateCropRatio(_ ratio: Double?) {
        viewModel.setFixedAspectRatio(ratio)
        
        let contentBounds = viewModel.getContentBounds(cropView.bounds, CropView.Constant.padding)
        let initialGuideFrame = viewModel.getInitialCropGuideViewRect(fromOutside: contentBounds)
        let convertedGuideFrame = cropView.convert(initialGuideFrame, to: view)
        let guideFrame = viewModel.calculateCropBoxFrame(by: convertedGuideFrame)
        
        viewModel.resetInitFrame(guideFrame)
        guideView.frame = guideFrame
        
        guideView.aspectRatio = ratio
    }
    
    // MARK: - Button actions
    
    @objc func resetPhotoButtonClicked(_ sender: UIButton) {
        // TODO: bug
        updateCropRatio(nil)
        let ratioBarItems = aspectRatioManager.items.map { AspectRatioButtonItem(title: $0.title, ratio: $0.value) }
        aspectRatioBar.reloadItems(ratioBarItems)
        
        let convertedFrame = self.view.convert(viewModel.initialFrame, to: cropView)
        cropView.resetSubviewsFrame(convertedFrame, currRotation: viewModel.rotation)
                
        guideView.frame = viewModel.initialFrame

    }
    
    @objc func aspectRatioButtonClicked(_ sender: UIButton) {        
        aspectRatioBar.isHidden = !aspectRatioBar.isHidden
    }
    
    @objc func cancelButtonClicked(_ sender: UIButton) {
        if viewModel.rotation != .zero || viewModel.hasResized(guideView.frame) {
            discardChangesWarning()
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func discardChangesWarning() {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let discard = UIAlertAction(title: "DiscardChanges", style: .destructive) { _ in
            self.dismiss(animated: true, completion: nil)
        }
        let cancel = UIAlertAction(title: L10n.cancel, style: .cancel, handler: nil)
        alertVC.addAction(discard)
        alertVC.addAction(cancel)
        
        present(alertVC, animated: true, completion: nil)
    }
    
    @objc func doneButtonClicked(_ sender: UIButton) {
        guard let imageViewImage = cropView.imageView.image else {
            assertionFailure("imageView doesn't contains an image")
            return
        }
        let ratio = imageViewImage.size.height / cropView.scrollView.contentSize.height
        let origin: CGPoint
        let cropImageViewSize = CGSize(width: guideView.bounds.size.width * ratio, height: guideView.bounds.size.height * ratio)
        if viewModel.rotation == .zero || viewModel.rotation == .counterclockwise180 {
            origin = CGPoint(x: cropView.scrollView.contentOffset.x * ratio, y: cropView.scrollView.contentOffset.y * ratio)
        } else {
            origin = CGPoint(x: cropView.scrollView.contentOffset.y * ratio, y: cropView.scrollView.contentOffset.x * ratio)
        }
                
        let cropFrame = CGRect(origin: origin, size: cropImageViewSize)
        
        let result: Result<UIImage, Error>
        if let image = crop(imageViewImage, to: cropFrame, rotation: viewModel.rotation) {
            result = .success(image)
        } else {
            result = .failure(CropImageError.invalidImage)
        }
        self.dismiss(animated: true) {
            self.croppedImage?(result)
        }
    }
    
    func crop(_ image: UIImage, to rect: CGRect, rotation: PhotoRotation) -> UIImage? {
        return image.cropWithFrame2(rect, isCircular: false, radians: CGFloat(rotation.radians))
    }
}
