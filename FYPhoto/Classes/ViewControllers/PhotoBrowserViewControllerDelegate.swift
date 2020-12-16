//
//  PhotoDetailCollectionViewControllerDelegate.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/21.
//

import Foundation

public protocol PhotoBrowserViewControllerDelegate: class {
//    func showNavigationBar(in photoBrowser: PhotoBrowserViewController) -> Bool
//    func showBottomToolBar(in photoBrowser: PhotoBrowserViewController) -> Bool
//    func canSelectPhoto(in photoBrowser: PhotoBrowserViewController) -> Bool
//    func canEditPhoto(in photoBrowser: PhotoBrowserViewController) -> Bool
//    func canDisplayCaption(in photoBrowser: PhotoBrowserViewController) -> Bool

    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, scrollAt indexPath: IndexPath)
//    func photoBrowser(_ photoBrowser: photoBrowserCollectionViewController, selectedPhotos indexPaths: [IndexPath])
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, selectedAssets identifiers: [String])
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, didCompleteSelected photos: [PhotoProtocol])
}

public extension PhotoBrowserViewControllerDelegate {
//    func showNavigationBar(in photoBrowser: PhotoBrowserViewController) -> Bool {
//        true
//    }
//    func showBottomToolBar(in photoBrowser: PhotoBrowserViewController) -> Bool {
//        false
//    }
//
//    func canSelectPhoto(in photoBrowser: PhotoBrowserViewController) -> Bool {
//        false
//    }
//    func canEditPhoto(in photoBrowser: PhotoBrowserViewController) -> Bool {
//        false
//    }
//    func canDisplayCaption(in photoBrowser: PhotoBrowserViewController) -> Bool {
//        false
//    }

    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, scrollAt indexPath: IndexPath) {

    }
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, selectedAssets identifiers: [String]) {
        
    }
    func photoBrowser(_ photoDetail: PhotoBrowserViewController, didCompleteSelected photos: [PhotoProtocol]) {

    }
}
