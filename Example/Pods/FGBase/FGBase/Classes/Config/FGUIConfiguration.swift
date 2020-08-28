//
//  FGUIConfiguration.swift
//  FGBase
//
//  Created by kun wang on 2020/07/21.
//

import Foundation
import UIKit

@objcMembers
public class FGUIConfiguration: NSObject {
    public static let shared = FGUIConfiguration()

    private override init() {
        super.init()
    }

    @available(*, deprecated)
    public static func sharedInstance() -> FGUIConfiguration {
        return shared
    }

    public var bgColor = UIColor(displayP3Red: 0.949, green: 0.949, blue: 0.949, alpha: 1.00) //#f2f2f2
    public var navBGColor = UIColor(displayP3Red: 0.125, green: 0.369, blue: 0.749, alpha: 1.00) //0x205ebf
    public var lineGrayColor = UIColor(displayP3Red: 0.863, green: 0.863, blue: 0.863, alpha: 1.00) //0xdcdcdc
    public var lineHeight: CGFloat = (1.0 / UIScreen.main.scale)
}
