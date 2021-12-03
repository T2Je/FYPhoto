//
//  AssetTransitioning.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/8/27.
//

import Foundation
import UIKit
import Photos

public protocol PhotoTransitioning {
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

    /// The location onscreen for the imageView provided in `referenceImageView(for:)`.
    /// If image frame is right, but image shows in wrong origin, consider set edgesForExtendedLayout to .all.
    func imageFrame() -> CGRect?

    /// if true, self is pushed by navigation controller using Photo transition.
    func enablePhotoTransitionPush() -> Bool
}

extension PhotoTransitioning {
    public func transitionWillStart() {}
    public func transitionDidEnd() {}
    public func enablePhotoTransitionPush() -> Bool {
        true
    }
}
