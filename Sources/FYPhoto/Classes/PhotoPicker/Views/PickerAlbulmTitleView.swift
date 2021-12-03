//
//  PickerNavigationTitleView.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/30.
//

import UIKit

class PickerAlbulmTitleView: UIView {

    var title: String = "" {
        willSet {
            titleLabel.text = newValue
            setNeedsDisplay()
        }
    }

    var titleColor: UIColor = .black {
        willSet {
            titleLabel.textColor = newValue
            setNeedsDisplay()
        }
    }

    var titleFont: UIFont = UIFont.boldSystemFont(ofSize: 14) {
        willSet {
            titleLabel.font = newValue
            setNeedsDisplay()
        }
    }

    var imageColor: UIColor = .systemBlue {
        didSet {
            imageView.tintColor = imageColor
            imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
        }
    }

    fileprivate let titleLabel = UILabel()

    let imageView = UIImageView(image: Asset.albumArrow.image)

    var tapped: (() -> Void)?

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        titleLabel.textColor = .black
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textAlignment = .center

        imageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
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
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 15),
            imageView.heightAnchor.constraint(equalToConstant: 15)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(PickerAlbulmTitleView.tap(_:)))
        addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc fileprivate func tap(_ gesture: UITapGestureRecognizer) {
        tapped?()
    }

}
