//
//  AssetGridViewController+AssetTransition.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/8/27.
//

import Foundation
import Photos

extension AssetGridViewController: AssetTransitioning {

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

    func targetFrame(transitionItem: Photo) -> CGRect? {
        guard
            let lastSelected = lastSelectedIndexPath,
            let cell = self.collectionView.cellForItem(at: lastSelected)
        else {
            return nil
        }
        return collectionView.convert(cell.frame, to: self.view)        
    }

    func willTransition(fromController: UIViewController, toController: UIViewController, item: Photo) {
        guard let indexPath = lastSelectedIndexPath else { return }
        collectionView.cellForItem(at: indexPath)?.isHidden = true
    }

    func didTransition(fromController: UIViewController, toController: UIViewController, item: Photo) {
        guard let indexPath = lastSelectedIndexPath else { return }
        collectionView.cellForItem(at: indexPath)?.isHidden = false
    }

    func itemForTransition(context: UIViewControllerContextTransitioning) -> Photo? {

//        var indexPaths = collectionView.indexPathsForVisibleItems
//        if context.isInteractive {
//            if let indexPath = collectionView.indexPathForItem(at: collectionView.panGestureRecognizer.location(in: collectionView)) {
//                indexPaths = [indexPath]
//            }
//        }
        guard
            let indexPath = lastSelectedIndexPath,
            let cell = self.collectionView.cellForItem(at: indexPath) as? GridViewCell
            else { return nil }
        let asset = fetchResult.object(at: indexPath.item)
        let photo = Photo(asset: asset)
        photo.underlyingImage = cell.imageView.image
        return photo
//        return indexPaths.map({ (indexPath: IndexPath) -> AssetTransitionItem in
//            let cell = collectionView.cellForItem(at: indexPath) as! GridViewCell
//            let asset = self.fetchResult.object(at: indexPath.item)
//            let initialFrame: CGRect
//
//            initialFrame = cell.convert(cell.bounds, to: nil)
//            return AssetTransitionItem(initialFrame: initialFrame, image: cell.imageView.image!, indexPath: indexPath, asset: asset)
//        })
    }

//    func targetFrame(transitionItem item: AssetTransitionItem) -> CGRect? {
//
////        if !collectionView.indexPathsForVisibleItems.contains(item.indexPath) {
////            collectionView.scrollToItem(at: item.indexPath, at: .centeredVertically, animated: false)
////            collectionView.layoutIfNeeded()
////        }
////
////        if let cell = collectionView.cellForItem(at: item.indexPath) as? GridViewCell {
////            if cell.representedAssetIdentifier == item.asset.localIdentifier {
////                return cell.convert(cell.bounds, to: nil)
////            }
////        }
//
//        guard
//            let lastSelected = lastSelectedIndexPath,
//            let cell = self.collectionView.cellForItem(at: lastSelected)
//        else {
//            return nil
//        }
//        return collectionView.convert(cell.frame, to: self.view)
//        return nil
//    }

//    func willTransition(fromController: UIViewController, toController: UIViewController, items: Array<AssetTransitionItem>) {
//        guard let collectionView = self.collectionView else { return }
//
//        let options = PHImageRequestOptions()
//        options.deliveryMode = .opportunistic
//        options.isNetworkAccessAllowed = true
//
//        for item in items {
//            collectionView.cellForItem(at: item.indexPath)?.alpha = 0.0
//
//            // Update the image resolution
//            if self == fromController {
//                self.imageManager.requestImage(for: item.asset, targetSize: item.targetFrame!.size, contentMode: .aspectFit, options: options, resultHandler: { [weak item] (result, _) in
//                    if let image = result {
//                        item?.image = image
//                    }
//                })
//            }
//        }
//    }

//    func didTransition(fromController: UIViewController, toController: UIViewController, items: Array<AssetTransitionItem>) {
//        guard let collectionView = self.collectionView else { return }
//
//        switch self.layoutStyle {
//        case .oneUp:
//            collectionView.alpha = 1.0
//            collectionView.panGestureRecognizer.isEnabled = true
//        case .grid:
//            for item in items {
//                collectionView.cellForItem(at: item.indexPath)?.alpha = 1.0
//            }
//        }
//    }
}
