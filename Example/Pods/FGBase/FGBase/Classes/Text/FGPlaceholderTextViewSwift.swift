//
//  FGPlaceholderTextView.swift
//  FYGOMS
//
//  Created by xiaoyang on 2018/7/26.
//  Copyright © 2018年 feeyo. All rights reserved.
//

import UIKit

@objc(FGPlaceholderTextView)
public class FGPlaceholderTextViewSwift: UITextView {
    @objc public var placeholder: String {
        didSet {
            setNeedsDisplay()
        }
    }

    @objc(placeholderTextColor)
    public var placeholderColor: UIColor {
        didSet {
            setNeedsDisplay()
        }
    }

    @objc public var placeholderFont: UIFont {
        didSet {
            setNeedsDisplay()
        }
    }

    @objc public var attributedPlaceholder: NSAttributedString? {
        didSet {
            setNeedsDisplay()
        }
    }


    /// Fix Bug: can't call UIView init(frame: CGRect)
    /// Probably a bug of Apple
    ///
    /// - Parameter frame: frame
    @objc public convenience init(frame: CGRect) {
        self.init(frame: frame, placeholder: "", color: nil)
    }

    @objc public init(frame: CGRect, placeholder: String, color: UIColor?) {
        self.placeholder = placeholder
        if let color = color {
            self.placeholderColor = color
        } else {
            self.placeholderColor = UIColor(hexString: "#999999")
        }
        placeholderFont = UIFont.systemFont(ofSize: 14)
        super.init(frame: frame, textContainer: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(textChanged(_:)), name: UITextView.textDidChangeNotification, object: nil)
    }

    @objc func textChanged(_ noti: NSNotification) {
//        if self.textStorage.length != 0 {
            setNeedsDisplay()
//        }

    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        guard self.textStorage.length == 0 else {
            return
        }
        placeholderColor.setFill()
        let attrDic = [NSAttributedString.Key.font: self.placeholderFont, NSAttributedString.Key.foregroundColor: self.placeholderColor]
        let rect = CGRect(x: 8, y: 6, width: rect.size.width - 8.0, height: rect.size.height - 6.0)

        if let attributedPlaceholder = attributedPlaceholder {
            attributedPlaceholder.draw(in: rect)
        } else {
            (placeholder as NSString).draw(in: rect, withAttributes: attrDic)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
