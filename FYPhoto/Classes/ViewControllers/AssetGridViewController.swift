//
//  AssetGridViewController.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/7/15.
//

import UIKit

import UIKit
import Photos
import PhotosUI

public class AssetGridViewController: UICollectionViewController {

    public var selectedPhotos: (([UIImage]) -> Void)?

    var allPhotos: PHFetchResult<PHAsset>!
//    var smartAlbums: PHFetchResult<PHAssetCollection>!
    var smartAlbums: [PHAssetCollection]!
    var userCollections: PHFetchResult<PHCollection>!

    /// select all photos default, use in AlbumsTableViewController
    fileprivate var selectedAlbumIndexPath = IndexPath(row: 0, section: 0)

    /// Grid cell indexPath
    internal var lastSelectedIndexPath: IndexPath?

    fileprivate let customTitleView = CustomNavigationTitleView()

    /// identify selected assets
    fileprivate var assetSelectionIdentifierCache = [String]()
    /// for quick search selected assets
    fileprivate var assetSelctionIndexPaths = [IndexPath]() {
        willSet {
            let newAssets = newValue.map { fetchResult.object(at: $0.row).localIdentifier }
            assetSelectionIdentifierCache = newAssets
            updateNavigationBarItems(newValue)
            updateSelectedAssetIsVideo(newValue)
            isReachedMaximum = newValue.count >= maximumNumber
        }
    }

    /// if true, unable to select more photos
    fileprivate var isReachedMaximum: Bool = false {
        willSet {
            collectionView.reloadData()
        }
    }

    internal let imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize!
    fileprivate var previousPreheatRect = CGRect.zero

    fileprivate var selectedPhotoCountBarItem: UIBarButtonItem!
    fileprivate var doneBarItem: UIBarButtonItem!

    fileprivate var selectedAssetIsVideo: Bool? = nil

    internal var fetchResult: PHFetchResult<PHAsset>! {
        willSet {
            if newValue != fetchResult {
                collectionView.reloadData()
            }
        }
    }

    var transitionController: PhotoTransitionController?

    fileprivate let maximumNumber: Int
    fileprivate let isOnlyImages: Bool
    // MARK: - Init
    /// Initial of GridVC
    /// - Parameter photosLimit: You can choose the maximum number of photos
    /// - Parameter isOnlyImages: If TRUE, only display images, elsewise, display all media types on device
    public init(maximumToSelect: Int, isOnlyImages: Bool) {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 120, height: 120)
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1
        flowLayout.scrollDirection = .vertical
        self.maximumNumber = maximumToSelect
        self.isOnlyImages = isOnlyImages
        super.init(collectionViewLayout: flowLayout)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }    

    // MARK: UIViewController / Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
//        self.edgesForExtendedLayout = .all

        collectionView.backgroundColor = .white

        collectionView.register(GridViewCell.self, forCellWithReuseIdentifier: String(describing: GridViewCell.self))

        requestAlbumsData()

        initalFetchResult()

        setupNavigationBar()

        resetCachedAssets()

        setupTransitionController()

        PHPhotoLibrary.shared().register(self)
    }

    func requestAlbumsData() {
        if isOnlyImages {
            allPhotos = PhotoPickerResource.shared.allImages()
            smartAlbums = PhotoPickerResource.shared.filteredSmartAlbums(isOnlyImages)
        } else {
            allPhotos = PhotoPickerResource.shared.allAssets(false)
            smartAlbums = PhotoPickerResource.shared.filteredSmartAlbums()
        }
        userCollections = PhotoPickerResource.shared.userCollection()
    }

    func initalFetchResult() {
        fetchResult = allPhotos
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Determine the size of the thumbnails to request from the PHCachingImageManager
        let scale = UIScreen.main.scale
        let cellSize = (collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)

//        self.navigationController?.setNavigationBarHidden(false, animated: false)
//        self.navigationController?.setNavigationBarHidden(false, animated: animated)

        print("navigationBar in GRID VC : \(self.navigationController?.navigationBar)")
        if self.navigationController?.navigationBar.alpha == 0 {
//            self.navigationController?.navigationBar.alpha = 1
            print("alpha == 0")
        }
    }

    // MARK: -NavigationBar
    func setupNavigationBar() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(backBarButton(_:)))
        navigationItem.leftBarButtonItem?.tintColor = .black

        selectedPhotoCountBarItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        selectedPhotoCountBarItem.tintColor = .systemBlue

        doneBarItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(doneBarButton(_:)))
        doneBarItem.isEnabled = false
        doneBarItem.tintColor = .black

        navigationItem.rightBarButtonItems = [doneBarItem, selectedPhotoCountBarItem]

        if isOnlyImages {
            // custom titleview
            customTitleView.tapped = { [weak self] in
                guard let self = self else { return }
                let albumsVC = AlbumsTableViewController(allPhotos: self.allPhotos, smartAlbums: self.smartAlbums, userCollections: self.userCollections, selectedIndexPath: self.selectedAlbumIndexPath)
                albumsVC.delegate = self
                self.present(albumsVC, animated: true, completion: nil)
            }
            customTitleView.title = "All photos".photoTablelocalized
            self.navigationItem.titleView = customTitleView
        }
    }

    func setupTransitionController() {
        guard let navigationController = self.navigationController else { return }
        transitionController = PhotoTransitionController(navigationController: navigationController)
    }
    
    @objc func backBarButton(_ sender: UIBarButtonItem) {
        back()
    }

    @objc func doneBarButton(_ sender: UIBarButtonItem) {
        let selectedAssets = assetSelctionIndexPaths.map {
            fetchResult.object(at: $0.row)
        }
        selectionCompleted(assets: selectedAssets, animated: true)
    }

    /// Completion of photo picker
    /// - Parameters:
    ///   - assets: selected assets
    ///   - animated: dissmiss animated
    func selectionCompleted(assets: [PHAsset], animated: Bool) {
        back()
//        self.navigationController?.popViewController(animated: true)
        guard !assets.isEmpty else {
            return
        }
        PhotoPickerResource.shared.fetchHighQualityImages(assets) {
            self.selectedPhotos?($0)
        }
    }

    func back() {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    // MARK: UICollectionView

    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = fetchResult.object(at: indexPath.item)

        // Dequeue a GridViewCell.
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: GridViewCell.self), for: indexPath) as? GridViewCell
            else { fatalError("unexpected cell in collection view") }

        cell.delegate = self

        // Add a badge to the cell if the PHAsset represents a Live Photo.
        if asset.mediaSubtypes.contains(.photoLive) {
            cell.livePhotoBadgeImage = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
        }
        cell.indexPath = indexPath

        // Request an image for the asset from the PHCachingImageManager.
        cell.representedAssetIdentifier = asset.localIdentifier

        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, info in
            // The cell may have been recycled by the time this handler gets called;
            // set the cell's thumbnail image only if it's still showing the same asset.
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image
                if asset.mediaType == .video {
                    cell.videoDuration = PhotoPickerResource.shared.time(of: asset.duration)
                    if let isVideo = self.selectedAssetIsVideo {
                        cell.unableToTouch(!isVideo)
                    } else {
                        cell.unableToTouch(false)
                    }
                } else {
                    cell.videoDuration = ""
                    if let isVideo = self.selectedAssetIsVideo {
                        cell.unableToTouch(isVideo)
                    } else {
                        cell.unableToTouch(false)
                    }
                }
                if let exsist = self.assetSelectionIdentifierCache.firstIndex(of: asset.localIdentifier) {
                    cell.displayButtonTitle("\(exsist + 1)") // display selected asset order
                } else {
                    cell.displayButtonTitle("")
                }
                
                if self.isReachedMaximum {
                    if self.assetSelctionIndexPaths.contains(indexPath) {
                        cell.unableToTouch(false)
                    } else {
                        cell.unableToTouch(true)
                    }
                }
            }
        })
        return cell
    }

    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        lastSelectedIndexPath = indexPath

        var photos = [PhotoProtocol]()
        for index in 0..<fetchResult.count {
            let asset = fetchResult[index]
            photos.append(Photo(asset: asset))
        }
        let selectedAssets = assetSelctionIndexPaths.map {
            fetchResult.object(at: $0.row)
        }

        let selectedPhotos = selectedAssets.map { Photo(asset: $0) }

        // collectionview
        let detailVC = PhotoDetailCollectionViewController(frame: view.bounds, photos: photos, initialIndex: indexPath.row)
        detailVC.selectedPhotos = selectedPhotos
        detailVC.selectedPhotoIndexPaths = assetSelctionIndexPaths
        detailVC.maximumNumber = maximumNumber
        detailVC.delegate = self

        self.navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: UIScrollView
    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
         updateCachedAssets()
    }
}

extension AssetGridViewController: GridViewCellDelegate {
    func gridCell(_ cell: GridViewCell, buttonClickedAt indexPath: IndexPath, assetIdentifier: String) {
        if let exsist = assetSelctionIndexPaths.firstIndex(of: indexPath) {
            assetSelctionIndexPaths.remove(at: exsist)
        } else {
            assetSelctionIndexPaths.append(indexPath)
        }

        // update cell selection button
        if let added = assetSelctionIndexPaths.firstIndex(of: indexPath) {
            // button display the order number of selected photos
            cell.displayButtonTitle("\(added + 1)")
        } else {
            cell.displayButtonTitle("")
        }
        collectionView.reloadData()
    }

    func updateSelectedAssetIsVideo(_ selectedIndexPaths: [IndexPath]) {
        guard let index = selectedIndexPaths.first?.item else {
            selectedAssetIsVideo = nil
            return
        }
        selectedAssetIsVideo = fetchResult.object(at: index).mediaType == .video
    }

    func updateNavigationBarItems(_ selectedIndexPaths: [IndexPath]) {
        let assets = selectedIndexPaths.map {
            fetchResult.object(at: $0.row)
        }
        selectedPhotoCountBarItem.title = assets.count == 0 ? "" : "\(assets.count)"
        doneBarItem.isEnabled = assets.count > 0
    }

}

// MARK: - PhotoDetailCollectionViewControllerDelegate
extension AssetGridViewController: PhotoDetailCollectionViewControllerDelegate {
    public func showNavigationBar(in photoDetail: PhotoDetailCollectionViewController) -> Bool {
        true
    }

    public func showNavigationToolBar(in photoDetail: PhotoDetailCollectionViewController) -> Bool {
        true
    }

    public func canDisplayCaption(in photoDetail: PhotoDetailCollectionViewController) -> Bool {
        true
    }

    public func canSelectPhoto(in photoDetail: PhotoDetailCollectionViewController) -> Bool {
        return true
    }

    public func canEditPhoto(in photoDetail: PhotoDetailCollectionViewController) -> Bool {
        return false
    }

    public func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, scrollAt indexPath: IndexPath) {
        lastSelectedIndexPath = indexPath
    }

    public func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, selectedPhotos indexPaths: [IndexPath]) {
        assetSelctionIndexPaths = indexPaths
        collectionView.reloadData()
    }

    public func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, didCompleteSelected photos: [PhotoProtocol]) {
        let assets = photos.compactMap { $0.asset }
        selectionCompleted(assets: assets, animated: true)
    }
}

// MARK: - AlbumsTableViewControllerDelegate
extension AssetGridViewController: AlbumsTableViewControllerDelegate {
    func albumsTableViewController(_ albums: AlbumsTableViewController, didSelectPhassetAt indexPath: IndexPath) {
        self.selectedAlbumIndexPath = indexPath
        switch AlbumsTableViewController.Section(rawValue: indexPath.section)! {
        case .allPhotos:
            fetchResult = allPhotos
            customTitleView.title = "All photos".photoTablelocalized
        case .smartAlbums:
            let collection = smartAlbums[indexPath.row]
            fetchResult = PHAsset.fetchAssets(in: collection, options: nil)
            customTitleView.title = collection.localizedTitle ?? ""
        case .userCollections:
            let collection: PHCollection = userCollections.object(at: indexPath.row)
            guard let assetCollection = collection as? PHAssetCollection else {
                assertionFailure("Expected an asset collection.")
                return
            }
            customTitleView.title = collection.localizedTitle ?? ""
            fetchResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
        }
    }
}

// MARK: - Asset Caching
extension AssetGridViewController {
    fileprivate func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }

    fileprivate func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }

        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)

        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }

        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }

        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
            targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
            targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)

        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }

    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                    width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                    width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                      width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                      width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension AssetGridViewController: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {

        guard let changes = changeInstance.changeDetails(for: fetchResult)
            else { return }

        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            // Hang on to the new fetch result.
            fetchResult = changes.fetchResultAfterChanges
            if changes.hasIncrementalChanges {
                // If we have incremental diffs, animate them in the collection view.
                guard let collectionView = self.collectionView else { fatalError() }
                collectionView.performBatchUpdates({
                    // For indexes to make sense, updates must be in this order:
                    // delete, insert, reload, move
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let inserted = changes.insertedIndexes, inserted.count > 0 {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let changed = changes.changedIndexes, changed.count > 0 {
                        collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
            } else {
                // Reload the collection view if incremental diffs are not available.
                collectionView!.reloadData()
            }
            resetCachedAssets()
        }
    }
}

extension AssetGridViewController {
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
    }
}

//extension AssetGridViewController: PhotoDetailTransitionAnimatorDelegate {
//    public func transitionWillStart() {
//        guard let indexPath = lastSelectedIndexPath else { return }
//        collectionView.cellForItem(at: indexPath)?.isHidden = true
//    }
//
//    public func transitionDidEnd() {
//        guard let indexPath = lastSelectedIndexPath else { return }
//        collectionView.cellForItem(at: indexPath)?.isHidden = false
//    }
//
//    public func referenceImage() -> UIImage? {
//        guard let indexPath = lastSelectedIndexPath else { return nil }
//        guard let cell = collectionView.cellForItem(at: indexPath) as? GridViewCell else {
//            return nil
//        }
//        return cell.imageView.image
//    }
//
//    public func imageFrame() -> CGRect? {
//        guard
//            let lastSelected = lastSelectedIndexPath,
//            let cell = self.collectionView.cellForItem(at: lastSelected)
//        else {
//            return nil
//        }
//        return collectionView.convert(cell.frame, to: self.view)
//    }
//}
