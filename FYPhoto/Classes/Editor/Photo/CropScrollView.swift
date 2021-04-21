//
//  CropScrollView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/20.
//

import UIKit

class CropScrollView: UIScrollView {

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
//        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
