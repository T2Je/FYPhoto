//
//  PaddingLabel.swift
//  FGBase
//
//  Created by xiaoyang on 2019/4/8.
//

import UIKit

@objc public class PaddingLabel: UILabel {

    @objc public var padding: UIEdgeInsets {
        didSet {
            setNeedsDisplay()
        }
    }

    @objc public init(padding: UIEdgeInsets = .zero, frame: CGRect = .zero) {
        self.padding = padding
        super.init(frame: frame)
    }

    @objc public required init?(coder aDecoder: NSCoder) {
        self.padding = .zero
        super.init(coder: aDecoder)
    }

    public override func drawText(in rect: CGRect) {
        let new = rect.inset(by: padding)
        super.drawText(in: new)
    }

    // Override `intrinsicContentSize` property for Auto layout code
    public override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize
        let height = superSize.height + padding.top + padding.bottom
        let width = superSize.width + padding.left + padding.right
        return CGSize(width: width, height: height)
    }

    // Override `sizeThatFits(_:)` method for Springs & Struts code
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let superSize = super.sizeThatFits(size)
        let height = superSize.height + padding.top + padding.bottom
        let width = superSize.width + padding.left + padding.right
        return CGSize(width: width, height: height)
    }

}
