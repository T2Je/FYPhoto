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
    var ratio: Double?
    let isFreeForm: Bool

    public init(title: String, ratio: Double?) {
        self.title = title

        self.ratio = ratio
        self.isFreeForm = ratio == nil
        self.isSelected = isFreeForm
    }
}
