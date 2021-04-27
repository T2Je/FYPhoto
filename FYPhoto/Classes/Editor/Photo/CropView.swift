//
//  CropView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/20.
//

import UIKit

class CropView: UIView {
    struct Constant {
        static let padding: CGFloat = 14
    }
    
    let viewModel: CropViewModel
    
    var image: UIImage {
        viewModel.image
    }
    
    let imageView: ImageView
    let guideView = InteractiveCropGuideView()
    let blurredManager = CropViewMaskManager()        
    
    lazy var scrollView = CropScrollView(frame: bounds)
    
    private var guideViewHasFrame = false
    
    private var cropFrameObservation: NSKeyValueObservation?
    
    init(viewModel: CropViewModel) {
        self.viewModel = viewModel
        self.imageView = ImageView(image: viewModel.image)
        super.init(frame: .zero)
    
        clipsToBounds = false
        addSubview(scrollView)
        scrollView.addSubview(imageView)
        addSubview(guideView)
        
        setupUI()
        
        viewModel.statusChanged = { [weak self] status in
            print("status: \(status)")
            self?.cropViewStatusChanged(status)
        }
        
        viewModel.rotationChanged = { [weak self] degree in
            self?.cropViewRotationDegreeChanged(degree)
        }
//        viewModel.aspectRatioChanged = { [weak self] ratio in
//            
//        }
        
        cropFrameObservation = viewModel.observe(\.initialFrame, options: .new) { [unowned self] (_, changed) in
            if let rect = changed.newValue {
                self.guideView.frame = rect
                self.blurredManager.recreateTransparentRect(rect)
            }
        }
    }
    
    func updateViews() {
        resetUIFrame()
    }
    
    func resetUIFrame() {
        blurredManager.reset()
        blurredManager.showIn(self)
        
        updateViewFrame()

        // guide view frame is set in kvo
        guideView.superview?.bringSubviewToFront(guideView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        setupScrollView()
        setupGuideView()
    }
    
    func setupGuideView() {
        guideView.resizeBegan = { [weak self] handle in
            self?.viewModel.status = .touchHandle(handle)
        }
        
        guideView.resizeEnded = { [weak self] guideViewFrame in
            guard let self = self else { return }
            self.guideViewResized(guideViewFrame)
        }
        
        guideView.resizeCancelled = { [weak self] in
            self?.viewModel.status = .endTouch
        }
    }
    
    func setupScrollView() {
        scrollView.delegate = self
        scrollView.touchesBegan = { [weak self] in
            self?.viewModel.status = .touchImage
        }
        
        scrollView.touchesCancelled = { [weak self] in
            self?.viewModel.status = .endTouch
        }
        
        scrollView.touchesEnd = { [weak self] in
            self?.viewModel.status = .endTouch
        }
    }
    
    func cropViewStatusChanged(_ status: CropViewStatus) {
        switch status {
        case .initial:
            setupUI()
        case .touchImage:
            blurredManager.showDimmingBackground()
            // TODO: 😴zZ
        case .touchHandle(_):
            blurredManager.showDimmingBackground()
        // TODO: 😴zZ
        case .imageRotation:
//            blurredManager.showVisualEffectBackground()
        break
        case .endTouch:
            blurredManager.showVisualEffectBackground()
        // TODO: 😴zZ

        }
    }
    
    func cropViewRotationDegreeChanged(_ degree: PhotoRotationDegree) {
//        switch degree {
//        case .zero:
//            <#code#>
//        default:
//            <#code#>
//        }
        updateSubviewsRotation(-Double.pi/2)
    }
        
    func counterclockRotate90Degree() {
        viewModel.rotationDegree.counterclockwiseRotate90Degree()
    }
    
    func updateSubviewsRotation(_ radians: Double) {
        viewModel.status = .imageRotation
        var rect = guideView.frame
        rect.size.width = guideView.frame.height
        rect.size.height = guideView.frame.width
        
        let contentBounds = viewModel.getContentBounds(bounds, Constant.padding)
        let newRect = GeometryHelper.getAppropriateRect(fromOutside: contentBounds, inside: rect)
        
//        let initialGuideFrame = viewModel.getInitialCropGuideViewRect(fromOutside: contentBounds)
        
        let initialGuideFrame = viewModel.getInitialCropGuideViewRect(fromOutside: contentBounds)
        viewModel.resetCropFrame(initialGuideFrame)
        
        
        let transform = scrollView.transform.rotated(by: CGFloat(radians))
        UIView.animate(withDuration: 0.25) {
            self.scrollView.transform = transform
//            self.viewModel.resetCropFrame(newRect)
            
            self.guideView.frame = newRect
            self.updateScrollViewBy90DegreeRotation(newRect.size)
        } completion: { _ in
            self.scrollView.updateMinimumScacle(withImageViewSize: self.imageView.frame.size)
            self.viewModel.status = .endTouch
        }
    }
    
    func updateScrollViewBy90DegreeRotation(_ guideViewSize: CGSize) {
        var size = guideViewSize
        if viewModel.rotationDegree == .zero || viewModel.rotationDegree == .counterclockwise180 {
//            size = CGSize(width: guideViewSize.height, height: guideViewSize.width)
        } else {
            size = CGSize(width: guideViewSize.height, height: guideViewSize.width)
        }
        scrollView.update(with: size)
        
        let scale = size.width / scrollView.frame.width
        let newScale = scrollView.minimumZoomScale * scale
        scrollView.minimumZoomScale = newScale
        scrollView.zoomScale = newScale

//        scrollView.checkContentOffset()
    }
    
    func guideViewResized(_ guideViewFrame: CGRect) {
        viewModel.status = .endTouch
        let scaleX: CGFloat
        let scaleY: CGFloat
        let contentBounds = viewModel.getContentBounds(bounds, Constant.padding)
        scaleX = contentBounds.width / guideViewFrame.size.width
        scaleY = contentBounds.height / guideViewFrame.size.height
        
        let scale = min(scaleX, scaleY)
        
        let newCropBounds = CGRect(x: 0, y: 0, width: guideViewFrame.width * scale, height: guideViewFrame.height * scale)
        
        // calculate the zoom area of scroll view
        var scaleFrame = guideViewFrame
        if scaleFrame.width >= scrollView.contentSize.width {
            scaleFrame.size.width = scrollView.contentSize.width
        }
        if scaleFrame.height >= scrollView.contentSize.height {
            scaleFrame.size.height = scrollView.contentSize.height
        }
        
        self.scrollView.update(with: newCropBounds.size)
        
        let convertedFrame = self.convert(scaleFrame, to: self.imageView)
        
        self.scrollView.zoom(to: convertedFrame, animated: false)
        self.guideView.frame = GeometryHelper.getAppropriateRect(fromOutside: self.viewModel.initialFrame, inside: guideViewFrame)
    }
    
    fileprivate func updateViewFrame() {
        let contentBounds = viewModel.getContentBounds(bounds, Constant.padding)
        let initialGuideFrame = viewModel.getInitialCropGuideViewRect(fromOutside: contentBounds)
        viewModel.resetCropFrame(initialGuideFrame)
        
        scrollView.transform = .identity
        scrollView.reset(initialGuideFrame)
        
        imageView.frame = scrollView.bounds
        imageView.center = CGPoint(x: scrollView.bounds.width/2, y: scrollView.bounds.height/2)
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        blurredManager.createTransparentRect(with: guideView.frame)
    }
    
}

extension CropView {
    func handleDeviceRotate() {
        updateViewFrame()
    }
}
