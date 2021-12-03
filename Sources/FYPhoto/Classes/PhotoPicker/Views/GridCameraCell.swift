//
//  GridCameraCell.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/8.
//

import UIKit

class GridCameraCell: UICollectionViewCell {
    static let reuseIdentifier = "GridCameraCell"
    let imageView = UIImageView()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor.color(light: #colorLiteral(red: 0.9294117647, green: 0.937254902, blue: 0.9450980392, alpha: 1), dark: #colorLiteral(red: 0.1843137255, green: 0.1843137255, blue: 0.1843137255, alpha: 1))
        imageView.contentMode = .center
        imageView.image = Asset.photoImageCamera.image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.color(light: #colorLiteral(red: 0.1843137255, green: 0.1843137255, blue: 0.1843137255, alpha: 1), dark: #colorLiteral(red: 0.9294117647, green: 0.937254902, blue: 0.9450980392, alpha: 1))
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
