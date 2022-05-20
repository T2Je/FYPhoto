//
//  PhotoEditorCropViewController.swift
//  FYPhoto_Example
//
//  Created by xiaoyang on 2021/4/16.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import Foundation

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

    private let cancelButton = UIButton()
    private let doneButton = UIButton()
    private let bottomStackView = UIStackView()

    private let maskManager = CropViewMaskManager()

    private var isGuideViewZoomingOut = false
    private var guideViewResizeAnimator: UIViewPropertyAnimator?

    private var maximumRectKeyValueObservation: NSKeyValueObservation?

    private var timer: Timer?

    var orientation: UIInterfaceOrientation {
        get {
            if #available(iOS 13, macOS 10.13, *) {
                return (UIApplication.shared.windows.first?.windowScene?.interfaceOrientation)!
            } else {
                return UIApplication.shared.statusBarOrientation
            }
        }
    }

    var initialLayout = false
    var customLayouts: [NSLayoutConstraint] = []

    let customRatio: [RatioItem]

    /// If the image is cropped before, use this data to re-create the situation of cropping the image
    public var restoreData: CroppedRestoreData?
    private var zoomRect: CGRect?
    private var imageContentOffset: CGPoint?

    // MARK: - Lifecycle
    /// Initialize CropImageViewController with image and custom ratios
    /// - Parameters:
    ///   - image: source image
    ///   - customRatio: customRatio, for example: you want a '1000:3' ratio, which is not included in built-in ratios
    ///   - restoreData: If the image is cropped before, use this data to re-create the situation of cropping the image
    public init(image: UIImage, customRatio: [RatioItem] = [], restoreData: CroppedRestoreData? = nil) {
        self.restoreData = restoreData
        viewModel = CropViewModel(image: image)
        cropView = CropView(image: image)
        if let previous = restoreData {
            viewModel.setInitialZoomScale(previous.initialZoomScale, at: previous.rotation)
            viewModel.setInitialFrame(previous.initialFrame, at: previous.rotation)

        } else {
            viewModel.setInitialZoomScale(cropView.scrollView.zoomScale, at: .zero)
        }

        self.customRatio = customRatio

        super.init(nibName: nil, bundle: nil)
    }

    public convenience init(image: UIImage) {
        self.init(image: image, customRatio: [], restoreData: nil)
    }

    public convenience init(restoreData: CroppedRestoreData) {
        self.init(image: restoreData.originImage, customRatio: [], restoreData: restoreData)
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

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !initialLayout {
            guideView.translatesAutoresizingMaskIntoConstraints = true
            initialLayout = true

            let guideViewFrame = calculateGuideViewInitialFrame()
            viewModel.resetInitialFrameAtCurrentRotation(guideViewFrame)
            guideView.frame = guideViewFrame
            let guideFrameInCropView = view.convert(guideViewFrame, to: cropView)
            cropView.updateSubViews(guideFrameInCropView, currRotation: viewModel.rotation)

            if let previousData = restoreData {
                restoreWithPreviousData(previousData)
            }

        }
        if !isGuideViewZoomingOut {
            updateMaskTransparent(guideView.frame, animated: false)
        }
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        hanleRotate()
    }

    func restoreWithPreviousData(_ data: CroppedRestoreData) {
        if data.rotation != .zero {
            updateCropViewRotation(data.rotation.radians, data.cropFrame, animated: false) { rect in
                self.viewModel.rotation.counterclockwiseRotate90Degree()
                self.viewModel.resetInitFrame(rect,
                                              imageZoomScale: self.cropView.scrollView.zoomScale,
                                              at: self.viewModel.rotation)

                self.viewModel.status = .endTouch
                self.cropView.completeRotation()
            }
        }

        if let zoomRect = data.zoomRect {
            guideView.frame = data.cropFrame
            updateCropViewBounds()
            cropView.scrollView.zoom(to: zoomRect, animated: false)
        }

        cropView.scrollView.setZoomScale(data.zoomScale, animated: true)
        if let contentOffset = data.contentOffset {
            cropView.scrollView.contentOffset = contentOffset
        }
    }

    func saveRestoreData(_ edited: UIImage) {
        let tempZoomRect = zoomRect ?? restoreData?.zoomRect
        let tempContentOffset = imageContentOffset ?? restoreData?.contentOffset
        restoreData = CroppedRestoreData(initialFrame: viewModel.initialFrame,
                                         initialZoomScale: viewModel.initalZoomScale,
                                         cropFrame: guideView.frame,
                                         zoomScale: cropView.scrollView.zoomScale,
                                         zoomRect: tempZoomRect,
                                         contentOffset: tempContentOffset,
                                         rotation: viewModel.rotation,
                                         originImage: viewModel.image,
                                         editedImage: edited)
    }

    // MARK: - Setup
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
        resetButton.alpha = 0

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

        cropView.scrollViewDidZoom = { [weak self] in
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
            self.startTimer(scaledFrame)
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
        viewModel.resetInitFrame(initialGuideFrame, imageZoomScale: cropView.scrollView.zoomScale, at: self.viewModel.rotation)
        guideView.frame = initialGuideFrame
        let guideViewFrameInCropView = view.convert(initialGuideFrame, to: cropView)
        cropView.handleDeviceRotate(guideViewFrameInCropView, currRotation: viewModel.rotation)
        maskManager.rotateMask(initialGuideFrame)
    }

    /// Rotate image counterclockwise at a degree
    /// - Parameter radians: degree radian value
    /// - Parameter guideViewFrame: current guide view frame
    func updateCropViewRotation(_ radians: CGFloat,
                                _ guideViewFrame: CGRect,
                                animated: Bool = true,
                                completion: @escaping ((CGRect) -> Void)) {
        viewModel.status = .imageRotation
        var rect = guideViewFrame
        rect.size.width = guideView.frame.height
        rect.size.height = guideView.frame.width

        let contentBounds = viewModel.getContentBounds(cropView.bounds, CropView.Constant.padding)
        let newRect = GeometryHelper.getAppropriateRect(fromOutside: contentBounds, inside: rect)
        let convertedGuideFrame = cropView.convert(newRect, to: self.view)
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.guideView.frame = convertedGuideFrame
                self.cropView.updateSubviewsRotation(radians, dstGuideViewSize: convertedGuideFrame.size, currRotation: self.viewModel.rotation)
            } completion: { _ in
                completion(convertedGuideFrame)
            }
        } else {
            self.guideView.frame = convertedGuideFrame
            self.cropView.updateSubviewsRotation(radians, dstGuideViewSize: convertedGuideFrame.size, currRotation: self.viewModel.rotation)
            completion(convertedGuideFrame)
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
            imageContentOffset = cropView.scrollView.contentOffset
            if viewModel.canReset(guideView.frame, cropView.scrollView.zoomScale) {
                resetButton.alpha = 1
            } else {
                resetButton.alpha = 0
            }
        }
    }

    func updateGuideViewMaximumRect() {
        let intersection = self.cropView.imageViewCropViewIntersection()
        let converted = self.cropView.convert(intersection, to: self.view)
        viewModel.maximumGuideViewRect = converted
    }

    // MARK: - GuideView resized
    fileprivate func updateCropViewBounds() {
        var rotationSize = guideView.frame.size
        if viewModel.rotation == .counterclockwise90 || viewModel.rotation == .counterclockwise270 {
            rotationSize = CGSize(width: rotationSize.height, height: rotationSize.width)
        }
        cropView.scrollView.updateBounds(with: rotationSize)
    }

    func calculateZoomRect(_ scaleFrame: CGRect) -> CGRect {
        // calculate the zoom area of scroll view
        var scaleFrame = scaleFrame

        if scaleFrame.width > cropView.scrollView.contentSize.width {
            scaleFrame.size.width = cropView.scrollView.contentSize.width
        }
        if scaleFrame.height > cropView.scrollView.contentSize.height {
            scaleFrame.size.height = cropView.scrollView.contentSize.height
        }

        return self.view.convert(scaleFrame, to: self.cropView.imageView)
    }

    func guideViewResized(_ scaleFrame: CGRect) {
        viewModel.status = .endTouch

        updateCropViewBounds()
        let zoomRect = calculateZoomRect(scaleFrame)
        cropView.scrollView.zoom(to: zoomRect, animated: false)

        self.zoomRect = zoomRect
    }

    fileprivate func animateGuideViewAfterResizing(_ scaledFrame: CGRect, animated: Bool) {
        let contentBounds = viewModel.getContentBounds(cropView.bounds, CropView.Constant.padding)
        var guideViewFrame = GeometryHelper.getAppropriateRect(fromOutside: contentBounds, inside: scaledFrame)
        guideViewFrame = cropView.convert(guideViewFrame, to: view)

        isGuideViewZoomingOut = true
        updateMaskTransparent(guideViewFrame, animated: true)

        guideViewResizeAnimator?.stopAnimation(true)
        let duration: TimeInterval = animated ? 0.2 : 0
        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
            self.guideView.frame = guideViewFrame
            self.guideViewResized(scaledFrame)
        }
        self.guideViewResizeAnimator = animator

        animator.startAnimation()
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
        updateCropViewRotation(-CGFloat.pi/2, guideView.frame) { guideViewFrame in
            self.viewModel.rotation.counterclockwiseRotate90Degree()
            self.viewModel.resetInitFrame(guideViewFrame,
                                          imageZoomScale: self.cropView.scrollView.zoomScale,
                                          at: self.viewModel.rotation)

            self.viewModel.status = .endTouch
            self.cropView.completeRotation()
        }

    }

    func updateMaskTransparent(_ rect: CGRect, animated: Bool) {
        self.maskManager.recreateTransparentRect(rect, animated: animated)
    }

    func startTimer(_ rect: CGRect) {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { _ in
            self.stopTimer()
            self.animateGuideViewAfterResizing(rect, animated: true)
        })
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: Crop ratio changed
    func updateCropRatio(_ ratio: Double?) {
        viewModel.setFixedAspectRatio(ratio)

        let initialFrame = calculateGuideViewInitialFrame()
        viewModel.resetInitialFrameAtCurrentRotation(initialFrame)
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

        resetButton.alpha = 0
    }

    @objc func aspectRatioButtonClicked(_ sender: UIButton) {
        aspectRatioBar.isHidden = !aspectRatioBar.isHidden
    }

    @objc func cancelButtonClicked(_ sender: UIButton) {
        if viewModel.hasChanges(guideView.frame, cropView.scrollView.zoomScale) {
            discardChangesWarning(sender)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    func discardChangesWarning(_ sender: UIView) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let discard = UIAlertAction(title: L10n.discardChanges, style: .destructive) { _ in
            self.dismiss(animated: true, completion: nil)
        }
        let cancel = UIAlertAction(title: L10n.cancel, style: .cancel, handler: nil)
        alertController.addAction(discard)
        alertController.addAction(cancel)
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            if let popoverController = alertController.popoverPresentationController {
                popoverController.sourceView = sender
                popoverController.sourceRect = sender.bounds
            }
        }
        present(alertController, animated: true, completion: nil)
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
            self.saveRestoreData(image)
        } else {
            result = .failure(CropImageError.invalidImage)
        }
        self.dismiss(animated: true) {

            self.croppedImage?(result)
        }
    }
}
