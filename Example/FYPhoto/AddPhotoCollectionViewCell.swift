//
//  AddPhotoCollectionViewCell.swift
//  FYPhotoPicker_Example
//
//  Created by xiaoyang on 2020/8/3.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import SDWebImage

class AddPhotoCollectionViewCell: UICollectionViewCell {
    let imageView = UIImageView()
    let deleteBtn = UIButton()

    var delete: ((IndexPath) -> Void)?

    var isAdd = false {
        willSet {
            deleteBtn.isHidden = newValue
        }
    }

    var indexPath: IndexPath?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(imageView)
        contentView.addSubview(deleteBtn)

        imageView.isUserInteractionEnabled = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        

        deleteBtn.addTarget(self, action: #selector(AddPhotoCollectionViewCell.deleteButtonClicked(_:)), for: .touchUpInside)
        deleteBtn.setTitle("✕", for: .normal)
        deleteBtn.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        deleteBtn.layer.cornerRadius = 17
        deleteBtn.layer.masksToBounds = true
        deleteBtn.backgroundColor = UIColor(white: 1, alpha: 0.5)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        deleteBtn.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        NSLayoutConstraint.activate([
            deleteBtn.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            deleteBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            deleteBtn.widthAnchor.constraint(equalToConstant: 34),
            deleteBtn.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func deleteButtonClicked(_ sender: UIButton) {
        guard let indexPath = indexPath else { return }
        delete?(indexPath)
    }

    var image: UIImage? {
        willSet {
            imageView.image = newValue
            setNeedsDisplay()
        }
    }

}
