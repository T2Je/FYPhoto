//
//  PhotoDetailTransitionAnimatorDelegate.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/24.
//

import Foundation

public protocol PhotoDetailTransitionAnimatorDelegate: class {

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
}

protocol PhotoDetailInteractivelyProtocol {
    /// Pan to dismiss
    var isInteractivelyDismissing: Bool { get set }
}
