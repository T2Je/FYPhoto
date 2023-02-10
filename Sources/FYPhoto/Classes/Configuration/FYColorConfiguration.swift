//
//  FYColorConfiguration.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/2/18.
//

import Foundation
import UIKit

/// FYPhoto color configuration.
public class FYColorConfiguration {
    public class BarColor {
        public let itemTintColor: UIColor
        public let itemDisableColor: UIColor
        public let itemBackgroundColor: UIColor
        // bar backgroundColor
        public let backgroundColor: UIColor

        public init(itemTintColor: UIColor,
                    itemDisableColor: UIColor,
                    itemBackgroundColor: UIColor,
                    backgroundColor: UIColor) {
            self.itemTintColor = itemTintColor
            self.itemDisableColor = itemDisableColor
            self.itemBackgroundColor = itemBackgroundColor
            self.backgroundColor = backgroundColor
        }
    }

    public init() {}

    // picker cell selection color
    public var selectionTitleColor: UIColor = .white
    public var selectionBackgroudColor: UIColor = .fyBlueTintColor
    
    public var topBarColor =
        BarColor(itemTintColor: UIColor.fyBlueTintColor,
                 itemDisableColor: .systemGray,
                 itemBackgroundColor: .clear,
                 backgroundColor: .white)

    public var pickerBottomBarColor =
        BarColor(itemTintColor: UIColor.fyBlueTintColor,
                 itemDisableColor: .fyItemDisableColor,
                 itemBackgroundColor: .fyGrayBackgroundColor,
                 backgroundColor: .fyGrayBackgroundColor)

    public var browserBottomBarColor =
        BarColor(itemTintColor: UIColor.fyBlueTintColor,
                 itemDisableColor: .fyItemDisableColor,
                 itemBackgroundColor: .white,
                 backgroundColor: UIColor(white: 0.1, alpha: 0.9))

}

extension UIColor {
    static let fyBlueTintColor = #colorLiteral(red: 0.09411764706, green: 0.5294117647, blue: 0.9843137255, alpha: 1)

    static let fyItemDisableColor = #colorLiteral(red: 0.6549019608, green: 0.6705882353, blue: 0.6941176471, alpha: 1)

    static let fyGrayBackgroundColor = UIColor.color(light: #colorLiteral(red: 0.9764705882, green: 0.9764705882, blue: 0.9764705882, alpha: 1),
                                                     dark: #colorLiteral(red: 0.1843137255, green: 0.1843137255, blue: 0.1843137255, alpha: 1))

    static func color(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traits -> UIColor in
                if traits.userInterfaceStyle == .dark {
                    return dark
                } else {
                    return light
                }
            }
        } else {
            return light
        }
    }
}
