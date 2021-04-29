//
//  CropDimmingView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/22.
//

import UIKit

class CropDimmingView: UIView, CropMaskProtocol {
    var transparentLayer: CAShapeLayer?
    
    func setMask(_ insideRect: CGRect, animated: Bool) {
        guard self.bounds.size != .zero else {
            return
        }

        let layer = createTransparentRect(withOutside: bounds, insideRect: insideRect, opacity: 0.5)
        
        if let shapeLayer = transparentLayer {
            if animated {
                
                animateTransparentLayer(shapeLayer, withOutside: bounds, insideRect: insideRect, opacity: 0.5)
//                CATransaction.begin()
//                CATransaction.setDisableActions(true)
//                let animation = CABasicAnimation(keyPath: "path")
//                animation.fromValue = shapeLayer.path
//                animation.toValue = layer.path
//                animation.duration = 1
//                animation.timingFunction = CAMediaTimingFunction(name: .linear)
//                shapeLayer.add(animation, forKey: "pathAnimation")
//                shapeLayer.path = layer.path
//                CATransaction.commit()
            } else {
                shapeLayer.path = layer.path
            }
        } else {
            self.layer.addSublayer(layer)
            transparentLayer = layer
        }
    }
}
