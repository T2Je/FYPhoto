//
//  CropViewModel.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/20.
//

import Foundation

class CropViewModel: NSObject {
//    var cropViewFrame: CGRect = .zero
    var imageFrame: CGRect = .zero
    
    var image: UIImage
    
    var isPortrait = true
    
    init(image: UIImage) {
        self.image = image
    }
    
    func getInitialCropGuideViewRect(fromOutside outside: CGRect) -> CGRect {
        guard image.size.width > 0 && image.size.height > 0 else {
            return .zero
        }
        
        let inside: CGRect
        
        if isPortrait {
            inside = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        } else {
            inside = CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width)
        }
        
        return GeometryHelper.getAppropriateRect(fromOutside: outside, inside: inside)
    }
    
    func resetCropFrame(_ rect: CGRect) {
        imageFrame = rect
    }

}
