//
//  TapExpandedView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/3/26.
//

import Foundation
import UIKit

final class TapExpandedView: UIView {

    let horizontal: CGFloat
    let vertical: CGFloat

    init(horizontal: CGFloat, vertical: CGFloat) {
        self.horizontal = horizontal
        self.vertical = vertical
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.insetBy(dx: -horizontal, dy: -vertical).contains(point)
    }
}
