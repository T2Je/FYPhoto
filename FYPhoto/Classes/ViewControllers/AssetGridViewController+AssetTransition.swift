//
//  AssetGridViewController+AssetTransition.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/8/27.
//

import Foundation
import Photos

extension AssetGridViewController: AssetTransitioning {
    func itemsForTransition(context: UIViewControllerContextTransitioning) -> Array<AssetTransitionItem> {
        guard let collectionView = self.collectionView else { return [] }

        var indexPaths = collectionView.indexPathsForVisibleItems
        if context.isInteractive {
            if let indexPath = collectionView.indexPathForItem(at: collectionView.panGestureRecognizer.location(in: collectionView)) {
                indexPaths = [indexPath]
            }
        }

        return indexPaths.map({ (indexPath: IndexPath) -> AssetTransitionItem in
            let cell = collectionView.cellForItem(at: indexPath) as! GridViewCell
            let asset = self.fetchResult.object(at: indexPath.item)
            let initialFrame: CGRect

            initialFrame = cell.convert(cell.bounds, to: nil)
            return AssetTransitionItem(initialFrame: initialFrame, image: cell.imageView.image!, indexPath: indexPath, asset: asset)
        })
    }

    func targetFrame(transitionItem item: AssetTransitionItem) -> CGRect? {
        guard let collectionView = self.collectionView else { return nil }

        if !collectionView.indexPathsForVisibleItems.contains(item.indexPath) {
            collectionView.scrollToItem(at: item.indexPath, at: .centeredVertically, animated: false)
            collectionView.layoutIfNeeded()
        }

        if let cell = collectionView.cellForItem(at: item.indexPath) as? GridViewCell {
            if cell.representedAssetIdentifier == item.asset.localIdentifier {
                return cell.convert(cell.bounds, to: nil)
            }
        }

        return nil
    }

    func willTransition(fromController: UIViewController, toController: UIViewController, items: Array<AssetTransitionItem>) {
        guard let collectionView = self.collectionView else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        for item in items {
            collectionView.cellForItem(at: item.indexPath)?.alpha = 0.0

            // Update the image resolution
            if self == fromController {
                self.imageManager.requestImage(for: item.asset, targetSize: item.targetFrame!.size, contentMode: .aspectFit, options: options, resultHandler: { [weak item] (result, _) in
                    if let image = result {
                        item?.image = image
                    }
                })
            }
        }
    }

    func didTransition(fromController: UIViewController, toController: UIViewController, items: Array<AssetTransitionItem>) {
        guard let collectionView = self.collectionView else { return }

        switch self.layoutStyle {
        case .oneUp:
            collectionView.alpha = 1.0
            collectionView.panGestureRecognizer.isEnabled = true
        case .grid:
            for item in items {
                collectionView.cellForItem(at: item.indexPath)?.alpha = 1.0
            }
        }
    }
}
