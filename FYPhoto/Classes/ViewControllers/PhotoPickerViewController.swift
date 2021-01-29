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

/// Option set of media types
public struct MediaOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let image = MediaOptions(rawValue: 1 << 0)
    public static let video = MediaOptions(rawValue: 1 << 1)
    
    public static let all: MediaOptions = [.image, .video]
}

/// PhotoPicker need be wrapped by NavigationController. Configure with set method.
public class PhotoPickerViewController: UICollectionViewController {
    // call back for photo, video selections
    public var selectedPhotos: (([SelectedImage]) -> Void)?
    public var selectedVideo: ((Result<SelectedVideo, Error>) -> Void)?
        
    var allPhotos: PHFetchResult<PHAsset>!
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
            updateSelectedAssetIsVideo(with: newValue)
            updateSelectedAssetsCount(with: newValue)
            reachedMaximum = newValue.count >= maximumCanBeSelected
            collectionView.reloadData()
        }
    }

    /// if true, unable to select more photos
    fileprivate var reachedMaximum: Bool = false

    internal let imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize!
    fileprivate var previousPreheatRect = CGRect.zero

    fileprivate lazy var bottomToolView: PhotoPickerBottomToolView = {
        let toolView = PhotoPickerBottomToolView(selectionLimit: maximumCanBeSelected)
        toolView.delegate = self
        return toolView
    }()
    
    var previewVC: PhotoBrowserViewController?
    
    fileprivate var selectedAssetIsVideo: Bool? = nil

    internal private(set) var fetchResult: PHFetchResult<PHAsset>! {
        willSet {
            if newValue != fetchResult, !willBatchUpdated {
                collectionView.reloadData()
            }
        }
    }
    
    var willBatchUpdated: Bool = false
    
    /// photo picker get the right authority to access photos
    var photosAuthorityPassed = false
    
    // photo
    fileprivate var maximumCanBeSelected: Int = 0
    
    // video
    fileprivate var videoMaximumDuration: TimeInterval?
    fileprivate var maximumVideoSize: Double?// MB
    fileprivate var compressedQuality: VideoCompressor.QualityLevel?
    fileprivate var moviePathExtension = "mp4"
    
    fileprivate let mediaOptions: MediaOptions
    
    /// Initialize PhotoPicker with media types: image, video or both. Use the setting method below to config it.
    /// - Parameter mediaTypes: image, video, both
    public init(mediaTypes: MediaOptions) {
        self.mediaOptions = mediaTypes
        let flowLayout = UICollectionViewFlowLayout()
        let screenSize = UIScreen.main.bounds.size
        let width = floor((screenSize.width - 5) / 3)
        flowLayout.itemSize = CGSize(width: width, height: width)
        flowLayout.minimumInteritemSpacing = 2.5
        flowLayout.minimumLineSpacing = 2.5
        flowLayout.scrollDirection = .vertical
        super.init(collectionViewLayout: flowLayout)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @discardableResult
    public func setMaximumPhotosCanBeSelected(_ maximum: Int) -> Self {
        self.maximumCanBeSelected = maximum
        return self
    }
    
    @discardableResult
    public func setMaximumVideoDuration(_ duration: Double) -> Self {
        self.videoMaximumDuration = duration
        return self
    }
    
    @discardableResult
    public func setMaximumVideoSizePerMB(_ size: Double,
                                         compressedQuality: VideoCompressor.QualityLevel = .AVAssetExportPreset640x480) -> Self {
        self.maximumVideoSize = size
        self.compressedQuality = compressedQuality
        return self
    }
    
    fileprivate var containsCamera: Bool = true
    
    @discardableResult
    public func setPickerWithCamera(_ containsCamera: Bool) -> Self {
        self.containsCamera = containsCamera
        return self
    }

    deinit {
        if photosAuthorityPassed {
            resetCachedAssets()
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
        }
    }
    
    // MARK: UIViewController / Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCollectionView()
        requestPhotoAuthority { (isSuccess) in
            if isSuccess {
                self.photosAuthorityPassed = true
//                self.setupCollectionView()
                self.requestAlbumsData()
                self.setupNavigationBar()
                self.setupBottomToolView()
                self.resetCachedAssets()
                PHPhotoLibrary.shared().register(self)
            } else {
                self.photosAuthorityPassed = false
                self.alertPhotosLibraryAuthorityError()
                // TODO: 😴zZ Can't use photo picker without authority
            }
        }
    }
    
    func requestPhotoAuthority(_ completion: @escaping (_ isSuccess: Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized, .limited:
                        completion(true)
                    case .denied, .restricted, .notDetermined:
                        completion(false)
                        print("⚠️ without authorization! ⚠️")
                    @unknown default:
                        fatalError()
                    }
                }
            }
        default:
            completion(false)
        }
        
    }
    
    func setupCollectionView() {
        collectionView.backgroundColor = .white

        collectionView.register(GridViewCell.self, forCellWithReuseIdentifier: String(describing: GridViewCell.self))
        collectionView.register(GridCameraCell.self, forCellWithReuseIdentifier: String(describing: GridCameraCell.self))
    }
    
    func requestAlbumsData() {
        allPhotos = PhotoPickerResource.shared.getAssets(withMediaOptions: mediaOptions)
        smartAlbums = PhotoPickerResource.shared.getSmartAlbums(withMediaOptions: mediaOptions)
        userCollections = PhotoPickerResource.shared.userCollection()
        
        fetchResult = allPhotos
        if #available(iOS 14, *) {
            if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
                let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") ?? ""
                let photosAuthorityRequestText = Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryUsageDescription")
                let title = "\(bundleName)" + "AccessPhotoLibraryTitle".photoTablelocalized
                PhotosAuthority.presentLimitedLibraryPicker(title: title, message: photosAuthorityRequestText as? String, from: self)
            }
        }
    }

    func alertPhotosLibraryAuthorityError() {
        let alert = UIAlertController(title: "AccessPhotosFailed".photoTablelocalized, message: "AccessPhotosFailedMessage".photoTablelocalized, preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "GoToSettings".photoTablelocalized, style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        let cancel = UIAlertAction(title: "Cancel".photoTablelocalized, style: .cancel) { _ in
            self.back()
        }
        alert.addAction(action)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard photosAuthorityPassed else { return }
        // Determine the size of the thumbnails to request from the PHCachingImageManager
        let scale = UIScreen.main.scale
        let cellSize = (collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)                
    }

    // MARK: -NavigationBar
    func setupNavigationBar() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".photoTablelocalized, style: .plain, target: self, action: #selector(backBarButton(_:)))
        // custom titleview
        customTitleView.tapped = { [weak self] in
            guard let self = self else { return }
            let albumsVC = AlbumsTableViewController(allPhotos: self.allPhotos,
                                                     smartAlbums: self.smartAlbums,
                                                     userCollections: self.userCollections,
                                                     selectedIndexPath: self.selectedAlbumIndexPath)
            albumsVC.delegate = self
            self.present(albumsVC, animated: true, completion: nil)
        }
        customTitleView.title = "AllPhotos".photoTablelocalized
        self.navigationItem.titleView = customTitleView
    }
    
    func setupBottomToolView() {
        view.addSubview(bottomToolView)
        bottomToolView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomToolView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            bottomToolView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            bottomToolView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            bottomToolView.heightAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    @objc func backBarButton(_ sender: UIBarButtonItem) {
        back()
    }
    
    fileprivate var selectedAssets: [PHAsset] {
        // The order of Assets fetched with identifiers maybe different from input identifiers order.
        let selectedFetchResults: [PHFetchResult<PHAsset>] = assetSelectionIdentifierCache.map {
            PHAsset.fetchAssets(withLocalIdentifiers: [$0], options: nil)
        }
        return selectedFetchResults.compactMap { $0.firstObject }
    }
    
    /// complete photo selection
    /// - Parameters:
    ///   - assets: selected assets
    ///   - animated: dissmiss animated
    func selectionCompleted(assets: [PHAsset], animated: Bool) {
        guard !assets.isEmpty else {
            return
        }
        
        PhotoPickerResource.shared.fetchHighQualityImages(assets) { images in
            var selectedArr = [SelectedImage]()
            for index in 0..<images.count {
                let asset = assets[index]
                let image = images[index]
                selectedArr.append(SelectedImage(asset: asset, image: image))
            }
            
            self.selectedPhotos?(selectedArr)
            self.back()
        }
    }

    func back() {
        // TODO: 😴zZ popup
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: UICollectionView

    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard photosAuthorityPassed else { return 0 }
        return containsCamera ? fetchResult.count + 1 : fetchResult.count
        // + 1, one cell for taking picture or video
    }
    
    /// Regenerate IndexPath whether the indexPath is for pure photos or not.
    ///
    /// CollectionView dataSource contains: photos fetchResult and a photo capture placeholder. Therefore, when calculating pure photo indexPath with fetchResult, we should
    /// set purePhotos true to minus one from the indexPath.
    /// - Parameters:
    ///   - indexPath: origin indexPath
    ///   - purePhotos: is this indexPath for pure photos browsing. If true, indexPath item minus one, else indexPath item plus one.
    /// - Returns: regenerated indexPath
    func regenerate(indexPath: IndexPath, for purePhotos: Bool) -> IndexPath {
        if containsCamera {
            let para = purePhotos ? -1 : 1
            return IndexPath(item: indexPath.item + para, section: indexPath.section)
        } else {
            return indexPath
        }
    }
    
    fileprivate func configureAssetCell(_ cell: GridViewCell, asset: PHAsset, at indexPath: IndexPath) {
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
                    cell.isVideoAsset = true
                } else {
                    cell.videoDuration = ""
                    if let isVideo = self.selectedAssetIsVideo {
                        cell.isEnable = !isVideo
                    } else {
                        cell.isEnable = true
                    }
                    cell.isVideoAsset = false
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
        if containsCamera {
            if indexPath.item == 0 {// camera
                return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: GridCameraCell.self), for: indexPath)
            } else {
                // Dequeue a GridViewCell.
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: GridViewCell.self), for: indexPath) as? GridViewCell {
                    let asset = fetchResult.object(at: regenerate(indexPath: indexPath, for: true).item)
                    configureAssetCell(cell, asset: asset, at: indexPath)
                    return cell
                }
            }
        } else {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: GridViewCell.self), for: indexPath) as? GridViewCell {
                let asset = fetchResult.object(at: regenerate(indexPath: indexPath, for: true).item)
                configureAssetCell(cell, asset: asset, at: indexPath)
                return cell
            }
        }
        return UICollectionViewCell()
    }

    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        lastSelectedIndexPath = indexPath
        if containsCamera {
            if indexPath.item == 0 { // camera
                launchCamera()
            } else {
                // due to the placeholder camera cell
                let fixedIndexPath = regenerate(indexPath: indexPath, for: true)
                let selectedAsset = fetchResult[fixedIndexPath.item]
                if selectedAsset.mediaType == .video {
                    browseVideoIfValid(selectedAsset)
                } else {
                    browseImages(at: fixedIndexPath)
                }
            }
        } else {
            let fixedIndexPath = regenerate(indexPath: indexPath, for: true)
            let selectedAsset = fetchResult[fixedIndexPath.item]
            if selectedAsset.mediaType == .video {
                browseVideoIfValid(selectedAsset)
            } else {
                browseImages(at: fixedIndexPath)
            }
        }
    }
    
    func browseImages(at indexPath: IndexPath) {
        var photos = [PhotoProtocol]()
        for index in 0..<fetchResult.count {
            let asset = fetchResult[index]
            photos.append(Photo.photoWithPHAsset(asset))
        }
        
        let selectedAssetsResult = selectedAssets
        let selectedPhotos = selectedAssetsResult.map { Photo.photoWithPHAsset($0) }

        let photoBrowser = PhotoBrowserViewController.create(photos: photos, initialIndex: indexPath.item, builder: { builder -> PhotoBrowserViewController.Builder in
            builder
                .buildForSelection(true)
                .setSelectedPhotos(selectedPhotos)
                .setMaximumCanBeSelected(self.maximumCanBeSelected)
                .buildThumbnailsForSelection()
                .buildNavigationBar()
                .buildBottomToolBar()
            
        })        

        photoBrowser.delegate = self
        self.navigationController?.fyphoto.push(photoBrowser, animated: true)
    }
    
    func browseVideoIfValid(_ asset: PHAsset) {
        guard asset.mediaType == .video else {
            return
        }
        guard validVideoDuration(asset) else {
            selectedVideo?(.failure(PhotoPickerError.VideoDurationTooLong))
            return
        }
        
        if let maximimVideoSize = maximumVideoSize {
            checkMemoryUsageFor(video: asset, limit: maximimVideoSize) { [weak self] (pass, url) in
                guard let self = self else { return }
                if pass {
                    self.browseVideo(asset)
                } else {
                    self.selectedVideo?(.failure(PhotoPickerError.VideoMemoryOutOfSize))
                }
            }
        } else {
            browseVideo(asset)
        }
    }
    
    func browseVideo(_ asset: PHAsset) {
        let videoPlayer = PlayVideoForSelectionViewController.playVideo(asset)
        videoPlayer.selectedVideo = { [weak self] url in
            guard let self = self else { return }
            if url.sizePerMB() <= 10 {
                let thumbnailImage = asset.getThumbnailImageSynchorously()
                let selectedVideo = SelectedVideo(url: url)
                selectedVideo.briefImage = thumbnailImage
                self.selectedVideo?(.success(selectedVideo))
                self.back()
            } else {
                self.compressVideo(url: url, asset: asset) { (result) in
                    switch result {
                    case .success(let url):
                        let thumbnailImage = asset.getThumbnailImageSynchorously()
                        let selectedVideo = SelectedVideo(url: url)
                        selectedVideo.briefImage = thumbnailImage
                        self.selectedVideo?(.success(selectedVideo))
                    case .failure(let error):
                        self.selectedVideo?(.failure(error))
                    }
                    self.back()
                }
            }
        }
        present(videoPlayer, animated: true, completion: nil)
    }
    
    fileprivate func browseVideo(url: URL, withAsset asset: PHAsset) {
        let videoPlayer = PlayVideoForSelectionViewController.playVideo(url)
        videoPlayer.selectedVideo = { [weak self] url in
            let thumbnailImage = asset.getThumbnailImageSynchorously()
            let selectedVideo = SelectedVideo(url: url)
            selectedVideo.briefImage = thumbnailImage
            self?.selectedVideo?(.success(selectedVideo))
        }
        present(videoPlayer, animated: true, completion: nil)
    }
    
    fileprivate func checkMemoryUsageFor(video: PHAsset, limit: Double, completion: @escaping (Bool, URL?) -> Void) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestAVAsset(forVideo: video, options: options) { (avasset, _, _) in
            DispatchQueue.main.async {
                guard let avURLAsset = avasset as? AVURLAsset else {
                    completion(false, nil)
                    return
                }
                let valid = self.validVideoSize(avURLAsset.url, by: limit)
                completion(valid, avURLAsset.url)
            }
        }
    }
    
    fileprivate func compressVideo(url: URL, asset: PHAsset, completion: @escaping ((Result<URL, Error>) -> Void)) {
        let quality = self.compressedQuality ?? .AVAssetExportPreset640x480
        VideoCompressor.compressVideo(url: url,
                                      quality: quality) { (result) in            
            switch result {
            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    fileprivate func validVideoDuration(_ asset: PHAsset) -> Bool {
        guard let maximumDuration = videoMaximumDuration else {
            return true
        }
        return asset.duration < maximumDuration
    }
    
    fileprivate func validVideoSize(_ url: URL, by limit: Double) -> Bool {
        guard url.isFileURL else {
            return false
        }
        return url.sizePerMB() <= limit
    }

    // MARK: UIScrollView
    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
         updateCachedAssets()
    }
    
    func launchCamera() {
        let cameraVC = CameraViewController()
        cameraVC.captureMode = mediaOptions
        cameraVC.videoMaximumDuration = videoMaximumDuration ?? 15
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

    func updateSelectedAssetIsVideo(with assetIdentifiers: [String]) {
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
    
    func updateSelectedAssetsCount(with assetIdentifiers: [String]) {
        bottomToolView.updateCount(assetIdentifiers.count)
    }
}

// MARK: - PhotoDetailCollectionViewControllerDelegate
extension PhotoPickerViewController: PhotoBrowserViewControllerDelegate {
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
    
    public func photoBrowser(_ photoBrowser: PhotoBrowserViewController, deletePhotoAtIndexWhenBrowsing index: Int) {
        assetSelectionIdentifierCache.remove(at: index)
    }
}

// MARK: - AlbumsTableViewControllerDelegate
extension PhotoPickerViewController: AlbumsTableViewControllerDelegate {
    func albumsTableViewController(_ albums: AlbumsTableViewController, didSelectPhassetAt indexPath: IndexPath) {
        self.selectedAlbumIndexPath = indexPath
        switch AlbumsTableViewController.Section(rawValue: indexPath.section)! {
        case .allPhotos:
            fetchResult = allPhotos
            customTitleView.title = "AllPhotos".photoTablelocalized
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
            if mediaOptions == .image {
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                fetchResult = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            } else if mediaOptions == .video {
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
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
        guard photosAuthorityPassed else { return }
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
            self.willBatchUpdated = changes.hasIncrementalChanges
            fetchResult = changes.fetchResultAfterChanges
            guard let collectionView = self.collectionView else { fatalError() }
            if changes.hasIncrementalChanges {
                let bias = self.containsCamera ? 1 : 0
                // If we have incremental diffs, animate them in the collection view.
                collectionView.performBatchUpdates({
                    // For indexes to make sense, updates must be in this order:
                    // delete, insert, reload, move
                    
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0 + bias, section: 0) }))
                    }
                    if let inserted = changes.insertedIndexes, inserted.count > 0 {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0 + bias, section: 0) }))
                    }
                    if let changed = changes.changedIndexes, changed.count > 0 {
                        collectionView.reloadItems(at: changed.map({ IndexPath(item: $0 + bias, section: 0) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
            } else {
                // Reload the collection view if incremental diffs are not available.
                collectionView.reloadData()
            }
            resetCachedAssets()
        }
    }
}

extension PhotoPickerViewController: PhotoPickerBottomToolViewDelegate {
    func bottomToolViewPreviewButtonClicked() {
        let photos = selectedAssets.map { Photo.photoWithPHAsset($0) }
        let photoBrowser = PhotoBrowserViewController.create(photos: photos, initialIndex: 0) {
            $0
                .setSelectedPhotos(photos)
                .buildNavigationBar()
                .showDeleteButtonForBrowser()
                .buildBottomToolBar()
        }
        photoBrowser.delegate = self
        self.navigationController?.delegate = nil
        self.navigationController?.pushViewController(photoBrowser, animated: true)
        self.previewVC = photoBrowser
    }
    
    func bottomToolViewDoneButtonClicked() {
        selectionCompleted(assets: selectedAssets, animated: true)
    }
}
