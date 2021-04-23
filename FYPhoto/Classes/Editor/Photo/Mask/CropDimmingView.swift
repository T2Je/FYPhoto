//
//  CropDimmingView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/22.
//

import UIKit

class CropDimmingView: UIView, CropMaskProtocol {
    var transparentLayer: CALayer?
    
    func setMask(_ insideRect: CGRect) {
        transparentLayer?.removeFromSuperlayer()
        transparentLayer = nil        
        let layer = createTransparentRect(withOutside: bounds, insideRect: insideRect, opacity: 0.5)
        self.layer.addSublayer(layer)
        transparentLayer = layer
    }

}
