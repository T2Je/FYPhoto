//
//  PhotoDetailCollectionViewControllerDelegate.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/21.
//

import Foundation

public protocol PhotoDetailCollectionViewControllerDelegate: class {
    func showNavigationBar(in photoDetail: PhotoBrowserViewController) -> Bool
    func showBottomToolBar(in photoDetail: PhotoBrowserViewController) -> Bool
    func canSelectPhoto(in photoDetail: PhotoBrowserViewController) -> Bool
    func canEditPhoto(in photoDetail: PhotoBrowserViewController) -> Bool
    func canDisplayCaption(in photoDetail: PhotoBrowserViewController) -> Bool

    func photoDetail(_ photoDetail: PhotoBrowserViewController, scrollAt indexPath: IndexPath)
//    func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, selectedPhotos indexPaths: [IndexPath])
    func photoDetail(_ photoDetail: PhotoBrowserViewController, selectedAssets identifiers: [String])
    func photoDetail(_ photoDetail: PhotoBrowserViewController, didCompleteSelected photos: [PhotoProtocol])
}

public extension PhotoDetailCollectionViewControllerDelegate {
    func showNavigationBar(in photoDetail: PhotoBrowserViewController) -> Bool {
        true
    }
    func showBottomToolBar(in photoDetail: PhotoBrowserViewController) -> Bool {
        false
    }

    func canSelectPhoto(in photoDetail: PhotoBrowserViewController) -> Bool {
        false
    }
    func canEditPhoto(in photoDetail: PhotoBrowserViewController) -> Bool {
        false
    }
    func canDisplayCaption(in photoDetail: PhotoBrowserViewController) -> Bool {
        false
    }

    func photoDetail(_ photoDetail: PhotoBrowserViewController, scrollAt indexPath: IndexPath) {

    }
    func photoDetail(_ photoDetail: PhotoBrowserViewController, selectedAssets identifiers: [String]) {
        
    }
    func photoDetail(_ photoDetail: PhotoBrowserViewController, didCompleteSelected photos: [PhotoProtocol]) {

    }
}
