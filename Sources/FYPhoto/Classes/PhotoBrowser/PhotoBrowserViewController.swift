//
//  PhotoDetailCollectionViewController.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/27.
//

import UIKit
import Photos
import MobileCoreServices
import Foundation

/// use static method `create(photos:initialIndex:builder:)` to create PhotoBrowser instance
public class PhotoBrowserViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    static let minimumLineSpacing: CGFloat = 20

    public weak var delegate: PhotoBrowserViewControllerDelegate?

    // bar item
    fileprivate var addPhotoBarItem: UIBarButtonItem!
    fileprivate var removePhotoBarItem: UIBarButtonItem!

    fileprivate var mainCollectionView: UICollectionView!

    /// bottom caption view
    fileprivate lazy var captionView = CaptionView()

    fileprivate lazy var pageControl: UIPageControl = {
        let pageCtl = UIPageControl()
        pageCtl.numberOfPages = photos.count
        pageCtl.currentPage = initialIndex
        pageCtl.currentPageIndicatorTintColor = UIColor.white
        pageCtl.pageIndicatorTintColor = UIColor.lightGray
        return pageCtl
    }()

    fileprivate lazy var bottomToolView: PhotoBrowserBottomToolView = {
        let toolView = PhotoBrowserBottomToolView(colorStyle: colorConfiguration.browserBottomBarColor,
                                                  safeAreaInsetsBottom: safeAreaInsetsBottom)
        toolView.delegate = self
        return toolView
    }()

    fileprivate var bottomToolViewBottomConstraint: NSLayoutConstraint?
    fileprivate var bottomToolViewHeight: CGFloat {
        return 45 + safeAreaInsetsBottom
    }

    var safeAreaInsetsBottom: CGFloat {
        return UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
    }

    var videoCache: VideoCache?

    fileprivate var initialScrollDone = false

    fileprivate var previousNavigationBarHidden: Bool?
    fileprivate var previousToolBarHidden: Bool?
    fileprivate var previousInteractivePop: Bool?
    fileprivate var previousNavigationTitle: String?
    fileprivate var previousExtendedLayoutIncludesOpaqueBars: Bool = false

    fileprivate var previousAudioCategory: AVAudioSession.Category?
    fileprivate var previousAudioMode: AVAudioSession.Mode?
    fileprivate var previousAudioOptions: AVAudioSession.CategoryOptions?

    fileprivate var originCaptionTransform: CGAffineTransform!

    fileprivate var mainFlowLayout: UICollectionViewFlowLayout? {
        return mainCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }

    fileprivate var assetSize: CGSize?

    fileprivate var initTargetSize = false

    // MARK: Video properties
    var player: AVPlayer? {
        didSet {
            bottomToolView.playButton.isEnabled = (player != nil)
        }
    }

    var mPlayerItem: AVPlayerItem?
    var isPlaying = false {
        willSet {
            if supportBottomToolBar {
                bottomToolView.isPlaying = newValue
            }
        }
    }

    let assetKeys = [
        "playable",
        "hasProtectedContent"
    ]

    var playerItemStatusToken: NSKeyValueObservation?

    /// After the movie has played to its end time, seek back to time zero
    /// to play it again.
    var seekToZeroBeforePlay: Bool = false

    var currentDisplayedIndexPath: IndexPath {
        didSet {
            guard currentDisplayedIndexPath != oldValue else { return }
            
            currentPhoto = photos[currentDisplayedIndexPath.item]
            delegate?.photoBrowser(self, scrollAt: currentDisplayedIndexPath.item)
            if isForSelection {
                updateAddBarItem(at: currentDisplayedIndexPath)
            } else {
                updatePageControl(withPage: currentDisplayedIndexPath.item)
            }
            if supportCaption {
                updateCaption(at: currentDisplayedIndexPath)
            }
            if supportThumbnails {
                if isOperatingMainPhotos {
                    updateThumbnails(at: currentDisplayedIndexPath)
                }
            }
            updateNavigationTitle(at: currentDisplayedIndexPath)
            updateCellVideoPlayer(at: currentDisplayedIndexPath)
            stopPlayingIfNeeded(at: oldValue)
        }
    }
    
    func updateCellVideoPlayer(at indexPath: IndexPath) {
        guard let videoCell = mainCollectionView.cellForItem(at: indexPath) as? VideoDetailCell else {
            return
        }
        let photo = photos[indexPath.item]
        guard photo.isVideo else {
            return
        }
        // a scroll action may cause the `cellForItem` method to be called twice, and will cause a bug when setting up avplayer, so I decide to move setup player code here.
        setupPlayer(photo: photo, for: videoCell)
    }

    var selectedThumbnailIndexPath: IndexPath? {
        willSet {
            guard isThumbnailIndexPathInitialized else {
                // do nothing when building PhotoBrowserViewController
                return
            }
            guard let newIndexPath = newValue else {
                thumbnailsCollectionView.reloadData()
                // 有值 -> 无值， 取消 thumbnail selected 状态
                // 无值 -> 无值， selectedPhotos 改变
                return
            }
            guard newIndexPath != selectedThumbnailIndexPath else {
                // 没有选中时，thumbanail collectionView
                return
            }
            guard !isOperatingMainPhotos else { // 点击 thumbnail
                // reload thumbnailsCollectionView when scorlling mainCollectionView
                thumbnailsCollectionView.reloadData()
                return
            }
            // scroll mainCollectionView when selecting thumbnail cell
            let thumbnailPhoto = selectedPhotos[newIndexPath.item]
            let mainPhoto = photos[currentDisplayedIndexPath.item]
            if !thumbnailPhoto.isEqualTo(mainPhoto), mainCollectionView.superview != nil {
                if let firstIndex = firstIndexOfPhoto(thumbnailPhoto, in: photos) { // 点击thumbnail cell 滑动主collectionView
                    let mainPhotoIndexPath = IndexPath(item: firstIndex, section: 0)
                    mainCollectionView.scrollToItem(at: mainPhotoIndexPath, at: .left, animated: true)
                    currentDisplayedIndexPath = mainPhotoIndexPath
                }
            }
            thumbnailsCollectionView.reloadData()
        }
        didSet {
            if !isThumbnailIndexPathInitialized {
                isThumbnailIndexPathInitialized = true
            }
        }
    }
    // mainCollectionView 和 thumbnailsCollectionView 同步切换cell 是通过 currentDisplayedIndexPath 和 selectedThumbnailIndexPath
    // 这两个 indexPath 来实现的。
    // 因此需要一个Bool 类型的值来避免 currentDisplayedIndexPath 与 selectedThumbnailIndexPath 循环调用
    // 调用时机需要注意，需要在给 indexPath 赋值之前
    fileprivate var isOperatingMainPhotos = false

    fileprivate var currentPhoto: PhotoProtocol {
        willSet {
            bottomToolView.showPlayButton(newValue.isVideo)
            bottomToolView.editButton.isHidden = newValue.asset?.mediaType != .image
        }
    }

    fileprivate var isThumbnailIndexPathInitialized = false

    /// main data source
    var selectedPhotos: [PhotoProtocol] = [] {
        didSet {
            guard isForSelection else {
                return
            }
            let assetIdentifiers = selectedPhotos.compactMap { $0.asset?.localIdentifier }
            delegate?.photoBrowser(self, selectedAssets: assetIdentifiers)

            guard supportThumbnails else { return }
            bottomToolView.disableDoneButton(selectedPhotos.isEmpty)

            guard !selectedPhotos.isEmpty else {
                selectedThumbnailIndexPath = nil
                thumbnailsCollectionView.isHidden = true
                return
            }
            thumbnailsCollectionView.isHidden = false

            if !isThumbnailIndexPathInitialized {
                // initialize thumbnail indexPath if selected photos are not empty when building PhotoBrowserViewController
                let initialPhoto = photos[initialIndex]
                if let photoIndexInSelectedPhotos = firstIndexOfPhoto(initialPhoto, in: selectedPhotos) {
                    let initialIndexPathInThumbnails = IndexPath(item: photoIndexInSelectedPhotos, section: 0)
                    selectedThumbnailIndexPath = initialIndexPathInThumbnails
                }
            } else {
                if oldValue.count <= selectedPhotos.count {
                    selectedThumbnailIndexPath = IndexPath(item: selectedPhotos.count - 1, section: 0)
                } else {
                    selectedThumbnailIndexPath = nil
                }
            }
        }
    }

    var photos: [PhotoProtocol] {
        didSet {
            mainCollectionView.reloadData()
            if supportPageControl {
                pageControl.numberOfPages = photos.count
                updatePageControl(withPage: currentDisplayedIndexPath.item)
            }
        }
    }
    
    private var scrollOnlyOnce = false
    
    fileprivate let initialIndex: Int
    /// the maximum number of photos you can select
    var maximumCanBeSelected: Int = 0
    var isForSelection = false
    var supportThumbnails = true
    var supportCaption = false
    var supportNavigationBar = false
    var supportBottomToolBar = false
    /// show delete button for photo browser
    var canDeleteWhenPreviewingSelectedPhotos = false
    var supportPageControl = false

    @available(swift, deprecated: 1.2.0, message: "use `colorConfiguration` for color configuration")
    public var uiConfiguration = FYUIConfiguration() {
        didSet {
            thumbnailsCollectionView.backgroundColor = uiConfiguration.browserBottomBarColorStyle.backgroundColor
        }
    }

    public var colorConfiguration = FYColorConfiguration() {
        didSet {
            thumbnailsCollectionView.backgroundColor = colorConfiguration.browserBottomBarColor.backgroundColor
        }
    }

    // MARK: - Function

    // MARK: LifeCycle
    /// PhotoBrowserViewController initialization.
    /// - Parameters:
    ///   - photos: data source to show
    ///   - initialIndex: first show the photo you clicked
    private init(photos: [PhotoProtocol], initialIndex: Int) {
        self.photos = photos
        self.initialIndex = initialIndex
        currentDisplayedIndexPath = IndexPath(row: initialIndex, section: 0)
        currentPhoto = photos[initialIndex]

        super.init(nibName: nil, bundle: nil)
    }

    /// Create PhotoBrowser.
    /// - Parameters:
    ///   - photos: photo data source to be browsed.
    ///   - initialIndex: the index of the first photo to be displayed.
    ///   - builder: construct photoBrowser with custom builder. By default, can only browse, not manipulate.
    /// - Returns: PhotoBrowserViewController
    public static func browse(photos: [PhotoProtocol],
                              at initialIndex: Int = 0,
                              builder: ((Builder) -> Builder)? = quickBuildPhotoBrowser()) -> PhotoBrowserViewController {
        let photoBrowser = PhotoBrowserViewController(photos: photos, initialIndex: initialIndex)
        let concretBuilder = Builder()
        builder?(concretBuilder).build(photoBrowser)
        return photoBrowser
    }

    /// Create PhotoBrowser.
    /// - Parameters:
    ///   - photos: photo data source to be browsed.
    ///   - initialIndex: the index of the first photo to be displayed.
    ///   - builder: construct photoBrowser with custom builder. By default, can only browse, not manipulate.
    /// - Returns: PhotoBrowserViewController
    @available(swift, deprecated: 3.0.0, message: "use `browse(photos:...)` instead")
    public static func create(photos: [PhotoProtocol],
                              initialIndex: Int,
                              builder: ((Builder) -> Builder)? = quickBuildPhotoBrowser()) -> PhotoBrowserViewController {
        let photoBrowser = PhotoBrowserViewController(photos: photos, initialIndex: initialIndex)
        let concretBuilder = Builder()
        builder?(concretBuilder).build(photoBrowser)
        return photoBrowser
    }

    public static func quickBuildPhotoBrowser() -> (Builder) -> Builder {
        return { builder -> Builder in
            return builder.quickBuildJustForBrowser()
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        videoCache?.cancelAllTask()
        restoreOtherPreviousData()
        NotificationCenter.default.removeObserver(self)
        playerItemStatusToken?.invalidate()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = true
        view.backgroundColor = .black
        edgesForExtendedLayout = .all
        cachePreviousData()
        // Set this value to true to fix a bug: when NavigationBar is opaque, photoBrowser show navigationbar again after hiding it,
        // but photoBrowser view is under a navigationBar height space
        extendedLayoutIncludesOpaqueBars = true
        setupVideoCache()
        setupCollectionView()
        setupNavigationBar()
        setupBottomToolBar()
        addSomeSubviews()

        if supportBottomToolBar {
            self.view.bringSubviewToFront(bottomToolView)
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationController?.setNavigationBarHidden(!supportNavigationBar, animated: true)
        originCaptionTransform = captionView.transform
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlayingAnyway()
        restorePreviousNavigationControllerData()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !initTargetSize && view.bounds.size != .zero {
            initTargetSize = true
            recalculateAseetTargetSize(inBoundingSize: view.bounds.size)
        }
        
        setupFirstScroll()
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // Device rotating
        // Instruct collection view how to handle changes in page size

        recalculateAseetTargetSize(inBoundingSize: size)
        if view.window == nil {
            view.frame = CGRect(origin: view.frame.origin, size: size)
            view.layoutIfNeeded()
        } else {
            let indexPath = self.mainCollectionView.indexPathsForVisibleItems.last
            coordinator.animate(alongsideTransition: { _ in
                self.mainCollectionView.layoutIfNeeded()
                if let indexPath = indexPath {
                    self.mainCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                }
            }, completion: { _ in

            })
        }

        super.viewWillTransition(to: size, with: coordinator)
    }

    fileprivate func cachePreviousData() {
        previousNavigationBarHidden = self.navigationController?.navigationBar.isHidden
        previousInteractivePop = self.navigationController?.interactivePopGestureRecognizer?.isEnabled
        previousNavigationTitle = self.navigationController?.navigationItem.title
        previousExtendedLayoutIncludesOpaqueBars = extendedLayoutIncludesOpaqueBars

        previousAudioCategory = AVAudioSession.sharedInstance().category
        previousAudioMode = AVAudioSession.sharedInstance().mode
        previousAudioOptions = AVAudioSession.sharedInstance().categoryOptions
    }

    fileprivate func activateOtherInterruptedAudioSessions() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

            if let category = previousAudioCategory {
                do {
                    try AVAudioSession.sharedInstance().setCategory(category,
                                                                    mode: previousAudioMode ?? .default,
                                                                    options: previousAudioOptions ?? [])
                } catch {
                    print(error)
                }
            }
        } catch let error {
            print("audio session set active error: \(error)")
        }
    }

    // MARK: Setup

    func addSomeSubviews() {
        if isForSelection {
            if supportThumbnails {
                addThumbnailCollectionView()
            }
        } else {
            if supportPageControl, photos.count > 1 {
                addPageControl()
            }
            if supportCaption {
                addCaptionView()
            }
        }
    }

    func generateMainCollectionView() -> UICollectionView {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = PhotoBrowserViewController.minimumLineSpacing
        flowLayout.minimumLineSpacing = PhotoBrowserViewController.minimumLineSpacing
        flowLayout.sectionInset = UIEdgeInsets(top: 0,
                                               left: PhotoBrowserViewController.minimumLineSpacing / 2.0,
                                               bottom: 0,
                                               right: PhotoBrowserViewController.minimumLineSpacing / 2.0)
        flowLayout.scrollDirection = .horizontal
        return UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    }

    func generateThumbnailsCollectionView() -> UICollectionView {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 10
        flowLayout.scrollDirection = .horizontal
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        return UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    }

    func setupCollectionView() {
        mainCollectionView = generateMainCollectionView()
        view.addSubview(mainCollectionView)
        mainCollectionView.register(PhotoDetailCell.self, forCellWithReuseIdentifier: PhotoDetailCell.reuseIdentifier)
        mainCollectionView.register(VideoDetailCell.self, forCellWithReuseIdentifier: VideoDetailCell.reuseIdentifier)
        mainCollectionView.isPagingEnabled = true
        mainCollectionView.delegate = self
        mainCollectionView.dataSource = self
//        collectionView.backgroundColor = .white
        mainCollectionView.contentInsetAdjustmentBehavior = .never
        
        mainCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
            mainCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -PhotoBrowserViewController.minimumLineSpacing/2),
            mainCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            mainCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: PhotoBrowserViewController.minimumLineSpacing/2),
        ])
    }

    lazy var addItemButton: UIButton = {
        let button = UIButton()
        button.setImage(Asset.imageSelectedOff.image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 30).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.layer.cornerRadius = 15
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(addPhotoBarItemClicked(_:)), for: .touchUpInside)
        button.backgroundColor = colorConfiguration.topBarColor.itemBackgroundColor
        button.setTitleColor(colorConfiguration.topBarColor.itemTintColor, for: .normal)
        return button
    }()

    func setupNavigationBar() {
        let config = colorConfiguration.topBarColor
        self.navigationController?.navigationBar.tintColor = config.itemTintColor
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: Asset.back.image, style: .plain, target: self, action: #selector(back))

        if isForSelection {
            addPhotoBarItem = UIBarButtonItem(customView: addItemButton)
            self.navigationItem.rightBarButtonItem = addPhotoBarItem
        } else {
            if canDeleteWhenPreviewingSelectedPhotos {
                removePhotoBarItem = UIBarButtonItem(barButtonSystemItem: .trash,
                                                     target: self,
                                                     action: #selector(removePhotoWhenBrowsingBarItemClicked(_:)))
                self.navigationItem.rightBarButtonItem = removePhotoBarItem
            }
        }
        updateNavigationTitle(at: currentDisplayedIndexPath)
    }

    func setupBottomToolBar() {
        guard supportBottomToolBar else { return }
        view.addSubview(bottomToolView)
        bottomToolView.translatesAutoresizingMaskIntoConstraints = false

        bottomToolViewBottomConstraint = bottomToolView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        bottomToolViewBottomConstraint?.isActive = true
        NSLayoutConstraint.activate([
            bottomToolView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            bottomToolView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            bottomToolView.heightAnchor.constraint(equalToConstant: bottomToolViewHeight)
        ])
        bottomToolView.showPlayButton(currentPhoto.isVideo)
        if isForSelection || canDeleteWhenPreviewingSelectedPhotos {
            bottomToolView.addDoneButton()
            bottomToolView.disableDoneButton(selectedPhotos.isEmpty)
        }
        if isForSelection {
            bottomToolView.addEditButton()
            if let current = currentPhoto.asset, current.mediaType == .image {
                bottomToolView.editButton.isHidden = false
            }
        }
    }
    
    func setupFirstScroll() {
        guard !scrollOnlyOnce else { return }
        // scroll position shouldn't be empty, otherwise, collection view will not be in the right position.
//        mainCollectionView.selectItem(at: currentDisplayedIndexPath, animated: false, scrollPosition: .centeredHorizontally)
        // animated should be true, otherwise can't scroll to the correct place.
        mainCollectionView.scrollToItem(at: currentDisplayedIndexPath, at: [.centeredVertically, .centeredHorizontally], animated: true)
        if isForSelection {
            updateAddBarItem(at: currentDisplayedIndexPath)
        }
        if supportCaption {
            updateCaption(at: currentDisplayedIndexPath)
        }
                
        scrollOnlyOnce = true
    }

    fileprivate func restoreOtherPreviousData() {
        activateOtherInterruptedAudioSessions()
        extendedLayoutIncludesOpaqueBars = previousExtendedLayoutIncludesOpaqueBars
    }

    func restorePreviousNavigationControllerData() {
        if let title = previousNavigationTitle {
            navigationItem.title = title
        }
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = previousInteractivePop ?? true
        if let originalIsNavigationBarHidden = previousNavigationBarHidden {
            navigationController?.setNavigationBarHidden(originalIsNavigationBarHidden, animated: false)
        }
    }

    func setupVideoCache() {
        videoCache = VideoCache.shared
    }

    // selected photo thumbnail collectionView
    lazy var thumbnailsCollectionView: UICollectionView = {
        let collectionView = generateThumbnailsCollectionView()
        collectionView.register(PBSelectedPhotosThumbnailCell.self,
                                forCellWithReuseIdentifier: PBSelectedPhotosThumbnailCell.reuseIdentifier)
        collectionView.isPagingEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = colorConfiguration.browserBottomBarColor.backgroundColor
        collectionView.contentInsetAdjustmentBehavior = .never
        return collectionView
    }()

    func addThumbnailCollectionView() {
        view.addSubview(thumbnailsCollectionView)
        let safeAreaLayoutGuide = self.view.safeAreaLayoutGuide
        thumbnailsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        if supportBottomToolBar {
            NSLayoutConstraint.activate([
                thumbnailsCollectionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 0),
                thumbnailsCollectionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: 0),
                thumbnailsCollectionView.bottomAnchor.constraint(equalTo: self.bottomToolView.topAnchor, constant: 0),
                thumbnailsCollectionView.heightAnchor.constraint(equalToConstant: 90)
            ])
        } else {
            NSLayoutConstraint.activate([
                thumbnailsCollectionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 0),
                thumbnailsCollectionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: 0),
                thumbnailsCollectionView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: 0),
                thumbnailsCollectionView.heightAnchor.constraint(equalToConstant: 90)
            ])
        }
    }

    func addCaptionView() {
        view.addSubview(captionView)
        let safeAreaLayoutGuide = self.view.safeAreaLayoutGuide
        captionView.translatesAutoresizingMaskIntoConstraints = false
        if supportBottomToolBar {
            NSLayoutConstraint.activate([
                captionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
                captionView.bottomAnchor.constraint(equalTo: bottomToolView.topAnchor, constant: -10),
                captionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10)
            ])
        } else {
            NSLayoutConstraint.activate([
                captionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
                captionView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),
                captionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10)
            ])
        }
    }

    func addCollectionView() {
        view.addSubview(mainCollectionView)
//        mainCollectionView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            mainCollectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
//            mainCollectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
//            mainCollectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
//            mainCollectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
//        ])
    }

    func addPageControl() {
        view.addSubview(pageControl)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
            pageControl.widthAnchor.constraint(equalToConstant: 200),
            pageControl.heightAnchor.constraint(equalToConstant: 30)
        ])
        mainCollectionView.showsHorizontalScrollIndicator = false
    }

    func hideCaptionView(_ flag: Bool, animated: Bool = true) {
        if flag { // hide
            let transition = CGAffineTransform(translationX: 0, y: captionView.bounds.height)
            if animated {
                UIView.animate(withDuration: 0.2, animations: {
                    self.captionView.transform = transition
                }) { (_) in
                    self.captionView.isHidden = true
                }
            } else {
                captionView.transform = transition
                captionView.isHidden = true
            }
        } else { // show
            captionView.isHidden = false
            if animated {
                UIView.animate(withDuration: 0.3) {
                    self.captionView.transform = self.originCaptionTransform
                }
            } else {
                self.captionView.transform = originCaptionTransform
            }
        }
    }

    // MARK: UICollectionViewDataSource
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if collectionView == self.mainCollectionView {
            return photos.count
        } else { // selected photos thumnail collectionView
            return selectedPhotos.count
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.mainCollectionView {
            var photo = photos[indexPath.item]
            photo.targetSize = assetSize
            if photo.isVideo {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoDetailCell.reuseIdentifier,
                                                                 for: indexPath) as? VideoDetailCell {
                    cell.photo = photo
                    if currentDisplayedIndexPath == indexPath {
                        // set player for cell when the collectionView first appears
                        setupPlayer(photo: photo, for: cell)
                    }
                    return cell
                }
            } else {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoDetailCell.reuseIdentifier,
                                                                 for: indexPath) as? PhotoDetailCell {
                    cell.photo = photo
                    return cell
                }
            }
        } else { // thumbnails
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PBSelectedPhotosThumbnailCell.reuseIdentifier,
                                                             for: indexPath) as? PBSelectedPhotosThumbnailCell {
                cell.cellBorderColor = colorConfiguration.browserBottomBarColor.itemTintColor
                cell.photo = selectedPhotos[indexPath.item]
                if let selectedIdx = selectedThumbnailIndexPath {
                    cell.thumbnailIsSelected = indexPath == selectedIdx
                } else {
                    cell.thumbnailIsSelected = false
                }
                return cell
            }
        }

        return UICollectionViewCell()
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // remove video player when video cell disappears
        if let videoCell = cell as? VideoDetailCell {
            videoCell.playerView.player = nil
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.thumbnailsCollectionView {
            isOperatingMainPhotos = false
            selectedThumbnailIndexPath = indexPath
        }
    }

    // UICollectionViewDelegateFlowLayout
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.mainCollectionView {
            return view.bounds.size
        } else {
            return CGSize(width: 70, height: 70)
        }
    }

    // MARK: Bar item actions
    @objc func doneBarButtonClicked(_ sender: UIBarButtonItem) {
        assert(!selectedPhotos.isEmpty, "photos shouldn't be empty")
        delegate?.photoBrowser(self, didCompleteSelected: selectedPhotos)
    }

    @objc func addPhotoBarItemClicked(_ sender: UIButton) {

        let photo = photos[currentDisplayedIndexPath.item]

        isOperatingMainPhotos = true

        if let exsit = firstIndexOfPhoto(photo, in: selectedPhotos) {
            // already added, remove it from selections
            selectedPhotos.remove(at: exsit)
            updateAddBarItem(title: "")
            return
        }

        // add photo
        selectedPhotos.append(photo)

        updateRightBarItemCount(photo)
    }

    @objc func removePhotoWhenBrowsingBarItemClicked(_ sender: UIBarButtonItem) {
        photos.remove(at: currentDisplayedIndexPath.item)
        delegate?.photoBrowser(self, deletePhotoAtIndexWhenBrowsing: currentDisplayedIndexPath.item)
        if !photos.isEmpty {
            let minusOneItem = currentDisplayedIndexPath.item - 1
            let fixedIndexPath = minusOneItem < 0 ? currentDisplayedIndexPath : IndexPath(item: minusOneItem, section: 0)
            currentDisplayedIndexPath = fixedIndexPath
        } else {
            back()
        }
    }

    @objc func back() {
        if presentingViewController != nil {
            if presentingViewController is UINavigationController {
                navigationController?.popViewController(animated: true)
            } else {
                dismiss(animated: true, completion: nil)
            }
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: Update views
    fileprivate func updateAddBarItem(at indexPath: IndexPath) {
        let photo = photos[indexPath.item]
        guard !photo.isVideo else {
            addItemButton.isHidden = true
            return
        }
        addItemButton.isHidden = false
        if let firstIndex = firstIndexOfPhoto(photo, in: selectedPhotos) {
            updateAddBarItem(title: "\(firstIndex + 1)")
        } else {
            updateAddBarItem(title: "")
        }
    }

    fileprivate func updateRightBarItemCount(_ currentPhoto: PhotoProtocol) {
        // update bar item: add, done
        if let firstIndex = self.firstIndexOfPhoto(currentPhoto, in: selectedPhotos) {
            self.updateAddBarItem(title: "\(firstIndex + 1)")
        }
    }

    fileprivate func updateAddBarItem(title: String) {
        if title.isEmpty {
//            addPhotoBarItem.title = " "
            addItemButton.isEnabled = selectedPhotos.count < maximumCanBeSelected
            if addItemButton.backgroundImage(for: .normal) == nil {
                addItemButton.setImage(Asset.imageSelectedOff.image, for: .normal)
                addItemButton.backgroundColor = nil
                addItemButton.setTitle(nil, for: .normal)
            }
        } else {
//            addPhotoBarItem.isEnabled = true
            addItemButton.isEnabled = true
            addItemButton.setTitle(title, for: .normal)
            addItemButton.setImage(nil, for: .normal)
            addItemButton.backgroundColor = .white
        }
    }

    fileprivate func updateCaption(at indexPath: IndexPath) {
        let photo = photos[indexPath.item]
        captionView.setup(content: photo.captionContent, signature: photo.captionSignature)
        // fix caption size not correctly calculated
        captionView.invalidateIntrinsicContentSize()
        view.setNeedsLayout()
    }

    fileprivate func updateNavigationTitle(at indexPath: IndexPath) {
        if supportNavigationBar {
            if isForSelection {
                navigationItem.title = ""
            } else {
                if photos.count > 1 {
                    navigationItem.title = "\(indexPath.item + 1)/\(photos.count)"
                }
            }
        }
    }

    fileprivate func updateThumbnails(at indexPath: IndexPath) {
        let photo = photos[indexPath.item]
        if let firstIndex = firstIndexOfPhoto(photo, in: selectedPhotos) {
            selectedThumbnailIndexPath = IndexPath(item: firstIndex, section: 0)
        } else {
            selectedThumbnailIndexPath = nil
        }
    }

    fileprivate func updatePageControl(withPage page: Int) {
        if photos.count <= 1 {
            pageControl.isHidden = true
        } else {
            pageControl.isHidden = false
            pageControl.currentPage = page
        }
    }

    fileprivate func recalculateAseetTargetSize(inBoundingSize size: CGSize) {
        let scale = UIScreen.main.scale
        assetSize = CGSize(width: size.width * scale, height: size.height * scale)
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        stopPlayingAnyway()
        player = nil
    }
}

extension PhotoBrowserViewController: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == mainCollectionView {
            let visibleRect = CGRect(origin: mainCollectionView.contentOffset, size: mainCollectionView.bounds.size)
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            let visibleIndexPath = mainCollectionView.indexPathForItem(at: visiblePoint)
            if visibleIndexPath != currentDisplayedIndexPath {
                isOperatingMainPhotos = true
                currentDisplayedIndexPath = visibleIndexPath ?? IndexPath(item: 0, section: 0)
            }
        }
    }
//    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
//
//    }
}

// MARK: - Router event
extension PhotoBrowserViewController {
    override func routerEvent(name: String, userInfo: [AnyHashable: Any]?) {
        if let tap = ImageViewGestureEvent(rawValue: name) {
            switch tap {
            case .singleTap:
                hideOrShowTopBottom()
            case .doubleTap:
                handleDoubleTap(userInfo)
            case .longPress:
                handleLongPress(userInfo)
            }
        } else {
            // pass the event
            next?.routerEvent(name: name, userInfo: userInfo)
        }
    }

    fileprivate func hideOrShowTopBottom() {
        if supportNavigationBar {
            self.navigationController?.setNavigationBarHidden(!(self.navigationController?.isNavigationBarHidden ?? true),
                                                              animated: true)
        }

        if supportBottomToolBar {
            let toolViewIsHidden = bottomToolView.isHidden
            let constant: CGFloat = toolViewIsHidden ? 0 : bottomToolViewHeight
            if toolViewIsHidden {
                self.bottomToolView.isHidden = false
            }
            UIView.animate(withDuration: 0.3) {
                self.bottomToolViewBottomConstraint?.constant = constant
                self.view.layoutIfNeeded()
            } completion: { _ in
                if !toolViewIsHidden {
                    self.bottomToolView.isHidden = true
                }
            }
        }

        if supportCaption {
            hideCaptionView(!captionView.isHidden)
        }
    }

    fileprivate func handleDoubleTap(_ userInfo: [AnyHashable: Any]?) {
        if let userInfo = userInfo, let mediaType = userInfo["mediaType"] as? String {
            let cfstring = mediaType as CFString
            switch cfstring {
            case kUTTypeImage:
                if let touchPoint = userInfo["touchPoint"] as? CGPoint,
                   let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) as? PhotoDetailCell {
                    doubleTap(touchPoint, on: cell)
                }
            case kUTTypeVideo:
                if isPlaying {
                    pauseVideo()
                } else {
                    playVideo()
                }
            default: break

            }
        }
    }

    fileprivate func doubleTap(_ touchPoint: CGPoint, on cell: PhotoDetailCell) {
        let scale = min(cell.zoomingView.zoomScale * 2, cell.zoomingView.maximumZoomScale)
        if cell.zoomingView.zoomScale == 1 {
            let zoomRect = zoomRectForScale(scale: scale, center: touchPoint, for: cell.zoomingView)
            cell.zoomingView.zoom(to: zoomRect, animated: true)
        } else {
            cell.zoomingView.setZoomScale(1, animated: true)
        }
    }

    fileprivate func zoomRectForScale(scale: CGFloat, center: CGPoint, for scroolView: UIScrollView) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = scroolView.frame.size.height / scale
        zoomRect.size.width  = scroolView.frame.size.width  / scale

        zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }

    func handleLongPress(_ userInfo: [AnyHashable: Any]?) {
        guard !isForSelection, let userInfo = userInfo, let touchPint = userInfo["touchPoint"] as? CGPoint else {
            return
        }
        // long press only work for pure browser, not for selection
        if let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) as? CellWithPhotoProtocol,
           let photo = cell.photo {
            delegate?.photoBrowser(self, longPressedOnPhoto: photo, in: touchPint)
        }
    }
}

// MARK: - PhotoDetailTransitionAnimatorDelegate
extension PhotoBrowserViewController: PhotoTransitioning {
    public func transitionWillStart() {
        guard let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) else { return }
        cell.isHidden = true
    }

    public func transitionDidEnd() {
        guard let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) else { return }
        cell.isHidden = false
    }

    public func referenceImage() -> UIImage? {
        if let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) as? PhotoDetailCell {
            return cell.image
        }
        if let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) as? VideoDetailCell {
            return cell.image
        }
        return nil
    }

    public func imageFrame() -> CGRect? {
        if let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) as? PhotoDetailCell {
            return CGRect.makeRect(aspectRatio: cell.image?.size ?? .zero, insideRect: cell.bounds)
        }
        if let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) as? VideoDetailCell {
            return CGRect.makeRect(aspectRatio: cell.image?.size ?? .zero, insideRect: cell.bounds)
        }
        return nil
    }
}

extension PhotoBrowserViewController {
    func firstIndexOfPhoto(_ photo: PhotoProtocol, in photos: [PhotoProtocol]) -> Int? {
        return photos.firstIndex { $0.isEqualTo(photo) }
    }
}

extension PhotoBrowserViewController: PhotoBrowserBottomToolViewDelegate {

    func browserBottomToolViewEditButtonClicked() {
        guard let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) as? PhotoDetailCell,
              let image = cell.image,
              var photo = cell.photo
        else { return }
        let cropViewController: CropImageViewController
        if let restoreData = cell.photo?.restoreData {
            cropViewController = CropImageViewController(restoreData: restoreData)
        } else {
            cropViewController = CropImageViewController(image: image)
        }
        cropViewController.croppedImage = { [weak self, weak cropViewController] result in // avoid retain cycle
            guard let self = self else { return }
            switch result {
            case .success(let cropped):
                photo.storeImage(cropped)
                cell.image = cropped

                if let asset = photo.asset, let restoreData = cropViewController?.restoreData {
                    photo.restoreData = restoreData
                    self.delegate?.photoBrowser(self, editedPhotos: [asset.localIdentifier: restoreData])

                    if !self.selectedPhotos.contains(where: { selected in
                        photo.isEqualTo(selected)
                    }) {
                        self.selectedPhotos.append(photo)
                        self.updateRightBarItemCount(photo)
                    }
                    self.thumbnailsCollectionView.reloadData()
                }
            case .failure(let error):
                self.showError(error)
            }
        }
        cropViewController.modalPresentationStyle = .fullScreen
        present(cropViewController, animated: true, completion: nil)
    }

    func browserBottomToolViewPlayButtonClicked() {
        guard currentPhoto.isVideo else { return }
        if isPlaying {
            pauseVideo()
        } else {
            playVideo()
        }
    }

    func browserBottomToolViewDoneButtonClicked() {
        assert(!selectedPhotos.isEmpty, "photos shouldn't be empty")
        back()
        delegate?.photoBrowser(self, didCompleteSelected: selectedPhotos)
    }
}

extension PhotoBrowserViewController: PhotoBrowserCurrentPage {
    var currentPage: Int {
        currentDisplayedIndexPath.item
    }
}
