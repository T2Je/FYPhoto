//
//  UICollectionView+IndexPathsInRect.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/7/30.
//

import Foundation
import UIKit

extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}
