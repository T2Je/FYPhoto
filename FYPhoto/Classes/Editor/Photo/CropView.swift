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
    }
    
    func updateViews() {
        resetUIFrame()
    }
    
    func resetUIFrame() {
        blurredManager.reset()
        blurredManager.showIn(self)
        
        let contentBounds = viewModel.getContentBounds(bounds, Constant.padding)
        let initialGuideFrame = viewModel.getInitialCropGuideViewRect(fromOutside: contentBounds)
        viewModel.resetCropFrame(initialGuideFrame)
                
        scrollView.transform = .identity
        scrollView.reset(initialGuideFrame)
        
        imageView.frame = scrollView.bounds
        imageView.center = CGPoint(x: scrollView.bounds.width/2, y: scrollView.bounds.height/2)

        guideView.frame = initialGuideFrame
        guideView.superview?.bringSubviewToFront(guideView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        setupScrollView()
        setupGuideView()
    }
    
    func setupImageView() {
        
    }
    
    func setupGuideView() {
        guideView.resizeBegan = { [weak self] handle in
            self?.viewModel.status = .touchHandle(handle)
        }
        
        guideView.resizeEnded = { [weak self] guideViewFrame in
            guard let self = self else { return }
            self.viewModel.status = .endTouch
            
            let convertedFrame = self.convert(guideViewFrame, to: self.imageView)
            self.scrollView.zoom(to: convertedFrame, animated: true)
            self.guideView.frame = GeometryHelper.getAppropriateRect(fromOutside: self.viewModel.imageFrame, inside: guideViewFrame)
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
        case .endTouch:
            blurredManager.showVisualEffectBackground()
        // TODO: 😴zZ

        }
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        blurredManager.createTransparentRect(with: guideView.frame)
    }
    
    
}
