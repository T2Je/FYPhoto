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
    
//    private var cropFrameKVO: NSKeyValueObservation?
    
    init(viewModel: CropViewModel) {
        self.viewModel = viewModel
        self.imageView = ImageView(image: viewModel.image)
        super.init(frame: .zero)
        
//        cropFrameKVO = viewModel.observe(\.cropViewFrame, options: [.new, .old], changeHandler: { (_ , value) in
//
//        })
        
        addSubview(scrollView)
        scrollView.addSubview(imageView)
        addSubview(guideView)
        setupUI()
        makeConstraints()
    }
    
    func makeConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: scrollView.leadingAnchor, constant: 30),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: scrollView.trailingAnchor, constant: -30),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: scrollView.topAnchor, constant: 30),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.bottomAnchor, constant: -30)
        ])
        
        
    }
    
    var guideViewHasFrame = false
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
//        print("imageView: \(imageView)")
        if !guideViewHasFrame && (imageView.frame.width < frame.width && imageView.frame.height < frame.height) {
            
            let convertedFrame = imageView.convert(imageView.bounds, to: self)
            guideView.frame = convertedFrame
            viewModel.imageFrame = convertedFrame
            guideViewHasFrame = true
        }        
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        setupGuideView()
    }
    
    func setupImageView() {
        
    }
    
    var touchesBegan: Bool = false
    
    func setupGuideView() {
        guideView.touchesBegan = { [weak self] in
            self?.touchesBegan = true
        }
        
        guideView.touchesEnded = { [weak self] in
            self?.touchesBegan = false
        }
        
        guideView.touchesCancelled = { [weak self] in
            self?.touchesBegan = false
        }
    }
    
    func setupScrollView() {
        
    }
}
