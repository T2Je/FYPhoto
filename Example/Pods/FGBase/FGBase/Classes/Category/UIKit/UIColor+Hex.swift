//
//  UIColor+FGHex.swift
//  FGBase
//
//  Created by kun wang on 2018/7/19.
//

import UIKit

extension UIColor {
    private convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }

    @objc public convenience init(hex rgb: Int) {
        self.init( red: (rgb >> 16) & 0xFF, green: (rgb >> 8) & 0xFF, blue: rgb & 0xFF)
    }

    @objc public convenience init(hex rgb: Int, alpha: CGFloat) {
        self.init( red: (rgb >> 16) & 0xFF, green: (rgb >> 8) & 0xFF, blue: rgb & 0xFF, alpha: alpha)
    }

    @objc public convenience init(hexString hex: String) {
        self.init(hexString: hex, alpha: 1.0)
    }

    @objc public convenience init(hexString hex: String, alpha: CGFloat) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        var rgbValue: UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        self.init(hex: Int(rgbValue), alpha: alpha)
    }

}


