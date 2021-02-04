//
//  PickerNavigationTitleView.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/30.
//

import UIKit

class PickerNavigationTitleView: UIView {

    var title: String = "" {
        willSet {
            titleLabel.text = newValue
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
    
    let imageView = UIImageView(image: Asset.albumArrow.image)
    
    var tapped: (() -> Void)?

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        titleLabel.textColor = .black
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        
        imageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        imageView.isUserInteractionEnabled = true
        addSubview(titleLabel)
        addSubview(imageView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: self.imageView.leadingAnchor, constant: -2)
        ])
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(PickerNavigationTitleView.tap(_:)))
        addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc fileprivate func tap(_ gesture: UITapGestureRecognizer) {
        tapped?()
    }
    
}
