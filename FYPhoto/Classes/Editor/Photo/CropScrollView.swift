//
//  CropScrollView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/20.
//

import UIKit

class CropScrollView: UIScrollView {

    var touchesBegan = {}
    var touchesCancelled = {}
    var touchesEnd = {}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        alwaysBounceHorizontal = true
        alwaysBounceVertical = true
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        minimumZoomScale = 1.0
        maximumZoomScale = 15.0
        clipsToBounds = false
        contentSize = bounds.size
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func reset(_ rect: CGRect) {
        // Reseting zoom need to be before resetting frame and contentsize
        minimumZoomScale = 1.0
        zoomScale = 1.0

        frame = rect
        contentSize = rect.size
    }
    
    // Update bound size, re-center with old center, then scrollView's frame will be changed.
    func update(with newSize: CGSize) {
        let oldCenter = center
        let oldOffsetCenter = CGPoint(x: contentOffset.x + bounds.width/2, y: contentOffset.y + bounds.height/2)
        
        bounds.size = newSize
        let newOffset = CGPoint(x: oldOffsetCenter.x - newSize.width/2, y: oldOffsetCenter.y - newSize.height/2)
        contentOffset = newOffset
        center = oldCenter
    }
    
    func updateMinimumScacle(withImageViewSize size: CGSize) {
        minimumZoomScale = getBoundZoomScale(size)
    }
    
    private func getBoundZoomScale(_ size: CGSize) -> CGFloat {
        let scaleW = bounds.width / size.width
        let scaleH = bounds.height / size.height
        
        return max(scaleW, scaleH)
    }
    
    func checkContentOffset() {
        contentOffset.x = max(contentOffset.x, 0)
        contentOffset.y = max(contentOffset.y, 0)
        
        if contentSize.height - contentOffset.y <= bounds.size.height {
            contentOffset.y = contentSize.height - bounds.size.height
        }
        
        if contentSize.width - contentOffset.x <= bounds.size.width {
            contentOffset.x = contentSize.width - bounds.size.width
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        touchesBegan()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        touchesCancelled()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        touchesEnd()
    }
}
