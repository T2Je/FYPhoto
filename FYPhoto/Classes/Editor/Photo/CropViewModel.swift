//
//  CropViewModel.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/20.
//

import Foundation

class CropViewModel: NSObject {
    var statusChanged: ((CropViewStatus) -> Void)?
    var rotationChanged: ((PhotoRotationDegree) -> Void)?
    var aspectRatioChanged: ((PhotoAspectRatio) -> Void)?
    
    /// initial frame of the imageView. Need to be reseted when device rotates.
    @objc dynamic var initialFrame: CGRect = .zero
    
    var image: UIImage
    
    var isPortrait = true
    
    var status: CropViewStatus = .initial {
        didSet {
            statusChanged?(status)
        }
    }
    
    
    var aspectRatio: PhotoAspectRatio
    var rotationDegree: PhotoRotationDegree = .zero
    
    init(image: UIImage) {
        self.image = image
        aspectRatio = PhotoAspectRatio(width: image.size.width, height: image.size.height)
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
    
    func getProporateGuideViewRect(fromOutside outside: CGRect) -> CGRect {
        guard image.size.width > 0 && image.size.height > 0 else {
            return .zero
        }
        
        let inside: CGRect
        
        let imageSize =
        if isPortrait {
            
            inside = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        } else {
            inside = CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width)
        }
        
        return GeometryHelper.getAppropriateRect(fromOutside: outside, inside: inside)
    }
    
    // CropGuideView moves around in this area
    func getContentBounds(_ outsideRect: CGRect, _ padding: CGFloat) -> CGRect {
        var rect = outsideRect
        rect.origin.x = rect.origin.x + padding
        rect.origin.y = rect.origin.y + padding
        rect.size.width = rect.size.width - padding * 2
        rect.size.height = rect.size.height - padding * 2
        return rect
    }
    
    func resetCropFrame(_ rect: CGRect) {
        initialFrame = rect
    }

}
