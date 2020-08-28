//
//  UIColor+Gradient.swift
//  FGBase
//
//  Created by kun wang on 2020/06/30.
//

import UIKit
import CoreGraphics

@objc public enum GradientStyle: Int {
    case leftToRight
    case radial
    case topToBottom
}

@objc public extension UIColor {
    @objc class func gradientColor(style: GradientStyle, frame: CGRect, colors: [UIColor]) -> UIColor? {
        let backgroundGradientLayer = CAGradientLayer()
        backgroundGradientLayer.frame = frame
        let cgColors = colors.map { $0.cgColor }

        switch style {
        case .leftToRight:
            //Set out gradient's colors
            backgroundGradientLayer.colors = cgColors

            //Specify the direction our gradient will take
            backgroundGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            backgroundGradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)

            //Convert our CALayer to a UIImage object
            UIGraphicsBeginImageContextWithOptions(backgroundGradientLayer.bounds.size, false, UIScreen.main.scale)
            if let context = UIGraphicsGetCurrentContext() {
                backgroundGradientLayer.render(in: context)
            }
            guard let backgroundColorImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
            UIGraphicsEndImageContext()

            return UIColor(patternImage: backgroundColorImage)
        case .radial:
            UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.main.scale)

            //Specific the spread of the gradient (For now this gradient only takes 2 locations)
            let locations: [CGFloat] = [0.0, 1.0]

            //Default to the RGB Colorspace
            let myColorspace = CGColorSpaceCreateDeviceRGB()

            //Create our Fradient
            guard let myGradient = CGGradient(colorsSpace: myColorspace, colors: cgColors as CFArray, locations: locations) else { return nil }
            // Normalise the 0-1 ranged inputs to the width of the image
            let myCentrePoint = CGPoint(x: 0.5 * frame.size.width, y: 0.5 * frame.size.height)
            let myRadius: CGFloat = min(frame.size.width, frame.size.height) * 1.0

            // Draw our Gradient
            UIGraphicsGetCurrentContext()?.drawRadialGradient(
                myGradient,
                startCenter: myCentrePoint,
                startRadius: 0,
                endCenter: myCentrePoint,
                endRadius: CGFloat(myRadius),
                options: .drawsAfterEndLocation)

            // Grab it as an Image
            guard let backgroundColorImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
            UIGraphicsEndImageContext()
            return UIColor(patternImage: backgroundColorImage)
        case .topToBottom:
            //Set out gradient's colors
            backgroundGradientLayer.colors = cgColors
            //Convert our CALayer to a UIImage object
            UIGraphicsBeginImageContextWithOptions(backgroundGradientLayer.bounds.size, false, UIScreen.main.scale)
            if let context = UIGraphicsGetCurrentContext() {
                backgroundGradientLayer.render(in: context)
            }
            guard let backgroundColorImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
            UIGraphicsEndImageContext()
            return UIColor(patternImage: backgroundColorImage)
        }
    }
}
