//
//  CropVisualEffectView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/22.
//

import UIKit

class CropVisualEffectView: UIVisualEffectView, CropMaskProtocol {        

    override init(effect: UIVisualEffect?) {
        super.init(effect: effect)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setMask(_ insideRect: CGRect) {
        guard self.bounds.size != .zero else { return }
        self.mask = nil
        let layer = createTransparentRect(withOutside: bounds, insideRect: insideRect, opacity: 0.98)
        
        let maskView = UIView(frame: bounds)
        maskView.clipsToBounds = true
        maskView.layer.addSublayer(layer)
        
        self.mask = maskView
    }
    
}
