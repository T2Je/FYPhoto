//
//  CropView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/20.
//

import UIKit

class CropView: UIView {
    
    let viewModel: CropViewModel
    
    var image: UIImage {
        viewModel.image
    }
    
    var imageView: ImageView
    var guideView = InteractiveCropGuideView()
    
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
            //            switch changed.newValue {
            //            case .initial:
            //            case .touchImage:
            //            case .touchHandle(_):
            //            case .endTouch:
            //
            //            }

        }
    }
    
    func updateViews() {
        resetUIFrame()
    }
    
    func resetUIFrame() {
        let initialGuideFrame = viewModel.getInitialCropGuideViewRect(fromOutside: bounds)
        viewModel.resetCropFrame(initialGuideFrame)
                
        scrollView.transform = .identity
        scrollView.reset(initialGuideFrame)
        
        imageView.frame = scrollView.bounds
        imageView.center = CGPoint(x: scrollView.bounds.width/2, y: scrollView.bounds.height/2)

        guideView.frame = initialGuideFrame
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
    
//    var touchesBegan: Bool = false
    
    func setupGuideView() {
        guideView.resizeBegan = { [weak self] handle in
            self?.viewModel.status = .touchHandle(handle)
        }
        
        guideView.resizeEnded = { [weak self] guideViewFrame in
            guard let self = self else { return }
            let convertedFrame = self.convert(guideViewFrame, to: self.imageView)
            
            self.scrollView.zoom(to: convertedFrame, animated: true)
            
            self.guideView.frame = GeometryHelper.getAppropriateRect(fromOutside: self.viewModel.imageFrame, inside: guideViewFrame)
        }
        
        guideView.resizeCancelled = { [weak self] in
            
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
    
    
}

extension CropView: UIScrollViewDelegate {
    // pinches imageView
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
