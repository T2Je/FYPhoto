//
//  AlbumCell.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/30.
//

import UIKit

class AlbumCell: UITableViewCell {

    fileprivate let coverImage = UIImageView()
    fileprivate let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        coverImage.contentMode = .scaleAspectFill
        coverImage.clipsToBounds = true

        contentView.addSubview(coverImage)
        contentView.addSubview(nameLabel)

        coverImage.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            coverImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            coverImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            coverImage.widthAnchor.constraint(equalToConstant: 50),
            coverImage.heightAnchor.constraint(equalToConstant: 50)
        ])

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: coverImage.trailingAnchor, constant: 10),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(image: UIImage, title: String) {
        coverImage.image = image
        nameLabel.text = title
    }

    var cover: UIImage? {
        willSet {
            coverImage.image = newValue
            setNeedsDisplay()
        }
    }

    var name: String? {
        willSet {
            nameLabel.text = newValue
            setNeedsDisplay()
        }
    }

}
