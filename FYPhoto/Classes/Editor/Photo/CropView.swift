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
//    private var cropFrameKVO: NSKeyValueObservation?
    
    init(viewModel: CropViewModel) {
        self.viewModel = viewModel
        self.imageView = ImageView(image: viewModel.image)
        super.init(frame: .zero)
        
//        cropFrameKVO = viewModel.observe(\.cropViewFrame, options: [.new, .old], changeHandler: { (_ , value) in
//
//        })
        clipsToBounds = false
        addSubview(scrollView)
        scrollView.addSubview(imageView)
        addSubview(guideView)
        setupUI()
        makeConstraints()
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
//        gridOverlayView.superview?.bringSubviewToFront(gridOverlayView)
    }
    
    func makeConstraints() {
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            scrollView.topAnchor.constraint(equalTo: topAnchor),
//            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor)
//        ])
                
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: scrollView.leadingAnchor, constant: 30),
//            imageView.trailingAnchor.constraint(lessThanOrEqualTo: scrollView.trailingAnchor, constant: -30),
//            imageView.topAnchor.constraint(greaterThanOrEqualTo: scrollView.topAnchor, constant: 30),
//            imageView.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.bottomAnchor, constant: -30)
//
////            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: scrollView.leadingAnchor, constant: 30),
////            imageView.trailingAnchor.constraint(lessThanOrEqualTo: scrollView.trailingAnchor, constant: -30),
////            imageView.topAnchor.constraint(greaterThanOrEqualTo: scrollView.topAnchor, constant: 30),
////            imageView.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.bottomAnchor, constant: -30)
//        ])
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
//        imageView.frame = viewModel.getInitialCropGuideViewRect(fromOutside: self.bounds)
//
////        print("imageView: \(imageView)")
//        if !guideViewHasFrame && (imageView.frame.width < frame.width && imageView.frame.height < frame.height) {
//            print("imageView: \(imageView)")
//            let convertedFrame = imageView.convert(imageView.bounds, to: self)
//            guideView.frame = convertedFrame
//            viewModel.imageFrame = convertedFrame
//            scrollView.contentSize = frame.size
//            guideViewHasFrame = true
//        }
        
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
        guideView.resizeBegan = { [weak self] in
//            self?.touchesBegan = true
        }
        
        guideView.resizeEnded = { [weak self] guideViewFrame in
            guard let self = self else { return }
            var convertedFrame = self.convert(guideViewFrame, to: self.imageView)
            
            self.scrollView.zoom(to: convertedFrame, animated: true)
            
            self.guideView.frame = GeometryHelper.getAppropriateRect(fromOutside: self.viewModel.imageFrame, inside: guideViewFrame)
//            self?.touchesBegan = false
        }
        
        guideView.resizeCancelled = { [weak self] in
            
//            self?.touchesBegan = false
        }
    }
    
    func setupScrollView() {
        scrollView.delegate = self
    }
    
    
}

extension CropView: UIScrollViewDelegate {
    // pinches imageView
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
