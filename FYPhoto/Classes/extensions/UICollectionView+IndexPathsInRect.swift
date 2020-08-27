//
//  UICollectionView+IndexPathsInRect.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/30.
//

import Foundation

extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}
