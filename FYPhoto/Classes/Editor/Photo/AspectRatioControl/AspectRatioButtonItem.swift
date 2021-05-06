//
//  AspectRatioButtonItem.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/5/6.
//

import Foundation

public class AspectRatioButtonItem {
    let title: String
    var isSelected: Bool
    var ratio: Double
    
    public init(title: String, isSelected: Bool, ratio: Double) {
        self.title = title
        self.isSelected = isSelected
        self.ratio = ratio
    }
}
