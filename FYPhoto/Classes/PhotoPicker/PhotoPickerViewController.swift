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


/// A picker that manages the custom interfaces for choosing assets from the user's photos library and delivers the results of those interactions to closures. Presents picker should be better.
///
/// Initializes new picker with the `configuration` the picker should use.
/// PhotoPickerViewController is intended to be used as-is and does not support subclassing
public final class PhotoPickerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    // call back for photo, video selections
    public var selectedPhotos: (([SelectedImage]) -> Void)?
    public var selectedVideo: ((Result<SelectedVideo, Error>) -> Void)?
    
    var allPhotos: PHFetchResult<PHAsset> = PHFetchResult()
    var smartAlbums: [PHAssetCollection] = []
    var userCollections: PHFetchResult<PHCollection> = PHFetchResult()

    /// select all photos default, used in AlbumsTableViewController
    fileprivate var selectedAlbumIndexPath = IndexPath(row: 0, section: 0)

    /// Grid cell indexPath
    internal var lastSelectedIndexPath: IndexPath?

    fileprivate lazy var topBar: PhotoPickerTopBar = {
        let bar = PhotoPickerTopBar(colorStyle: configuration.colorConfiguration.topBarColor,
                                    safeAreaInsetsTop: safeAreaInsets.top)
        return bar
    }()

    /// identify selected assets
    fileprivate var assetSelectionIdentifierCache = [String]() {
        didSet {
            updateSelectedAssetIsVideo(with: assetSelectionIdentifierCache)
            updateSelectedAssetsCount(with: assetSelectionIdentifierCache)
            updateVisibleCells(with: assetSelectionIdentifierCache)
            reachedMaximum = assetSelectionIdentifierCache.count >= maximumCanBeSelected
//            collectionView.reloadData()
        }
    }

    var safeAreaInsets: UIEdgeInsets {
        return UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
    }
    
    /// if true, unable to select more photos
    fileprivate var reachedMaximum: Bool = false

    internal let imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize = .zero
    fileprivate var previousPreheatRect = CGRect.zero

    fileprivate lazy var bottomToolBar: PhotoPickerBottomToolView = {
        let toolView = PhotoPickerBottomToolView(selectionLimit: maximumCanBeSelected,
                                                 colorStyle: configuration.colorConfiguration.pickerBottomBarColor,
                                                 safeAreaInsetsBottom: safeAreaInsets.bottom)
        toolView.delegate = self
        return toolView
    }()
    
    fileprivate var selectedAssetIsVideo: Bool? = nil {
        willSet {
            if newValue != selectedAssetIsVideo {
                reloadVisibleVideoCellsState()
            }
        }
    }
    
    /// assets in current album
    private(set) var assets: PHFetchResult<PHAsset> = PHFetchResult() {
        didSet {
            if assets != oldValue, !willBatchUpdated {
                collectionView.reloadData()
            }
        }
    }
    
    var willBatchUpdated: Bool = false
    
    // authority params
    /// photo picker get the right authority to access photos
    var photosAuthorityPassed: Bool?
    var isAuthorityErrorAlerted = false
    /// appears from camera dimissing
    var willDismiss = false
    
    fileprivate var containsCamera: Bool {
        configuration.supportCamera
    }
    
    // photo
    fileprivate var maximumCanBeSelected: Int {
        if configuration.selectionLimit == 0 {
            return allPhotos.count
        } else {
            return configuration.selectionLimit
        }
    }
    
    // video
    fileprivate var videoMaximumDuration: TimeInterval? {
        configuration.maximumVideoDuration
    }
    
    fileprivate var maximumVideoSize: Double? {
        configuration.maximumVideoMemorySize
    }
    fileprivate var compressedQuality: VideoCompressor.QualityLevel? {
        configuration.compressedQuality
    }
    fileprivate var moviePathExtension: String {
        configuration.moviePathExtension
    }
    
    fileprivate var mediaOptions: MediaOptions {
        configuration.mediaFilter
    }
    
    /// single selection has different interactions
    fileprivate var isSingleSelection: Bool {
        configuration.selectionLimit == 1
    }
    
    private(set) var configuration: FYPhotoPickerConfiguration
        
    let collectionView: UICollectionView
    
    private init() {
        self.configuration = FYPhotoPickerConfiguration()
        let flowLayout = UICollectionViewFlowLayout()
        let screenSize = UIScreen.main.bounds.size
        let width = floor((screenSize.width - 5) / 3)
        flowLayout.itemSize = CGSize(width: width, height: width)
        flowLayout.minimumInteritemSpacing = 2.5
        flowLayout.minimumLineSpacing = 2.5
        flowLayout.scrollDirection = .vertical
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        super.init(nibName: nil, bundle: nil)
    }
    
    /// Initializes new picker with the `configuration` the picker should use.
    public convenience init(configuration: FYPhotoPickerConfiguration) {
        self.init()
        self.configuration = configuration
    }
    
    /// Initialize PhotoPicker with media types: image, video or both. Use the setting method below to config it.
    /// - Parameter mediaTypes: image, video, both
    @available(swift, deprecated: 1.1.0, message: "Use init(configuration:) instead")
    public convenience init(mediaTypes: MediaOptions) {
        self.init()
        configuration.filterdMedia = mediaTypes
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @available(swift, deprecated: 1.1.0, message: "Use configuration instead")
    @discardableResult
    public func setMaximumPhotosCanBeSelected(_ maximum: Int) -> Self {
        configuration.selectionLimit = maximum
        return self
    }
    
    @available(swift, deprecated: 1.1.0, message: "Use configuration instead")
    @discardableResult
    public func setMaximumVideoDuration(_ duration: Double) -> Self {
        configuration.maximumVideoDuration = duration
        return self
    }
    
    @available(swift, deprecated: 1.1.0, message: "Use configuration instead")
    @discardableResult
    public func setMaximumVideoSizePerMB(_ size: Double,
                                         compressedQuality: VideoCompressor.QualityLevel = .AVAssetExportPreset640x480) -> Self {
        configuration.maximumVideoMemorySize = size
        configuration.compressedQuality = compressedQuality
        return self
    }
    
    @available(swift, deprecated: 1.1.0, message: "Use configuration instead")
    @discardableResult
    public func setPickerWithCamera(_ containsCamera: Bool) -> Self {
        configuration.supportCamera = containsCamera
        return self
    }

    deinit {
        if let isPassed = photosAuthorityPassed, isPassed {
            resetCachedAssets()
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
        }
    }
    
    // MARK: UIViewController / Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.addSubViews()
        self.setupSubViews()
        PhotosAuthority.requestPhotoAuthority { (isSuccess) in
            if isSuccess {
                self.photosAuthorityPassed = true
                self.thumbnailSize = self.calculateThumbnailSize()
                self.requestAlbumsData()
                self.resetCachedAssets()
                PHPhotoLibrary.shared().register(self)
            } else {
                self.photosAuthorityPassed = false
            }
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !willDismiss else {
            return
        }
        if let isPassed = photosAuthorityPassed {
            if !isPassed, !isAuthorityErrorAlerted {
                self.alertPhotosLibraryAuthorityError()
            } else {
                thumbnailSize = calculateThumbnailSize()
                alertLimitedStatus()
            }
        }
    }
    
    func alertLimitedStatus() {
        if #available(iOS 14, *) {
            if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
                let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") ?? ""
                let message = Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryUsageDescription") as? String
                let title = "\(bundleName)" + L10n.accessPhotoLibraryTitle
                PhotosAuthority.presentLimitedLibraryPicker(title: title, message: message, from: self)
            }
        }
    }
    
    func requestAlbumsData() {
        allPhotos = PhotoPickerResource.shared.getAssets(withMediaOptions: mediaOptions)
        smartAlbums = PhotoPickerResource.shared.getSmartAlbums(withMediaOptions: mediaOptions)
        userCollections = PhotoPickerResource.shared.userCollection()
        
        assets = allPhotos
    }

    func alertPhotosLibraryAuthorityError() {
        let alert = UIAlertController(title: L10n.accessPhotosFailed,
                                      message: L10n.accessPhotosFailedMessage,
                                      preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: L10n.goToSettings, style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                self.back()
                return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            self.back()
        }
        let cancel = UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
            if !self.containsCamera {
                self.back()
            }
        }
        alert.addAction(action)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: {
            self.isAuthorityErrorAlerted = true
        })
    }
    
    func calculateThumbnailSize() -> CGSize {
        // Determine the size of the thumbnails to request from the PHCachingImageManager
        let scale = UIScreen.main.scale
        let cellSize = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize ?? CGSize(width: 110, height: 110)
        return CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
    }

    // MARK: -NavigationBar
    func setupSubViews() {
        setupNavigationBar()
        setupCollectionView()
    }
    
    func setupNavigationBar() {
        // custom titleview
        topBar.dismiss = { [weak self] in
            self?.back()
        }
        topBar.albulmTitleTapped = { [weak self] in
            guard let self = self else { return }
            let albumsVC = AlbumsTableViewController(allPhotos: self.allPhotos,
                                                     smartAlbums: self.smartAlbums,
                                                     userCollections: self.userCollections,
                                                     selectedIndexPath: self.selectedAlbumIndexPath)
            albumsVC.delegate = self
            self.present(albumsVC, animated: true, completion: nil)
        }
        topBar.setTitle(L10n.allPhotos)
    }
    
    func setupCollectionView() {
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(GridViewCell.self, forCellWithReuseIdentifier: GridViewCell.reuseIdentifier)
        collectionView.register(GridCameraCell.self, forCellWithReuseIdentifier: GridCameraCell.reuseIdentifier)
    }
    
    func addSubViews() {
        view.addSubview(topBar)
        view.addSubview(collectionView)
        view.addSubview(bottomToolBar)
        
        let safeArea = self.view.safeAreaLayoutGuide
        topBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: safeAreaInsets.top + 44),
            topBar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor)
        ])
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: self.topBar.bottomAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.bottomToolBar.topAnchor)
        ])
        
        bottomToolBar.translatesAutoresizingMaskIntoConstraints = false
        let height: CGFloat = safeAreaInsets.bottom + 45
        NSLayoutConstraint.activate([
            bottomToolBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            bottomToolBar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            bottomToolBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            bottomToolBar.heightAnchor.constraint(equalToConstant: height)
        ])
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
            
            self.back {
                self.selectedPhotos?(selectedArr)
            }
        }
    }

    func back(_ completion: (() -> Void)? = nil) {
        self.dismiss(animated: true, completion: {
            completion?()
        })
    }

    // MARK: UICollectionView Delegate

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if containsCamera {
            // one cell for taking picture or video
            if let isPassed = photosAuthorityPassed, isPassed {
                return assets.count + 1
            } else {
                return 1
            }
        } else {
            return assets.count
        }
    }
    
    /// Regenerate IndexPath whether the indexPath is for pure photos or not.
    ///
    /// CollectionView dataSource contains: photos fetchResult and a photo capture placeholder. Therefore, when calculating pure photo indexPath with fetchResult, we should
    /// set purePhotos true to minus one from the indexPath.
    /// - Parameters:
    ///   - indexPath: origin indexPath
    ///   - purePhotos: is this indexPath for pure photos browsing. If true, indexPath item minus one, else indexPath item plus one.
    /// - Returns: regenerated indexPath
    func regenerate(indexPath: IndexPath, if containsCamera: Bool) -> IndexPath {
        if containsCamera {
            return IndexPath(item: indexPath.item - 1, section: indexPath.section)
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

        cell.selectionButtonBackgroundColor = configuration.colorConfiguration.selectionBackgroudColor
        cell.selectionButtonTitleColor = configuration.colorConfiguration.selectionTitleColor
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFit, options: options, resultHandler: { image, info in
            // The cell may have been recycled by the time this handler gets called;
            // set the cell's thumbnail image only if it's still showing the same asset.
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image
                self.setupCell(cell, asset: asset)
            }
        })
    }
    
    func setupCell(_ cell: GridViewCell, asset: PHAsset) {
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
        if !self.isSingleSelection {
            if let exsist = self.assetSelectionIdentifierCache.firstIndex(of: asset.localIdentifier) {
                cell.updateSelectionButtonTitle("\(exsist + 1)", false) // display selected asset order
            } else {
                cell.updateSelectionButtonTitle("", false)
            }
        } else {
            // hide multiple usage views
            cell.hideUselessViewsForSingleSelection(true)
        }
        
        if self.reachedMaximum {
            if self.assetSelectionIdentifierCache.contains(asset.localIdentifier) {
                cell.isEnable = true
            } else {
                cell.isEnable = false
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if containsCamera {
            if indexPath.item == 0 {// camera
                return collectionView.dequeueReusableCell(withReuseIdentifier: GridCameraCell.reuseIdentifier, for: indexPath)
            } else {
                // Dequeue a GridViewCell.
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GridViewCell.reuseIdentifier, for: indexPath) as? GridViewCell {
                    let asset = assets.object(at: regenerate(indexPath: indexPath, if: containsCamera).item)
                    configureAssetCell(cell, asset: asset, at: indexPath)
                    return cell
                }
            }
        } else {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GridViewCell.reuseIdentifier, for: indexPath) as? GridViewCell {
                let asset = assets.object(at: regenerate(indexPath: indexPath, if: containsCamera).item)
                configureAssetCell(cell, asset: asset, at: indexPath)
                return cell
            }
        }
        return UICollectionViewCell()
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        lastSelectedIndexPath = indexPath
        if containsCamera {
            if indexPath.item == 0 { // camera
                launchCamera()
            } else {
                // due to the placeholder camera cell
                let indexPathWithoutCamera = regenerate(indexPath: indexPath, if: containsCamera)
                let selectedAsset = assets[indexPathWithoutCamera.item]
                if selectedAsset.mediaType == .video {
                    browseVideoIfValid(selectedAsset)
                } else {
                    if isSingleSelection {
                        completeSingleSelection(at: indexPath)
                    } else {
                        browseImages(at: indexPathWithoutCamera)
                    }
                }
            }
        } else {
            let indexPathWithoutCamera = regenerate(indexPath: indexPath, if: containsCamera)
            let selectedAsset = assets[indexPathWithoutCamera.item]
            if selectedAsset.mediaType == .video {
                browseVideoIfValid(selectedAsset)
            } else {
                if isSingleSelection {
                    completeSingleSelection(at: indexPath)
                } else {
                    browseImages(at: indexPathWithoutCamera)
                }
            }
        }
    }
    
    
    // Single selection just return selected image without entering PhotoBrowser
    func completeSingleSelection(at indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? GridViewCell,
              let identifier = cell.representedAssetIdentifier
        else { return }
        
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        if let first = assets.firstObject {
            selectionCompleted(assets: [first], animated: true)
        }
    }
    
    func browseImages(at indexPath: IndexPath) {
        var photos = [PhotoProtocol]()
        for index in 0..<assets.count {
            let asset = assets[index]
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
        photoBrowser.colorConfiguration = configuration.colorConfiguration
        photoBrowser.delegate = self
        let navi = UINavigationController(rootViewController: photoBrowser)
        navi.modalPresentationStyle = .fullScreen
        self.fyphoto.present(navi, animated: true, completion: nil) { [weak self] (page) -> TransitionEssential? in
            guard let self = self else { return nil }
            let itemInPhotoPicker = self.containsCamera ? page + 1 : page
            let indexPath = IndexPath(item: itemInPhotoPicker, section: 0)
            self.lastSelectedIndexPath = indexPath
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? GridViewCell else {
                return nil
            }
            let rect = cell.convert(cell.bounds, to: self.view)
            
            return TransitionEssential(transitionImage: cell.imageView.image, convertedFrame: rect)
        }
//        self.navigationController?.fyphoto.push(photoBrowser, animated: true)
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
                
                self.back {
                    self.selectedVideo?(.success(selectedVideo))
                }
            } else {
                self.compressVideo(url: url, asset: asset) { [weak self] (result) in
                    guard let self = self else { return }
                    switch result {
                    case .success(let url):
                        self.back {
                            let thumbnailImage = asset.getThumbnailImageSynchorously()
                            let selectedVideo = SelectedVideo(url: url)
                            selectedVideo.briefImage = thumbnailImage
                            self.selectedVideo?(.success(selectedVideo))
                        }
                    case .failure(let error):
                        self.selectedVideo?(.failure(error))
                    }
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
    
    func launchCamera() {
        let cameraVC = CameraViewController(tintColor: configuration.colorConfiguration.topBarColor.itemTintColor)
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
        collectionView.reloadItems(at: [indexPath])
        
        if let exsist = assetSelectionIdentifierCache.firstIndex(of: assetIdentifier) {
            assetSelectionIdentifierCache.remove(at: exsist)
        } else {
            assetSelectionIdentifierCache.append(assetIdentifier)
        }
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
        bottomToolBar.updateCount(assetIdentifiers.count)
    }
    
    // MARK: Reload Visible Cells
    func updateVisibleCells(with identifiers: [String]) {
        let cells = collectionView.visibleCells.compactMap{ $0 as? GridViewCell }.filter { $0.indexPath != nil }
        for cell in cells {
            let asset = assets.object(at: regenerate(indexPath: cell.indexPath!, if: containsCamera).item)
            setupCell(cell, asset: asset)
        }
    }
    
    func reloadVisibleVideoCellsState() {
        let visibleVideoCellIndexPaths = collectionView.visibleCells.compactMap{ $0 as? GridViewCell }.filter { $0.isVideoAsset }.compactMap { $0.indexPath }
        collectionView.reloadItems(at: visibleVideoCellIndexPaths)
    }

}

// MARK: - PhotoDetailCollectionViewControllerDelegate
extension PhotoPickerViewController: PhotoBrowserViewControllerDelegate {
    public func photoBrowser(_ photoBrowser: PhotoBrowserViewController, scrollAt indexPath: IndexPath) {
        let itemFromBrowser = indexPath.item
        let itemInPhotoPicker = containsCamera ? itemFromBrowser - 1 : itemFromBrowser
        lastSelectedIndexPath = IndexPath(item: itemInPhotoPicker, section: 0)
    }

    public func photoBrowser(_ photoBrowser: PhotoBrowserViewController, selectedAssets identifiers: [String]) {
        assetSelectionIdentifierCache = identifiers
    }

    public func photoBrowser(_ photoBrowser: PhotoBrowserViewController, didCompleteSelected photos: [PhotoProtocol]) {
        let assets = photos.compactMap { $0.asset }
        photoBrowser.dismiss(animated: true) {
            self.selectionCompleted(assets: assets, animated: true)
        }
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
            assets = allPhotos
            topBar.setTitle(L10n.allPhotos)
        case .smartAlbums:
            let collection = smartAlbums[indexPath.row]
            assets = PHAsset.fetchAssets(in: collection, options: nil)
            topBar.setTitle(collection.localizedTitle ?? "")
        case .userCollections:
            let collection: PHCollection = userCollections.object(at: indexPath.row)
            guard let assetCollection = collection as? PHAssetCollection else {
                assertionFailure("Expected an asset collection.")
                return
            }
            topBar.setTitle(collection.localizedTitle ?? "")
            if mediaOptions == .image {
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            } else if mediaOptions == .video {
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
                assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            } else {
                assets = PHAsset.fetchAssets(in: assetCollection, options: nil)
            }
        }
    }
}

// MARK: - Asset Caching
extension PhotoPickerViewController: UIScrollViewDelegate {
    // MARK: UIScrollView
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
         updateCachedAssets()
    }
    
    fileprivate func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }

    fileprivate func updateCachedAssets() {
        guard let isPassed = photosAuthorityPassed, isPassed else { return }
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }
        guard assets.count > 0 else {
            #if DEBUG
            print("❌ could't fetch any photo")
            #endif
            return
        }
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)

        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect)}
            .compactMap { indexPath -> PHAsset? in
            if indexPath.item == 0 {
                return nil
            } else {
                let index = indexPath.item - 1
                return assets.object(at: index)
            }
        }
                
        let removedAssets = removedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .compactMap { indexPath -> PHAsset? in
                if indexPath.item == 0 {
                    return nil
                } else {
                    let index = indexPath.item - 1
                    return assets.object(at: index)
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

        guard let changes = changeInstance.changeDetails(for: assets)
            else { return }

        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            // Hang on to the new fetch result.
            self.willBatchUpdated = changes.hasIncrementalChanges
            assets = changes.fetchResultAfterChanges
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
                        self.collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
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
        let navi = UINavigationController(rootViewController: photoBrowser)
        self.present(navi, animated: true, completion: nil)
    }
    
    func bottomToolViewDoneButtonClicked() {
        self.selectionCompleted(assets: self.selectedAssets, animated: true)
    }
}
