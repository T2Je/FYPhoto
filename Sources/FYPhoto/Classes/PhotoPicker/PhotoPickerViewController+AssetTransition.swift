//
//  PhotoPickerViewController+AssetTransition.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/8/27.
//

import Foundation
import Photos
import UIKit

extension PhotoPickerViewController {

    public func transitionWillStart() {
        guard let indexPath = lastSelectedIndexPath else { return }
        collectionView.cellForItem(at: indexPath)?.isHidden = true
    }

    public func transitionDidEnd() {
        guard let indexPath = lastSelectedIndexPath else { return }
        collectionView.cellForItem(at: indexPath)?.isHidden = false
    }

    public func referenceImage() -> UIImage? {
        guard let indexPath = lastSelectedIndexPath else { return nil }
        guard let cell = collectionView.cellForItem(at: indexPath) as? GridViewCell else {
            return nil
        }
        return cell.imageView.image
    }

    public func imageFrame() -> CGRect? {
        guard
            let lastSelected = lastSelectedIndexPath,
            let cell = self.collectionView.cellForItem(at: lastSelected)
        else {
            return nil
        }
        return collectionView.convert(cell.frame, to: self.view)
    }
}
