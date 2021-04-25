//
//  PhotoAspectRatio.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/25.
//

import Foundation

public struct RatioItem {
    let title: String
    let value: Double
}

public struct RatioOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    static public let original = RatioOptions(rawValue: 1 << 0)
    static public let square = RatioOptions(rawValue: 1 << 1)
    static public let extraDefaultRatios = RatioOptions(rawValue: 1 << 2)
    static public let custom = RatioOptions(rawValue: 1 << 3)
    
    static public let all: RatioOptions = [original, square, extraDefaultRatios, custom]
}

class RatioManager {
    let ratioOptions: RatioOptions
    
    var horizontalItems: [RatioItem]
    var verticalItems: [RatioItem]
    
    init(ratioOptions: RatioOptions, custom: [RatioItem]) {
        if ratioOptions.contains(.original) {
            horizontalItems.append(RatioItem(title: L10n.orinial, value: 1))
            verticalItems.append(RatioItem(title: L10n.orinial, value: 1))
        }
        if ratioOptions.contains(.square) {
            horizontalItems.append(RatioItem(title: L10n.orinial, value: 1))
            verticalItems.append(RatioItem(title: L10n.orinial, value: 1))
        }
        if ratioOptions.contains(.extraDefaultRatios) {
            horizontalItems += horizontalExtraDefault()
            verticalItems += verticalExtraDefault()
        }
        if ratioOptions.contains(.custom) {
            horizontalItems += custom
            verticalItems += custom
        }
    }
    
    func horizontalExtraDefault() -> [RatioItem] {
        [RatioItem(title: "16:9", value: 16.0 / 9.0),
         RatioItem(title: "10:8", value: 10.0 / 8.0),
         RatioItem(title: "7:5", value: 7.0 / 5.0),
         RatioItem(title: "4:3", value: 4.0 / 3.0),
         RatioItem(title: "5:3", value: 5.0 / 3.0),
         RatioItem(title: "3:2", value: 3.0 / 2.0)
        ]
    }
    
    func verticalExtraDefault() -> [RatioItem] {
        [RatioItem(title: "9:16", value: 9.0 / 16.0),
         RatioItem(title: "8:10", value: 8.0 / 10.0),
         RatioItem(title: "5:7", value: 5.0 / 7.0),
         RatioItem(title: "3:4", value: 3.0 / 4.0),
         RatioItem(title: "3:5", value: 3.0 / 5.0),
         RatioItem(title: "2:3", value: 2.0 / 3.0)
        ]
    }
}
