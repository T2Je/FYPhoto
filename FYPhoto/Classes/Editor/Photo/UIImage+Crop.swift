//
//  UIImage+Crop.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/5/18.
//

import Foundation

extension UIImage {
    func cropWithFrame2(_ cropRect: CGRect, isCircular: Bool, radians: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(cropRect.size, false, scale)
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.translateBy(x: -cropRect.origin.x, y: -cropRect.origin.y)
        if radians != 0  {
            let imageBounds = CGRect(origin: .zero, size: size)
            let rotateBounds = imageBounds.applying(CGAffineTransform(rotationAngle: radians))
            ctx?.translateBy(x: -rotateBounds.origin.x, y: -rotateBounds.origin.y)
            ctx?.rotate(by: radians)
        }
        
        draw(at: .zero)
        if let renderer = UIGraphicsGetImageFromCurrentImageContext(), let image = renderer.cgImage {
            UIGraphicsEndImageContext()
            return UIImage(cgImage: image, scale: scale, orientation: imageOrientation)
        }
        UIGraphicsEndImageContext()
        return nil
    }
    
    func cropWithFrame(_ cropRect: CGRect, isCircular: Bool, radians: CGFloat) -> UIImage? {
        guard let cgImage = cgImage else { return nil }
        let isAlpha = cgImage.alphaInfo == CGImageAlphaInfo.first ||
            cgImage.alphaInfo == CGImageAlphaInfo.last ||
            cgImage.alphaInfo == CGImageAlphaInfo.premultipliedFirst ||
            cgImage.alphaInfo == CGImageAlphaInfo.premultipliedLast
        let format = imageRendererFormat
        format.opaque = !isAlpha && !isCircular
        format.scale = scale
        
        let renderer = UIGraphicsImageRenderer(size: cropRect.size, format: format).image { ctx in
//            ctx.cgContext.concatenate(.flippingVerticaly(size.height))
            // If we're capturing a circular image, set the clip mask first
            if isCircular {
                ctx.cgContext.addEllipse(in: CGRect(origin: .zero, size: cropRect.size))
                ctx.cgContext.clip()
            }
            // Offset the origin (Which is the top left corner) to start where our cropping origin is
            ctx.cgContext.translateBy(x: -cropRect.origin.x, y: -cropRect.origin.y)
            
            // If an angle was supplied, rotate the entire canvas + coordinate space to match
            if radians != 0 {
                let imageBounds = CGRect(origin: .zero, size: size)
                let rotateBounds = imageBounds.applying(CGAffineTransform(rotationAngle: radians))
                // As we're rotating from the top left corner, and not the center of the canvas, the frame
                // will have rotated out of our visible canvas. Compensate for this.
                ctx.cgContext.translateBy(x: -rotateBounds.origin.x, y: -rotateBounds.origin.y)
                ctx.cgContext.rotate(by: radians)
            }
            draw(at: .zero)
//            ctx.cgContext.draw(cgImage, in: CGRect(origin: .zero, size: cropRect.size))
//            ctx.cgContext.drawImage(image: cgImage, inRect: CGRect(origin: .zero, size: cropRect.size))
        }.cgImage
        
        return UIImage(cgImage: renderer!, scale: scale, orientation: imageOrientation)
    }
}
