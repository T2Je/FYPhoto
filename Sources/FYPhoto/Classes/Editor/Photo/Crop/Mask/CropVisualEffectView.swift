//
//  CropVisualEffectView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/22.
//

import UIKit

class CropVisualEffectView: UIVisualEffectView, CropMaskProtocol {

    var transparentLayer: CAShapeLayer?

    override init(effect: UIVisualEffect?) {
        super.init(effect: effect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setMask(_ insideRect: CGRect, animated: Bool) {
        guard self.bounds.size != .zero else { return }
        let layer = createTransparentRect(withOutside: bounds, insideRect: insideRect, opacity: 0.98)

        if let shapeLayer = transparentLayer {
            if animated {
                animateTransparentLayer(shapeLayer, withOutside: bounds, insideRect: insideRect, opacity: 0.98)
            } else {
                shapeLayer.path = layer.path
            }
        } else {
            let maskView = UIView(frame: bounds)
            maskView.clipsToBounds = true
            maskView.layer.addSublayer(layer)
            transparentLayer = layer
            self.mask = maskView
        }
    }

    /// Create a brand new mask layer without using the exsisting shapeLayer.
    /// - Parameter insideRect: transparent rect
    func createBrandNewMask(_ insideRect: CGRect) {
        guard self.bounds.size != .zero else { return }
        let layer = createTransparentRect(withOutside: bounds, insideRect: insideRect, opacity: 0.98)
        let maskView = UIView(frame: bounds)
        maskView.clipsToBounds = true
        maskView.layer.addSublayer(layer)
        transparentLayer = layer
        self.mask = maskView
    }
}
