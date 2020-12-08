//
//  GridCameraCell.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/8.
//

import UIKit

class GridCameraCell: UICollectionViewCell {
    let imageView = UIImageView()
        
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor(red: 237/255.0, green: 239/255.0, blue: 241/255.0, alpha: 1)
        imageView.contentMode = .scaleAspectFit
        imageView.image = "photo_image_camera".photoImage
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
