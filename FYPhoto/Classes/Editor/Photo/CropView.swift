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
        
    var scrollViewTouchesBegan = {}
    var scrollViewTouchesCancelled = {}
    var scrollViewTouchesEnd = {}
    var scrollViewWillBeginDragging = {}
    var scrollViewDidEndDragging = {}
    var scrollViewDidEndDecelerating = {}
    
    let imageView: ImageView
    
    lazy var scrollView = CropScrollView(frame: bounds)
            
    init(image: UIImage) {
        self.imageView = ImageView(image: image)
        super.init(frame: .zero)
    
        clipsToBounds = false
        addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.imageContainer = imageView
        
        setupUI()
    }
    
    func updateSubViews(_ frame: CGRect, degree: CGFloat) {
        resetSubviewsFrame(frame, degree: degree)
    }
    
    func resetSubviewsFrame(_ frame: CGRect, degree: CGFloat) {
        resetScrollView(frame, degree)
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
        }
        
        scrollView.touchesCancelled = { [weak self] in
            self?.scrollViewTouchesCancelled()
        }
        
        scrollView.touchesEnd = { [weak self] in
            self?.scrollViewTouchesEnd()
        }
    }
        
    func updateSubviewsRotation(_ radians: CGFloat, dstGuideViewSize: CGSize, currRotation: PhotoRotationDegree) {
        let width = abs(cos(radians)) * dstGuideViewSize.width + abs(sin(radians)) * dstGuideViewSize.height
        let height = abs(sin(radians)) * dstGuideViewSize.width + abs(cos(radians)) * dstGuideViewSize.height
        
        let dstSize: CGSize
        
        if currRotation == .zero || currRotation == .counterclockwise180 {
            dstSize = CGSize(width: width, height: height)
        } else {
            dstSize = CGSize(width: height, height: width)
        }
        
        let transform = scrollView.transform.rotated(by: radians)
        self.scrollView.transform = transform
        self.updateScrollViewRotation(dstSize)
    }
    
    func completeRotation() {
        self.scrollView.updateMinimumScacle()
    }
    
    func updateScrollViewRotation(_ size: CGSize) {
        let scale = computeScrollViewScale(size)
        scrollView.updateBounds(with: size)
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
    
    fileprivate func resetScrollView(_ frame: CGRect, _ degree: CGFloat) {
        let transform = CGAffineTransform.identity.rotated(by: degree)
        scrollView.transform = transform
        scrollView.reset(frame)
        
        imageView.frame = scrollView.bounds
        imageView.center = CGPoint(x: scrollView.bounds.width/2, y: scrollView.bounds.height/2)
    }
    
    func updateScrollViewMinZoomScale() {
        scrollView.updateMinimumScacle()
    }
    
}

extension CropView {
    func handleDeviceRotate(_ guideViewFrame: CGRect, degree: CGFloat) {
        resetScrollView(guideViewFrame, degree)
    }
    
    func imageViewCropViewIntersection() -> CGRect {
        self.imageView
            .convert(imageView.bounds, to: self)
            .intersection(bounds.inset(by: UIEdgeInsets(top: Constant.padding,
                                                       left: Constant.padding,
                                                       bottom: Constant.padding,
                                                       right: Constant.padding)))
    }
}
