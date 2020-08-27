//
//  CustomNavigationTitleView.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/30.
//

import UIKit

class CustomNavigationTitleView: UIView {

    var title: String = "" {
        willSet {
            titleLabel.text = String(format: "%@ %@", arguments: [newValue, triangleIcon])
            setNeedsDisplay()
        }
    }

    var titleColor: UIColor = .black {
        willSet {
            titleLabel.tintColor = newValue
            setNeedsDisplay()
        }
    }

    var titleFont: UIFont = UIFont.boldSystemFont(ofSize: 14) {
        willSet {
            titleLabel.font = newValue
            setNeedsDisplay()
        }
    }


    fileprivate let titleLabel = UILabel()
//    let imageView = UIImageView()
    fileprivate let triangleIcon = "▾"

    var tapped: (() -> Void)?

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        titleLabel.textColor = .black
        addSubview(titleLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(CustomNavigationTitleView.tap(_:)))
        addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc fileprivate func tap(_ gesture: UITapGestureRecognizer) {
        tapped?()
    }
    
}
