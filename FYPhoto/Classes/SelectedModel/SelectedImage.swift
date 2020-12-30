//
//  SelectedImage.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/30.
//

import Foundation
import Photos

public class SelectedImage {
    public init(asset: PHAsset?, image: UIImage) {
        self.asset = asset
        self.image = image
    }
    
    public let asset: PHAsset?
    public let image: UIImage
    
}
