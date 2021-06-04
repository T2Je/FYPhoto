//
//  PhotoEditorCropViewController.swift
//  FYPhoto_Example
//
//  Created by xiaoyang on 2021/4/16.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

typealias CropInfo = (translation: CGPoint, rotation: CGFloat, scale: CGFloat, cropSize: CGSize, imageViewSize: CGSize)

public class CropImageViewController: UIViewController {
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
        let bar = AspectRatioBar(items: ratioBarItems, isPortrait: orientation == .portrait || orientation == .portraitUpsideDown)
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
        
        maximumRectKeyValueObservation = viewModel.observe(\.maximumGuideViewRect,
                                                           options: [.new]) { [weak self] (_, change) in
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
        
        layoutCropViewAndRatioBar(orientation == .portrait || orientation == .portraitUpsideDown)
    }
    
    var customLayouts: [NSLayoutConstraint] = []
        
    func layoutCropViewAndRatioBar(_ isPortrait: Bool) {
        let safeArea = view.safeAreaLayoutGuide
        cropView.translatesAutoresizingMaskIntoConstraints = false
        aspectRatioBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.deactivate(customLayouts)
        customLayouts.removeAll()
        if isPortrait {
            if bottomStackView.superview == nil {
                topStackView.removeFully(view: cancelButton)
                topStackView.removeFully(view: doneButton)
                
                bottomStackView.addArrangedSubview(cancelButton)
                bottomStackView.addArrangedSubview(doneButton)
                view.addSubview(bottomStackView)
            }
            let cropViewContraints = [
                cropView.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: 0),
                cropView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 0),
                cropView.bottomAnchor.constraint(equalTo: aspectRatioBar.topAnchor, constant: 0),
                cropView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: 0)
            ]
            
            NSLayoutConstraint.activate(cropViewContraints)
                        
            bottomStackView.translatesAutoresizingMaskIntoConstraints = false
            
            let bottomStackViewConstraints = [
                bottomStackView.heightAnchor.constraint(equalToConstant: 45),
                bottomStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 10),
                bottomStackView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
                bottomStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -10)
            ]
            NSLayoutConstraint.activate(bottomStackViewConstraints)
            
            let aspectRatioBarConstraints = [
                aspectRatioBar.heightAnchor.constraint(equalToConstant: 45),
                aspectRatioBar.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
                aspectRatioBar.bottomAnchor.constraint(equalTo: bottomStackView.topAnchor),
                aspectRatioBar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor)
            ]
            
            NSLayoutConstraint.activate(aspectRatioBarConstraints)
            
            customLayouts = cropViewContraints + aspectRatioBarConstraints + bottomStackViewConstraints
        } else {
            let cropViewContraints = [
                cropView.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: 0),
                cropView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 0),
                cropView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: 0),
                cropView.trailingAnchor.constraint(equalTo: aspectRatioBar.leadingAnchor, constant: -20)
            ]
            
            NSLayoutConstraint.activate(cropViewContraints)
                      
            let aspectRatioBarConstraints = [
                aspectRatioBar.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: 0),
                aspectRatioBar.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
                aspectRatioBar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: 0),
                aspectRatioBar.widthAnchor.constraint(equalToConstant: 100)
            ]
            NSLayoutConstraint.activate(aspectRatioBarConstraints)
            
            customLayouts = cropViewContraints + aspectRatioBarConstraints
            bottomStackView.removeFromSuperview()
                        
            bottomStackView.removeFullyAllArrangedSubviews()
            topStackView.insertArrangedSubview(cancelButton, at: 0)
            topStackView.addArrangedSubview(doneButton)
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !initialLayout {
            guideView.translatesAutoresizingMaskIntoConstraints = true            
            initialLayout = true
            
            let guideViewFrame = calculateGuideViewInitialFrame()
            viewModel.resetInitFrame(guideViewFrame)
            guideView.frame = guideViewFrame
            let guideFrameInCropView = view.convert(guideViewFrame, to: cropView)
            cropView.updateSubViews(guideFrameInCropView, currRotation: viewModel.rotation)
        }
        if !isGuideViewZoomingOut {
            updateMaskTransparent(guideView.frame, animated: false)
        }        
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        hanleRotate()
        
    }
    
    // MARK: - Rotation
    
    func hanleRotate() {
        if UIDevice.current.userInterfaceIdiom == .phone && orientation == .portraitUpsideDown {
            return
        }
        // When it is embedded in a container, the timing of viewDidLayoutSubviews
        // is different with the normal mode.
        // So delay the execution to make sure handleRotate runs after the final
        // viewDidLayoutSubviews

        let isPortraitPrevious = orientation == .portrait || orientation == .portraitUpsideDown
        aspectRatioBar.flip()
        layoutCropViewAndRatioBar(!isPortraitPrevious)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.deviceRotating()
        }
    }
    
    func deviceRotating() {
        let initialGuideFrame = calculateGuideViewInitialFrame()
        viewModel.resetInitFrame(initialGuideFrame)
        guideView.frame = initialGuideFrame
        let guideViewFrameInCropView = view.convert(initialGuideFrame, to: cropView)
        cropView.handleDeviceRotate(guideViewFrameInCropView, currRotation: viewModel.rotation)
        maskManager.rotateMask(initialGuideFrame)
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
    
    fileprivate func calculateGuideViewInitialFrame() -> CGRect {
        let contentBounds = viewModel.getContentBounds(cropView.bounds, CropView.Constant.padding)
        let initGuideFrameInCropView = viewModel.getInitialCropGuideViewRect(fromOutside: contentBounds)
        //  initialGuideFrame is under CropView, should convert it to viewController's view before being set to guideView
        let convertedInitFrame = cropView.convert(initGuideFrameInCropView, to: view)
        return convertedInitFrame
    }

    @objc func rotatePhotoBy90DegreeClicked(_ sender: UIButton) {
        updateCropViewRotation(-CGFloat.pi/2, guideView.frame) {
            self.viewModel.rotation.counterclockwiseRotate90Degree()
            self.viewModel.resetInitFrame(self.calculateGuideViewInitialFrame())
            
            self.viewModel.status = .endTouch
            self.cropView.completeRotation()
        }
        
    }
    
    func updateMaskTransparent(_ rect: CGRect, animated: Bool) {
        self.maskManager.recreateTransparentRect(rect, animated: animated)
    }
    
    // MARK: Crop ratio changed
    func updateCropRatio(_ ratio: Double?) {
        viewModel.setFixedAspectRatio(ratio)
        
        let initialFrame = calculateGuideViewInitialFrame()
        viewModel.resetInitFrame(initialFrame)
        let guideFrame = viewModel.calculateGuideViewFrame(by: initialFrame)
        guideView.frame = guideFrame
             
        guideView.aspectRatio = ratio
        updateMaskTransparent(guideFrame, animated: false) // viewDidLayoutSubviews doesn't call on iOS 11
    }
    
    // MARK: - Button actions
    
    @objc func resetPhotoButtonClicked(_ sender: UIButton) {
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
        
        let result: Result<UIImage, Error>
        
        let guideViewRectInCropView = view.convert(guideView.frame, to: cropView)
        let cropInfo = cropView.getCropInfo(with: guideViewRectInCropView, radians: viewModel.rotation.radians)
        if let image = imageViewImage.getCroppedImage(byCropInfo: cropInfo) {
            result = .success(image)
        } else {
            result = .failure(CropImageError.invalidImage)
        }
        self.dismiss(animated: true) {
            self.croppedImage?(result)
        }
    }
}
