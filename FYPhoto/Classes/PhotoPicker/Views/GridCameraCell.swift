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
        contentView.backgroundColor = UIColor(red: 237/255.0, green: 239/255.0, blue: 241/255.0, alpha: 1)
        imageView.contentMode = .center
        imageView.image = Asset.photoImageCamera.image
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
