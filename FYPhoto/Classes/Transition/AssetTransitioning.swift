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
    func itemsForTransition(context: UIViewControllerContextTransitioning) -> Array<AssetTransitionItem>
    func targetFrame(transitionItem: AssetTransitionItem) -> CGRect?
    func willTransition(fromController: UIViewController, toController: UIViewController, items: Array<AssetTransitionItem>)
    func didTransition(fromController: UIViewController, toController: UIViewController, items: Array<AssetTransitionItem>)

    /// if true, self is pushed by navigation controller using Asset transition.
    func willPushedByAssetTransition() -> Bool
}

extension AssetTransitioning {
    func willPushedByAssetTransition() -> Bool {
        true
    }
}


