//
//  AssetTransitioning.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/8/27.
//

import Foundation
import UIKit
import Photos

class AssetTransitionItem: NSObject {
    var initialFrame: CGRect
    var image: UIImage {
        didSet {
            imageView?.image = image
        }
    }
    var indexPath: IndexPath
    var asset: PHAsset
    var targetFrame: CGRect?
    var imageView: UIImageView?
    var touchOffset: CGVector = CGVector.zero

    init(initialFrame: CGRect, image: UIImage, indexPath: IndexPath, asset: PHAsset) {
        self.initialFrame = initialFrame
        self.image = image
        self.indexPath = indexPath
        self.asset = asset
        super.init()
    }
}

protocol AssetTransitioning {
//    func itemForTransition(context: UIViewControllerContextTransitioning) -> Photo?
//    func targetFrame(transitionItem: Photo) -> CGRect?
//    func willTransition(fromController: UIViewController, toController: UIViewController, item: Photo)
//    func didTransition(fromController: UIViewController, toController: UIViewController, item: Photo)

    /// Called just-before the transition animation begins.
    /// Use this to prepare for the transition.
    func transitionWillStart()

    /// Called right-after the transition animation ends.
    /// Use this to clean up after the transition.
    func transitionDidEnd()

    /// The animator needs a UIImageView for the transition;
    /// eg the Photo Detail screen should provide a snapshotView of its image,
    /// and a collectionView should do the same for its image views.
    func referenceImage() -> UIImage?

    /// The location onscreen for the imageView provided in `referenceImageView(for:)`
    func imageFrame() -> CGRect?
    
    /// if true, self is pushed by navigation controller using Asset transition.
    func enableAssetTransitionPush() -> Bool
}

extension AssetTransitioning {
    func enableAssetTransitionPush() -> Bool {
        true
    }
}


