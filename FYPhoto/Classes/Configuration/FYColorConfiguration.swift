//
//  FYColorConfiguration.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/2/18.
//

import Foundation

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

    public var selectionTitleColor: UIColor = .white
    public var selectionBackgroudColor: UIColor = .fyBlueTintColor
    
    public var topBarColor =
        BarColor(itemTintColor: UIColor.fyBlueTintColor,
                 itemDisableColor: .systemGray,
                 itemBackgroundColor: .white,
                 backgroundColor: .white)
    
    @available(swift, deprecated: 1.2.0, message: "topBarColorStyle is renamed to topBarColor")
    public var topBarColorStyle =
        BarColor(itemTintColor: UIColor.fyBlueTintColor,
                 itemDisableColor: .systemGray,
                 itemBackgroundColor: .white,
                 backgroundColor: .white)
    
    public var pickerBottomBarColor =
        BarColor(itemTintColor: UIColor.fyBlueTintColor,
                 itemDisableColor: .fyItemDisableColor,
                 itemBackgroundColor: .fyGrayBackgroundColor,
                 backgroundColor: .fyGrayBackgroundColor)
    
    @available(swift, deprecated: 1.2.0, message: "pickerBottomBarColorStyle is renamed to pickerBottomBarColor")
    public var pickerBottomBarColorStyle =
        BarColor(itemTintColor: UIColor.fyBlueTintColor,
                 itemDisableColor: .fyItemDisableColor,
                 itemBackgroundColor: .fyGrayBackgroundColor,
                 backgroundColor: .fyGrayBackgroundColor)
    
    public var browserBottomBarColor =
        BarColor(itemTintColor: UIColor.fyBlueTintColor,
                 itemDisableColor: .fyItemDisableColor,
                 itemBackgroundColor: .white,
                 backgroundColor: UIColor(white: 0.1, alpha: 0.9))
    
    @available(swift, deprecated: 1.2.0, message: "browserBottomBarColorStyle is renamed to browserBottomBarColor")
    public var browserBottomBarColorStyle =
        BarColor(itemTintColor: UIColor.fyBlueTintColor,
                 itemDisableColor: .fyItemDisableColor,
                 itemBackgroundColor: .white,
                 backgroundColor: UIColor(white: 0.1, alpha: 0.9))
}

extension UIColor {
    static let fyBlueTintColor = UIColor(red: 24/255.0,
                                         green: 135/255.0,
                                         blue: 251/255.0,
                                         alpha: 1)
    
    static let fyItemDisableColor = UIColor(red: 167/255.0,
                                            green: 171/255.0,
                                            blue: 177/255.0,
                                            alpha: 1)
    
    static let fyGrayBackgroundColor = UIColor(red: 249/255.0,
                                               green: 249/255.0,
                                               blue: 249/255.0,
                                               alpha: 1)
}
