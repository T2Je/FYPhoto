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

public class PhotoPickerViewController: UICollectionViewController {
    
    public var selectedPhotos: (([UIImage]) -> Void)?
    
    var allPhotos: PHFetchResult<PHAsset>!
//    var smartAlbums: PHFetchResult<PHAssetCollection>!
    var smartAlbums: [PHAssetCollection]!
    var userCollections: PHFetchResult<PHCollection>!

    /// select all photos default, used in AlbumsTableViewController
    fileprivate var selectedAlbumIndexPath = IndexPath(row: 0, section: 0)

    /// Grid cell indexPath
    internal var lastSelectedIndexPath: IndexPath?

    fileprivate let customTitleView = CustomNavigationTitleView()

    /// identify selected assets
    fileprivate var assetSelectionIdentifierCache = [String]() {
        willSet {
            updateSelectedAssetIsVideo(by: newValue)
            updateNavigationBarItems(by: newValue)
            reachedMaximum = newValue.count >= maximumCanBeSelected
            collectionView.reloadData()
        }
    }

    /// if true, unable to select more photos
    fileprivate var reachedMaximum: Bool = false

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

    fileprivate let maximumCanBeSelected: Int
    fileprivate let isOnlyImages: Bool
    
    // video
    fileprivate var videoMaximumDuration: TimeInterval = 15
    fileprivate var moviePathExtension = "mp4"
    // MARK: - Init
    /// Initial of GridVC
    /// - Parameter maximumCanBeSelected: You can selected the maximum number of photos
    /// - Parameter isOnlyImages: If TRUE, only display images, otherwise, display all media types on device
    public init(maximumCanBeSelected: Int, isOnlyImages: Bool) {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 120, height: 120)
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1
        flowLayout.scrollDirection = .vertical
        self.maximumCanBeSelected = maximumCanBeSelected
        self.isOnlyImages = isOnlyImages
        super.init(collectionViewLayout: flowLayout)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }    

    deinit {
        resetCachedAssets()
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // MARK: UIViewController / Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.backgroundColor = .white

        collectionView.register(GridViewCell.self, forCellWithReuseIdentifier: String(describing: GridViewCell.self))
        collectionView.register(GridCameraCell.self, forCellWithReuseIdentifier: String(describing: GridCameraCell.self))
        
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
            smartAlbums = PhotoPickerResource.shared.filteredSmartAlbums(isOnlyImage: true)
        } else {
            allPhotos = PhotoPickerResource.shared.allAssets(ascending: false)
            smartAlbums = PhotoPickerResource.shared.filteredSmartAlbums()
        }
        userCollections = PhotoPickerResource.shared.userCollection()
    }

    func initalFetchResult() {
        fetchResult = allPhotos
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Determine the size of the thumbnails to request from the PHCachingImageManager
        let scale = UIScreen.main.scale
        let cellSize = (collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.isToolbarHidden = true
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

    func setupTransitionController() {
        guard let navigationController = self.navigationController else { return }
        transitionController = PhotoTransitionController(navigationController: navigationController)
    }
    
    @objc func backBarButton(_ sender: UIBarButtonItem) {
        back()
    }

    @objc func doneBarButton(_ sender: UIBarButtonItem) {
        let selectedFetchResult: PHFetchResult<PHAsset> = PHAsset.fetchAssets(withLocalIdentifiers: assetSelectionIdentifierCache, options: nil)
        var assets = [PHAsset]()
        selectedFetchResult.enumerateObjects { (asset, _, _) in
            assets.append(asset)
        }
        selectionCompleted(assets: assets, animated: true)
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
        return fetchResult.count + 1 // one cell for taking picture or video
    }
    
    
    /// Regenerate IndexPath whether the indexPath is for pure photos or not.
    ///
    /// CollectionView dataSource contains: photos fetchResult and a photo capture placeholder. Therefore, when calculating pure photo indexPath with fetchResult, we should
    /// set purePhotos true to minus one from the indexPath.
    /// - Parameters:
    ///   - indexPath: origin indexPath
    ///   - purePhotos: is this indexPath for pure photos. If true, indexPath item minus one, else indexPath item plus one.
    /// - Returns: regenerated indexPath
    func regenerate(indexPath: IndexPath, for purePhotos: Bool) -> IndexPath {
        let para = purePhotos ? -1 : 1
        return IndexPath(item: indexPath.item + para, section: indexPath.section)
    }
    
    fileprivate func configureCell(_ cell: GridViewCell, at indexPath: IndexPath) {
        let asset = fetchResult.object(at: regenerate(indexPath: indexPath, for: true).item)
        
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
                        cell.isEnable = isVideo
                    } else {
                        cell.isEnable = true
                    }
                } else {
                    cell.videoDuration = ""
                    if let isVideo = self.selectedAssetIsVideo {
                        cell.isEnable = !isVideo
                    } else {
                        cell.isEnable = true
                    }
                }
                if let exsist = self.assetSelectionIdentifierCache.firstIndex(of: asset.localIdentifier) {
                    cell.displayButtonTitle("\(exsist + 1)") // display selected asset order
                } else {
                    cell.displayButtonTitle("")
                }
                
                if self.reachedMaximum {
                    if self.assetSelectionIdentifierCache.contains(asset.localIdentifier) {
                        cell.isEnable = true
                    } else {
                        cell.isEnable = false
                    }
                }
            }
        })
    }
    
    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {// camera
            return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: GridCameraCell.self), for: indexPath)
        } else {
            // Dequeue a GridViewCell.
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: GridViewCell.self), for: indexPath) as? GridViewCell {
                configureCell(cell, at: indexPath)
                return cell
            }
        }
        
        return UICollectionViewCell()
    }

    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        lastSelectedIndexPath = indexPath
        if indexPath.item == 0 { // camera
            launchCamera()
        } else {
            var photos = [PhotoProtocol]()
            for index in 0..<fetchResult.count {
                let asset = fetchResult[index]
    //            print("assert location: \(asset.location)")
//                photos.append(Photo(asset: asset))
                photos.append(Photo.photoWithPHAsset(asset))
            }

            var selectedPhotos: [PhotoProtocol] = []
            let selectedAssetsResult = PHAsset.fetchAssets(withLocalIdentifiers: assetSelectionIdentifierCache, options: nil)
            selectedAssetsResult.enumerateObjects { (asset, _, _) in
                let photo = Photo.photoWithPHAsset(asset)
                selectedPhotos.append(photo)
            }

            // collectionview
            let initialIndex = regenerate(indexPath: indexPath, for: true).item // due to the placeholder camera cell
            let photoBrowser = PhotoBrowserViewController.Builder(photos: photos, initialIndex: initialIndex)
                .buildForSelection(true)
                .setSelectedPhotos(selectedPhotos)
                .setMaximumCanBeSelected(maximumCanBeSelected)
                .supportThumbnails(true)
                .supportNavigationBar(true)
                .supportBottomToolBar(true)
                .build()
                        
            photoBrowser.delegate = self

            self.navigationController?.pushViewController(photoBrowser, animated: true)
        }
    }

    // MARK: UIScrollView
    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
         updateCachedAssets()
    }
    
    func launchCamera() {
        let cameraVC = CameraViewController()
        let captureModes = isOnlyImages ? [CameraViewController.CaptureMode.image] : [CameraViewController.CaptureMode.movie, CameraViewController.CaptureMode.image]
        cameraVC.captureModes = captureModes
        cameraVC.videoMaximumDuration = videoMaximumDuration
        cameraVC.moviePathExtension = moviePathExtension
        cameraVC.delegate = self
        cameraVC.modalPresentationStyle = .fullScreen
        self.present(cameraVC, animated: true, completion: nil)
    }
}

extension PhotoPickerViewController: GridViewCellDelegate {
    func gridCell(_ cell: GridViewCell, buttonClickedAt indexPath: IndexPath, assetIdentifier: String) {
        if let exsist = assetSelectionIdentifierCache.firstIndex(of: assetIdentifier) {
            assetSelectionIdentifierCache.remove(at: exsist)
        } else {
            assetSelectionIdentifierCache.append(assetIdentifier)
        }

        // update cell selection button
        if let added = assetSelectionIdentifierCache.firstIndex(of: assetIdentifier) {
            // button display the order number of selected photos
            cell.displayButtonTitle("\(added + 1)")
        } else {
            cell.displayButtonTitle("")
        }
        collectionView.reloadData()
    }

    func updateSelectedAssetIsVideo(by assetIdentifiers: [String]) {
        guard let first = assetIdentifiers.first else {
            selectedAssetIsVideo = nil
            return
        }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [first], options: nil)
        if let firstAsset = result.firstObject {
            selectedAssetIsVideo = firstAsset.mediaType == .video
        } else {
            selectedAssetIsVideo = nil
        }
    }

    func updateNavigationBarItems(by assetIdentifiers: [String]) {
        selectedPhotoCountBarItem.title = (assetIdentifiers.count == 0) ? "" : "\(assetIdentifiers.count)"
        doneBarItem.isEnabled = assetIdentifiers.count > 0
    }

}

// MARK: - PhotoDetailCollectionViewControllerDelegate
extension PhotoPickerViewController: PhotoBrowserViewControllerDelegate {
    public func showNavigationBar(in photoBrowser: PhotoBrowserViewController) -> Bool {
        true
    }

    public func showBottomToolBar(in photoBrowser: PhotoBrowserViewController) -> Bool {
        true
    }

    public func canDisplayCaption(in photoBrowser: PhotoBrowserViewController) -> Bool {
        true
    }

    public func canSelectPhoto(in photoBrowser: PhotoBrowserViewController) -> Bool {
        return true
    }

    public func canEditPhoto(in photoBrowser: PhotoBrowserViewController) -> Bool {
        return false
    }

    public func photoBrowser(_ photoBrowser: PhotoBrowserViewController, scrollAt indexPath: IndexPath) {
        lastSelectedIndexPath = regenerate(indexPath: indexPath, for: false)
    }

    public func photoBrowser(_ photoBrowser: PhotoBrowserViewController, selectedAssets identifiers: [String]) {
        assetSelectionIdentifierCache = identifiers
    }

    public func photoBrowser(_ photoBrowser: PhotoBrowserViewController, didCompleteSelected photos: [PhotoProtocol]) {
        let assets = photos.compactMap { $0.asset }
        selectionCompleted(assets: assets, animated: true)
    }
}

// MARK: - AlbumsTableViewControllerDelegate
extension PhotoPickerViewController: AlbumsTableViewControllerDelegate {
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
            if isOnlyImages {
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                fetchResult = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            } else {
                fetchResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
            }

        }
    }
}

// MARK: - Asset Caching
extension PhotoPickerViewController {
    fileprivate func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }

    fileprivate func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }
        guard fetchResult.count > 0 else {
            #if DEBUG
            print("❌ could't fetch any photo")
            #endif
            return
        }
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)

        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }

        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect)}
            .compactMap { indexPath -> PHAsset? in
            if indexPath.item == 0 {
                return nil
            } else {
                let index = indexPath.item - 1
                return fetchResult.object(at: index)
            }
        }
                
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .compactMap { indexPath -> PHAsset? in
                if indexPath.item == 0 {
                    return nil
                } else {
                    let index = indexPath.item - 1
                    return fetchResult.object(at: index)
                }
            }
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
extension PhotoPickerViewController: PHPhotoLibraryChangeObserver {
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
