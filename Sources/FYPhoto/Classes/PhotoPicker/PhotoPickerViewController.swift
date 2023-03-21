//
//  AssetGridViewController.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/7/15.
//

import UIKit

import Photos
import PhotosUI
import FYVideoCompressor

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

/// A picker that manages the custom interfaces for choosing assets from the user's photos library and
/// delivers the results of those interactions to closures. Presents picker should be better.
///
/// Initializes new picker with the `configuration` the picker should use.
/// PhotoPickerViewController is intended to be used as-is and does not support subclassing
/// Support dark mode for devices running iOS 13 or above. Customize color with FYColorConfiguration.
public final class PhotoPickerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    static let topBarHeight: CGFloat = 44
    static let bottomBarHeight: CGFloat = 45

    // call back for photo, video selections
    public var selectedPhotos: (([SelectedImage]) -> Void)?
    public var selectedVideo: ((Result<SelectedVideo, Error>) -> Void)?
    
    public weak var cameraDelegate: CameraViewControllerDelegate?
    public weak var watermarkDelegate: WatermarkDelegate?
    public weak var watermarkDataSource: WatermarkDataSource?

    var allPhotos: PHFetchResult<PHAsset> = PHFetchResult()
    var smartAlbums: [PHAssetCollection] = []
    var userCollections: PHFetchResult<PHAssetCollection> = PHFetchResult()

    /// select all photos default, used in AlbumsTableViewController
    fileprivate var selectedAlbumIndexPath = IndexPath(row: 0, section: 0)

    /// Grid cell indexPath
    internal var lastSelectedIndexPath: IndexPath?

    fileprivate lazy var topBar: PhotoPickerTopBar = {
        let bar = PhotoPickerTopBar(colorStyle: configuration.colorConfiguration.topBarColor,
                                    safeAreaInsetsTop: safeAreaInsets.top)
        return bar
    }()

    fileprivate lazy var bottomToolBar: PhotoPickerBottomToolView = {
        let toolView = PhotoPickerBottomToolView(selectionLimit: maximumCanBeSelected,
                                                 colorStyle: configuration.colorConfiguration.pickerBottomBarColor,
                                                 safeAreaInsetsBottom: safeAreaInsets.bottom)
        toolView.delegate = self
        return toolView
    }()

    /// identify selected assets
    fileprivate var assetSelectionIdentifierCache = [String]() {
        didSet {
            updateSelectedAssetIsVideo(with: assetSelectionIdentifierCache)
            updateSelectedAssetsCount(with: assetSelectionIdentifierCache)
            updateVisibleCells(with: assetSelectionIdentifierCache)
        }
    }

    fileprivate var selectedAssets: [PHAsset] {
        // The order of Assets fetched with identifiers maybe different from input identifiers order.
        let selectedFetchResults: [PHFetchResult<PHAsset>] = assetSelectionIdentifierCache.map {
            PHAsset.fetchAssets(withLocalIdentifiers: [$0], options: nil)
        }
        return selectedFetchResults.compactMap { $0.firstObject }
    }

    private var safeAreaInsets: UIEdgeInsets {
        return UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
    }

    internal let imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize = .zero
    fileprivate var previousPreheatRect = CGRect.zero

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
    var photosAuthorityPassed: Bool = false
    var isAuthorityErrorAlerted = false
    /// appears from camera dimissing
    var willDismiss = false

    var hasAlertedLimited = false

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
    fileprivate var maximumVideoDuration: TimeInterval {
        configuration.maximumVideoDuration
    }

    fileprivate var maximumVideoSize: Double {
        configuration.maximumVideoMemorySize
    }
    fileprivate var compressedQuality: FYVideoCompressor.VideoQuality {
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

    fileprivate var hasMemorySizeLimit: Bool {
        return maximumVideoSize > 0
    }

    /// save edited photos in PhotoBrowser
    var editedPhotos: [String: CroppedRestoreData] = [:]

    private(set) var configuration: FYPhotoPickerConfiguration

    let videoValidator: VideoValidatorProtocol = FYVideoValidator()
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

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemGroupedBackground
        } else {
            view.backgroundColor = .white
        }

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
        if PHPhotoLibrary.authorizationStatus() != .notDetermined {
            // app is installed on device for the first time, the photos authority is not determined,
            // so there is no need to show custom alert controller.
            if photosAuthorityPassed {
                thumbnailSize = calculateThumbnailSize()
                alertPhotoLibraryLimitedAuthority()
            } else {
                if !isAuthorityErrorAlerted {
                    self.alertPhotosLibraryAuthorityError()
                }
            }
        }
    }
    var isCollectionViewContentInsetSet = false

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isCollectionViewContentInsetSet {
            isCollectionViewContentInsetSet = true
            let insets = self.view.safeAreaInsets
            let collectionTopInset = PhotoPickerViewController.topBarHeight
            let collectionBottomInset = PhotoPickerViewController.bottomBarHeight + insets.bottom

            collectionView.contentInset = UIEdgeInsets(top: collectionTopInset, left: 0, bottom: collectionBottomInset, right: 0)
        }
    }

    func alertPhotoLibraryLimitedAuthority() {
        if #available(iOS 14, *) {
            if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited && !hasAlertedLimited {
                let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") ?? ""
                let message = Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryUsageDescription") as? String
                let title = "\(bundleName)" + L10n.accessPhotoLibraryTitle
                PhotosAuthority.presentLimitedLibraryPicker(title: title, message: message, from: self)
                hasAlertedLimited = true
            }
        }
    }

    func requestAlbumsData() {
        allPhotos = PhotoPickerResource.shared.recentAssetsWith(mediaOptions)
        smartAlbums = PhotoPickerResource.shared.smartAlbumsWith(mediaOptions)
        userCollections = PhotoPickerResource.shared.userCollection()

        assets = allPhotos
    }

    func alertPhotosLibraryAuthorityError() {
        let alert = UIAlertController(title: L10n.accessPhotosFailed,
                                      message: L10n.accessPhotosFailedMessage,
                                      preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: L10n.goToSettings, style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                self.back(animated: true)
                return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            self.back(animated: true)
        }
        let cancel = UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
            if !self.containsCamera {
                self.back(animated: true)
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

    // MARK: - NavigationBar
    func setupSubViews() {
        setupNavigationBar()
        setupCollectionView()
    }

    func setupNavigationBar() {
        // custom titleview
        topBar.dismiss = { [weak self] in
            self?.back(animated: true)
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
        if #available(iOS 13.0, *) {
            collectionView.backgroundColor = .systemBackground
        } else {
            collectionView.backgroundColor = .white
        }

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(GridViewCell.self, forCellWithReuseIdentifier: GridViewCell.reuseIdentifier)
        collectionView.register(GridCameraCell.self, forCellWithReuseIdentifier: GridCameraCell.reuseIdentifier)
    }

    func addSubViews() {
        view.addSubview(collectionView)
        view.addSubview(topBar)
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
            collectionView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
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

    func completeSelection(photos: [PhotoProtocol], animated: Bool) {
        guard !photos.isEmpty else {
            return
        }
        var arr: [SelectedImage?] = Array(repeating: nil, count: photos.count)
        for (index, photo) in photos.enumerated() {
            if let image = photo.image {
                arr[index] = SelectedImage(asset: photo.asset, image: image)
            } else if let asset = photo.asset {
                if let image = PhotoPickerResource.shared.fetchImage(asset) {
                    arr[index] = SelectedImage(asset: photo.asset, image: image)
                }
            }
        }
        let result = arr.compactMap { $0 }
        self.back(animated: animated) {
            self.selectedPhotos?(result)
        }
    }

    func back(animated: Bool, completion: (() -> Void)? = nil) {
        self.dismiss(animated: animated, completion: {
            completion?()
        })
    }

    // MARK: UICollectionView Delegate

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if containsCamera {
            // one cell for taking picture or video
            if photosAuthorityPassed {
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
        if let restore = editedPhotos[asset.localIdentifier] {
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = restore.editedImage
                configureCellState(cell, asset: asset)
                cell.showEditAnnotation(true)
            }
        } else {
            imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFit, options: options, resultHandler: { image, _ in
                // The cell may have been recycled by the time this handler gets called;
                // set the cell's thumbnail image only if it's still showing the same asset.
                if cell.representedAssetIdentifier == asset.localIdentifier {
                    cell.thumbnailImage = image
                    self.configureCellState(cell, asset: asset)
                    cell.showEditAnnotation(false)
                }
            })
        }

    }

    func configureCellState(_ cell: GridViewCell, asset: PHAsset) {
        if asset.mediaType == .video {
            cell.videoDuration = asset.duration.videoDurationFormat()
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

        // disable selection for unselected photos
        if assetSelectionIdentifierCache.count >= maximumCanBeSelected {
            if self.assetSelectionIdentifierCache.contains(asset.localIdentifier) {
                cell.isEnable = true
            } else {
                cell.isEnable = false
            }
        } else {
            cell.isEnable = true
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

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let gridCell = cell as? GridViewCell else { return }
        // fix the bug that cells aren't reloaded when selecting other cells
        let asset = assets.object(at: regenerate(indexPath: indexPath, if: containsCamera).item)
        self.configureCellState(gridCell, asset: asset)
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
            if let image = PhotoPickerResource.shared.fetchImage(first) {
                self.back(animated: true) {
                    self.selectedPhotos?([SelectedImage(asset: first, image: image)])
                }
            }
        }
    }

    // MARK: BROWSE IMAGES || VIDEO
    func browseImages(at indexPath: IndexPath) {
        var photos = [PhotoProtocol]()

        if editedPhotos.isEmpty {
            for index in 0..<assets.count {
                let asset = assets[index]
                photos.append(Photo.photoWithPHAsset(asset))
            }
        } else {
            for index in 0..<assets.count {
                let asset = assets[index]
                var photo = Photo.photoWithPHAsset(asset)
                if editedPhotos.keys.contains(asset.localIdentifier) {
                    photo.restoreData = editedPhotos[asset.localIdentifier]
                }
                photos.append(photo)
            }
        }

        let selectedAssetsResult = selectedAssets
        let selectedPhotos = selectedAssetsResult.map { Photo.photoWithPHAsset($0) }

        let photoBrowser = PhotoBrowserViewController.browse(photos: photos, at: indexPath.item, builder: { builder -> PhotoBrowserViewController.Builder in
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
    }

    func browseVideoIfValid(_ asset: PHAsset) {
        guard asset.mediaType == .video else {
            return
        }
        guard videoValidator.validVideoDuration(asset, limit: maximumVideoDuration) else {
            PhotoPickerResource.shared.requestAVAsset(for: asset) { [weak self] (avAsset) in
                if let urlAsset = avAsset as? AVURLAsset {
                    self?.presentVideoTrimmer(urlAsset, duration: urlAsset.duration.seconds)
                } else if let composition = avAsset as? AVComposition {
                    self?.presentVideoTrimmer(composition, duration: asset.duration)
                }
            }
            return
        }
        if !hasMemorySizeLimit {
            self.browseVideo(asset)
        } else {
            // It takes a lot of time to compute slow mode video momery footprint because
            // it needs to be exported to temp file to get the video url
            checkMemoryUsageFor(video: asset, limit: maximumVideoSize) { [weak self] (pass, _) in
                guard let self = self else { return }
                if pass {
                    self.browseVideo(asset)
                } else {
                    self.selectedVideo?(.failure(PhotoPickerError.VideoMemoryOutOfSize))
                }
            }
        }

    }

    func browseVideo(_ asset: PHAsset) {
        let videoPlayer = PlayVideoForSelectionViewController.playVideo(asset)
        videoPlayer.selectedVideo = { [weak self] url in
            guard let self = self else { return }
            if self.configuration.compressVideoBeforeSelected {
                if url.sizePerMB() <= self.configuration.compressVideoLimitSize {
                    let thumbnailImage = asset.getThumbnailImageSynchorously()
                    let selectedVideo = SelectedVideo(url: url)
                    selectedVideo.briefImage = thumbnailImage
                    self.back(animated: false) {
                        self.selectedVideo?(.success(selectedVideo))
                    }
                } else {
                    self.compressVideo(url: url, asset: asset) { [weak self] (result) in
                        guard let self = self else { return }
                        switch result {
                        case .success(let url):
                            let thumbnailImage = asset.getThumbnailImageSynchorously()
                            let selectedVideo = SelectedVideo(url: url)
                            selectedVideo.briefImage = thumbnailImage
                            self.back(animated: false) {
                                self.selectedVideo?(.success(selectedVideo))
                            }
                        case .failure(let error):
                            self.selectedVideo?(.failure(error))
                        }
                    }
                }
            } else {
                let thumbnailImage = asset.getThumbnailImageSynchorously()
                let selectedVideo = SelectedVideo(url: url)
                selectedVideo.briefImage = thumbnailImage
                self.back(animated: false) {
                    self.selectedVideo?(.success(selectedVideo))
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
        PhotoPickerResource.shared.requestAVAssetURL(for: video) { [weak self] (url) in
            guard let self = self else { return }
            guard let url = url else { return }
            let isValid = self.videoValidator.validVideoSize(url, limit: limit)
            completion(isValid, url)
        }
    }

    fileprivate func compressVideo(url: URL, asset: PHAsset, completion: @escaping ((Result<URL, Error>) -> Void)) {
        FYVideoCompressor().compressVideo(url, quality: compressedQuality) { (result) in
            switch result {
            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func presentVideoTrimmer(_ avAsset: AVAsset, duration: Double) {
        let trimmerVC = VideoTrimmerViewController(asset: avAsset, duration: duration, maximumDuration: maximumVideoDuration)
        trimmerVC.delegate = self
        trimmerVC.modalPresentationStyle = .fullScreen
        self.present(trimmerVC, animated: true, completion: nil)
    }

    func launchCamera() {
        let presentingVC = presentingViewController
        back(animated: true) {
            let cameraVC = CameraViewController(tintColor: self.configuration.colorConfiguration.selectionBackgroudColor)
            cameraVC.captureMode = self.mediaOptions
            cameraVC.videoMaximumDuration = self.maximumVideoDuration
            cameraVC.moviePathExtension = self.moviePathExtension
            cameraVC.delegate = self.cameraDelegate ?? self
            cameraVC.watermarkDelegate = self.watermarkDelegate
            cameraVC.watermarkDataSource = self.watermarkDataSource
            cameraVC.modalPresentationStyle = .fullScreen
            presentingVC?.present(cameraVC, animated: true, completion: nil)
        }
    }
}

extension PhotoPickerViewController: GridViewCellDelegate {
    func gridCell(_ cell: GridViewCell, buttonClickedAt indexPath: IndexPath, assetIdentifier: String) {
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
        let cells = collectionView.visibleCells.compactMap { $0 as? GridViewCell }.filter { $0.indexPath != nil }
        for cell in cells {
            let asset = assets.object(at: regenerate(indexPath: cell.indexPath!, if: containsCamera).item)
            configureCellState(cell, asset: asset)
        }
    }

    func reloadVisibleVideoCellsState() {
        let visibleVideoCellIndexPaths = collectionView.visibleCells.compactMap { $0 as? GridViewCell }.filter { $0.isVideoAsset }.compactMap { $0.indexPath }
        collectionView.reloadItems(at: visibleVideoCellIndexPaths)
    }

}

// MARK: - PhotoBrowserViewControllerDelegate
extension PhotoPickerViewController: PhotoBrowserViewControllerDelegate {

    public func photoBrowser(_ photoBrowser: PhotoBrowserViewController, scrollAt item: Int) {
        let itemFromBrowser = item
        let itemInPhotoPicker = containsCamera ? itemFromBrowser - 1 : itemFromBrowser
        lastSelectedIndexPath = IndexPath(item: itemInPhotoPicker, section: 0)
    }

    public func photoBrowser(_ photoBrowser: PhotoBrowserViewController, selectedAssets identifiers: [String]) {
        assetSelectionIdentifierCache = identifiers
    }

    public func photoBrowser(_ photoBrowser: PhotoBrowserViewController, didCompleteSelected photos: [PhotoProtocol]) {
        photoBrowser.dismiss(animated: true) {
            self.completeSelection(photos: photos, animated: true)
        }
    }

    public func photoBrowser(_ photoBrowser: PhotoBrowserViewController, deletePhotoAtIndexWhenBrowsing index: Int) {
        assetSelectionIdentifierCache.remove(at: index)
    }

    public func photoBrowser(_ photoBrowser: PhotoBrowserViewController, editedPhotos: [String: CroppedRestoreData]) {
        self.editedPhotos = editedPhotos
        if let indexPath = lastSelectedIndexPath {
            collectionView.reloadItems(at: [indexPath])
        }
    }
}

// MARK: - AlbumsTableViewControllerDelegate
extension PhotoPickerViewController: AlbumsTableViewControllerDelegate {
    func albumsTableViewController(_ albums: AlbumsTableViewController, didSelectPhassetAt indexPath: IndexPath) {
        self.selectedAlbumIndexPath = indexPath
        switch AlbumsTableViewController.Section(rawValue: indexPath.section)! {
        case .recentPhotos:
            assets = allPhotos
            topBar.setTitle(L10n.allPhotos)
        case .smartAlbums:
            let collection = smartAlbums[indexPath.row]
            topBar.setTitle(collection.localizedTitle ?? "")
            if mediaOptions == .image {
                assets = PhotoPickerResource.shared.allVideos(in: collection)
            } else if mediaOptions == .video {
                assets = PhotoPickerResource.shared.allVideos(in: collection)
            } else {
                assets = PhotoPickerResource.shared.allAssets(in: collection)
            }
        case .userCollections:
            let assetCollection: PHAssetCollection = userCollections.object(at: indexPath.row)
            topBar.setTitle(assetCollection.localizedTitle ?? "")
            if mediaOptions == .image {
                assets = PhotoPickerResource.shared.allVideos(in: assetCollection)
            } else if mediaOptions == .video {
                assets = PhotoPickerResource.shared.allVideos(in: assetCollection)
            } else {
                assets = PhotoPickerResource.shared.allAssets(in: assetCollection)
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
        guard photosAuthorityPassed else { return }
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
    fileprivate func handleObservingPhotosRemoved(_ ids: [String]) {
        for removedID in ids {
            assetSelectionIdentifierCache.removeAll {
                removedID == $0
            }
        }
    }

    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: assets) else { return }

        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            self.requestAlbumsData()

            if changes.removedObjects.count > 0 {
                handleObservingPhotosRemoved(changes.removedObjects.map {$0.localIdentifier})
            }

            self.collectionView.reloadData()
            self.resetCachedAssets()
        }
    }
}

extension PhotoPickerViewController: PhotoPickerBottomToolViewDelegate {
    func bottomToolViewPreviewButtonClicked() {
        let photos = selectedAssets.map { Photo.photoWithPHAsset($0) }
        let photoBrowser = PhotoBrowserViewController.browse(photos: photos) {
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
        let photos: [PhotoProtocol]

        if editedPhotos.isEmpty {
            photos = selectedAssets.map {
                Photo.photoWithPHAsset($0)
            }
        } else {
            photos = selectedAssets.map { asset -> PhotoProtocol in
                var photo = Photo.photoWithPHAsset(asset)
                if editedPhotos.keys.contains(asset.localIdentifier) {
                    photo.restoreData = editedPhotos[asset.localIdentifier]
                }
                return photo
            }
        }
        completeSelection(photos: photos, animated: true)
    }
}

extension PhotoPickerViewController: VideoTrimmerViewControllerDelegate {
    public func videoTrimmerDidCancel(_ videoTrimmer: VideoTrimmerViewController) {
        videoTrimmer.dismiss(animated: true, completion: nil)
    }

    public func videoTrimmer(_ videoTrimmer: VideoTrimmerViewController, didFinishTrimingAt url: URL) {
        self.back(animated: true) {
            self.selectedVideo?(.success(SelectedVideo(url: url)))
        }
    }

}
