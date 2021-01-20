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
    
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, longPressedOnPhoto photo: PhotoProtocol)
}

public extension PhotoBrowserViewControllerDelegate {
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, scrollAt indexPath: IndexPath) { }
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, selectedAssets identifiers: [String]) { }
    func photoBrowser(_ photoDetail: PhotoBrowserViewController, didCompleteSelected photos: [PhotoProtocol]) { }
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, deletePhotoAtIndexWhenBrowsing index: Int) { }
}

public extension PhotoBrowserViewControllerDelegate {
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, longPressedOnPhoto photo: PhotoProtocol) {
        alertSavePhoto(photo, on: photoBrowser)
    }
    
    func alertSavePhoto(_ photo: PhotoProtocol, on viewController: UIViewController) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let actionTitle = photo.isVideo ? "SaveVideo".photoTablelocalized : "SavePhoto".photoTablelocalized
        let saveAction = UIAlertAction(title: actionTitle, style: .default) { (_) in
            self.savePhotoToLibrary(photo)
        }
        let cancelAction = UIAlertAction(title: "Cancel".photoTablelocalized, style: .cancel, handler: nil)
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    func savePhotoToLibrary(_ photo: PhotoProtocol) {
        // TODO: 😴zZ save photo to library
        
    }
    
    func saveImage(_ image: UIImage) {
        
    }
    
    func saveVideo(_ url: URL) {
        
    }
}
