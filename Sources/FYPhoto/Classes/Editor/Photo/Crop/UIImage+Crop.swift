//
//  UIImage+Crop.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/5/18.
//

import Foundation
import UIKit

extension UIImage {
    func getCroppedImage(byCropInfo info: CropInfo) -> UIImage? {
        guard let fixedImage = self.cgImageWithFixedOrientation() else {
            return nil
        }

        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: info.translation.x, y: info.translation.y)
        transform = transform.rotated(by: info.rotation)
        transform = transform.scaledBy(x: info.scale, y: info.scale)

        guard let imageRef = fixedImage.transformedImage(transform,
                                                         zoomScale: info.scale,
                                                         sourceSize: self.size,
                                                         cropSize: info.cropSize,
                                                         imageViewSize: info.imageViewSize) else {
                                                            return nil
        }

        return UIImage(cgImage: imageRef)
    }

    func cgImageWithFixedOrientation() -> CGImage? {

        guard let cgImage = self.cgImage, let colorSpace = cgImage.colorSpace else {
            return nil
        }

        if self.imageOrientation == UIImage.Orientation.up {
            return self.cgImage
        }

        let width  = self.size.width
        let height = self.size.height

        var transform = CGAffineTransform.identity

        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: width, y: height)
            transform = transform.rotated(by: CGFloat.pi)

        case .left, .leftMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.rotated(by: 0.5 * CGFloat.pi)

        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: height)
            transform = transform.rotated(by: -0.5 * CGFloat.pi)

        case .up, .upMirrored:
            break
        @unknown default:
            break
        }

        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)

        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)

        default:
            break
        }

        guard let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: UInt32(cgImage.bitmapInfo.rawValue)
            ) else {
                return nil
        }

        context.concatenate(transform)

        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: height, height: width))

        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        // And now we just create a new UIImage from the drawing context
        guard let newCGImg = context.makeImage() else {
            return nil
        }

        return newCGImg
    }
}

extension CGImage {

    func transformedImage(_ transform: CGAffineTransform, zoomScale: CGFloat, sourceSize: CGSize, cropSize: CGSize, imageViewSize: CGSize) -> CGImage? {
        guard var colorSpaceRef = self.colorSpace else {
            return self
        }
        // If the color space does not allow output, default to the RGB color space
        if !colorSpaceRef.supportsOutput {
            colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        }

        let expectedWidth = floor(sourceSize.width / imageViewSize.width * cropSize.width) / zoomScale
        let expectedHeight = floor(sourceSize.height / imageViewSize.height * cropSize.height) / zoomScale
        let outputSize = CGSize(width: expectedWidth, height: expectedHeight)
        let bitmapBytesPerRow = 0

        func getBitmapInfo() -> UInt32 {
            if colorSpaceRef.model == .rgb {
                switch(bitsPerPixel, bitsPerComponent) {
                case (16, 5):
                    return CGImageAlphaInfo.noneSkipFirst.rawValue
                case (32, 8):
                    return CGImageAlphaInfo.premultipliedLast.rawValue
                case (32, 10):
                    if #available(iOS 12, macOS 10.14, *) {
                        return CGImageAlphaInfo.alphaOnly.rawValue | CGImagePixelFormatInfo.RGBCIF10.rawValue
                    } else {
                        return bitmapInfo.rawValue
                    }
                case (64, 16):
                    return CGImageAlphaInfo.premultipliedLast.rawValue
                case (128, 32):
                    return CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.floatComponents.rawValue
                default:
                    return bitmapInfo.rawValue
                }
            }

            return bitmapInfo.rawValue
        }

        guard let context = CGContext(data: nil,
                                width: Int(outputSize.width),
                                height: Int(outputSize.height),
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bitmapBytesPerRow,
                                space: colorSpaceRef,
                                bitmapInfo: getBitmapInfo()) else {
            return self
        }

        context.setFillColor(UIColor.clear.cgColor)
        context.fill(CGRect(x: 0,
                             y: 0,
                             width: outputSize.width,
                             height: outputSize.height))

        var uiCoords = CGAffineTransform(scaleX: outputSize.width / cropSize.width,
                                         y: outputSize.height / cropSize.height)
        uiCoords = uiCoords.translatedBy(x: cropSize.width / 2, y: cropSize.height / 2)
        uiCoords = uiCoords.scaledBy(x: 1.0, y: -1.0)

        context.concatenate(uiCoords)
        context.concatenate(transform)
        context.scaleBy(x: 1.0, y: -1.0)
        context.draw(self, in: CGRect(x: (-imageViewSize.width / 2),
                                       y: (-imageViewSize.height / 2),
                                       width: imageViewSize.width,
                                       height: imageViewSize.height))

        let result = context.makeImage()

        return result
    }
}
