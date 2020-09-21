//
//  PhotoDetailCollectionViewControllerDelegate.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/21.
//

import Foundation

public protocol PhotoDetailCollectionViewControllerDelegate: class {
    func showNavigationBar(in photoDetail: PhotoDetailCollectionViewController) -> Bool
    func showBottomToolBar(in photoDetail: PhotoDetailCollectionViewController) -> Bool
    func canSelectPhoto(in photoDetail: PhotoDetailCollectionViewController) -> Bool
    func canEditPhoto(in photoDetail: PhotoDetailCollectionViewController) -> Bool
    func canDisplayCaption(in photoDetail: PhotoDetailCollectionViewController) -> Bool

    func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, scrollAt indexPath: IndexPath)
    func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, selectedPhotos indexPaths: [IndexPath])
    func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, didCompleteSelected photos: [PhotoProtocol])
}

public extension PhotoDetailCollectionViewControllerDelegate {
    func showNavigationBar(in photoDetail: PhotoDetailCollectionViewController) -> Bool {
        true
    }
    func showBottomToolBar(in photoDetail: PhotoDetailCollectionViewController) -> Bool {
        false
    }

    func canSelectPhoto(in photoDetail: PhotoDetailCollectionViewController) -> Bool {
        false
    }
    func canEditPhoto(in photoDetail: PhotoDetailCollectionViewController) -> Bool {
        false
    }
    func canDisplayCaption(in photoDetail: PhotoDetailCollectionViewController) -> Bool {
        false
    }

    func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, scrollAt indexPath: IndexPath) {

    }
    func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, selectedPhotos indexPaths: [IndexPath]) {

    }
    func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, didCompleteSelected photos: [PhotoProtocol]) {

    }
}
