//
//  PhotoDetailCollectionViewControllerDelegate.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/21.
//

import Foundation

public protocol PhotoBrowserViewControllerDelegate: class {
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, scrollAt indexPath: IndexPath)
//    func photoBrowser(_ photoBrowser: photoBrowserCollectionViewController, selectedPhotos indexPaths: [IndexPath])
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, selectedAssets identifiers: [String])
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, didCompleteSelected photos: [PhotoProtocol])
 
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, deletePhotoAtIndexWhenBrowsing index: Int)
}

public extension PhotoBrowserViewControllerDelegate {
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, scrollAt indexPath: IndexPath) { }
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, selectedAssets identifiers: [String]) { }
    func photoBrowser(_ photoDetail: PhotoBrowserViewController, didCompleteSelected photos: [PhotoProtocol]) { }
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, deletePhotoAtIndexWhenBrowsing index: Int) { }
}
