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
    
    var statusChanged: ((CropViewStatus) -> Void)?
    
    var scrollViewTouchesBegan = {}
    var scrollViewTouchesCancelled = {}
    var scrollViewTouchesEnd = {}
    var scrollViewWillBeginDragging = {}
    var scrollViewDidEndDragging = {}
    var scrollViewDidEndDecelerating = {}
    
    let imageView: ImageView
    
    lazy var scrollView = CropScrollView(frame: bounds)
    
    private var guideViewHasFrame = false
        
    
    init(image: UIImage) {
        self.imageView = ImageView(image: image)
        super.init(frame: .zero)
    
        clipsToBounds = false
        addSubview(scrollView)
        scrollView.addSubview(imageView)
        
        setupUI()
    }
    
    func updateSubViews(_ guideViewFrame: CGRect ) {
        resetSubviewsFrame(guideViewFrame)
    }
    
    func resetSubviewsFrame(_ guideViewFrame: CGRect) {
        updateViewFrame(guideViewFrame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        setupScrollView()
    }
    

    func setupScrollView() {
        scrollView.delegate = self
        scrollView.touchesBegan = { [weak self] in
            self?.scrollViewTouchesBegan()
//            self?.viewModel.status = .touchImage
        }
        
        scrollView.touchesCancelled = { [weak self] in
            self?.scrollViewTouchesCancelled()
//            self?.viewModel.status = .endTouch
        }
        
        scrollView.touchesEnd = { [weak self] in
            self?.scrollViewTouchesEnd()
//            self?.viewModel.status = .endTouch
        }
    }
        
    func updateSubviewsRotation(_ radians: Double, _ size: CGSize) {
        let transform = scrollView.transform.rotated(by: CGFloat(radians))
        self.scrollView.transform = transform
        self.updateScrollViewBy90DegreeRotation(size)
    }
    
    func completeRotation() {
        self.scrollView.updateMinimumScacle(withImageViewSize: self.imageView.frame.size)
    }
    
    func updateScrollViewBy90DegreeRotation(_ size: CGSize) {
        let scale = computeScrollViewScale(size)
        scrollView.update(with: size)
        let newScale = scrollView.zoomScale * scale
        scrollView.minimumZoomScale = newScale
        scrollView.zoomScale = newScale
        
        
        scrollView.checkContentOffset()
    }
    
    func computeScrollViewScale(_ size: CGSize) -> CGFloat {
        return size.width / scrollView.bounds.width
    }
    
    func updateScrollView(with convertedFrame: CGRect) {
        self.scrollView.zoom(to: convertedFrame, animated: false)
    }
    
    fileprivate func updateViewFrame(_ guideViewFrame: CGRect) {
        
        scrollView.transform = .identity
        scrollView.reset(guideViewFrame)
        
        imageView.frame = scrollView.bounds
        imageView.center = CGPoint(x: scrollView.bounds.width/2, y: scrollView.bounds.height/2)
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()        
    }
    
}

extension CropView {
    func handleDeviceRotate(_ guideViewFrame: CGRect) {
        updateViewFrame(guideViewFrame)
    }
    
}
