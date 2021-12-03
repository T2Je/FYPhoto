//
//  AspectRatioButton.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/5/6.
//

import UIKit

class AspectRatioButton: UIButton {
    let item: AspectRatioButtonItem

    init(item: AspectRatioButtonItem) {
        self.item = item
        super.init(frame: .zero)
        setTitleColor(UIColor(white: 1, alpha: 0.8), for: .normal)
        setTitleColor(.white, for: .selected)
        backgroundColor = .clear
        titleLabel?.font = UIFont.systemFont(ofSize: 14)

        layer.masksToBounds = true

        if #available(iOS 13.0, *) {
            layer.cornerCurve = .continuous
        } else {
            // Fallback on earlier versions
        }

        contentEdgeInsets = UIEdgeInsets(top: 6,
                                         left: 16,
                                         bottom: 6,
                                         right: 16)

        isSelected = item.isSelected
        setTitle(item.title, for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            item.isSelected = isSelected
            updateAppearance()
        }
    }

    func updateAppearance() {
        if isSelected {
            backgroundColor = .init(white: 1, alpha: 0.5)
//            setTitleColor(.white, for: .normal)
        } else {
            backgroundColor = .clear
//            setTitleColor(UIColor(white: 1, alpha: 0.8), for: .normal)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

//    override var intrinsicContentSize: CGSize {
//        let superSize = super.intrinsicContentSize
//        return superSize
//    }
}
