//
//  PhotoDetailCollectionViewController.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/27.
//

import UIKit
import Photos
import MobileCoreServices

/// use static method `create(photos:initialIndex:builder:)` to create PhotoBrowser instance
public class PhotoBrowserViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    public weak var delegate: PhotoBrowserViewControllerDelegate?

    // bar item
    fileprivate var addPhotoBarItem: UIBarButtonItem!
    fileprivate var removePhotoBarItem: UIBarButtonItem!
    
    fileprivate var mainCollectionView: UICollectionView!

    /// 底部标题
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
        let toolView = PhotoBrowserBottomToolView(safeAreaInsetsBottom: safeAreaInsetsBottom)
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
    
    fileprivate var videoCache: VideoCache?

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

    fileprivate var resized = false

    // MARK: Video properties
    var player: AVPlayer?
    var mPlayerItem: AVPlayerItem?
    var isPlaying = false {
        willSet {
            if currentPhoto.isVideo {
                updateBottomViewPlayButton(newValue)
//                updateToolBarItems(isPlaying: newValue)
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
    private var seekToZeroBeforePlay: Bool = false

    var currentDisplayedIndexPath: IndexPath {
        willSet {
            stopPlayingIfNeeded()
            currentPhoto = photos[newValue.item]
            if currentDisplayedIndexPath != newValue {
                delegate?.photoBrowser(self, scrollAt: newValue)
                delegate?.photoBrowser(self, scrollAt: newValue.item)
            }
            if isForSelection {
                updateAddBarItem(at: newValue)
            } else {
                updatePageControl(withPage: newValue.item)
            }
            if supportCaption {
                updateCaption(at: newValue)
            }
            if supportThumbnails {
                if isOperatingMainPhotos {
                    updateThumbnails(at: newValue)
                }
            }
            updateNavigationTitle(at: newValue)
            stopPlayingVideoIfNeeded(at: currentDisplayedIndexPath)
        }
    }
    
    var selectedThumbnailIndexPath: IndexPath? {
        willSet {
            guard isThumbnailIndexPathInitialized else {
                // do nothing when building PhotoBrowserViewController
                return
            }
            guard let idx = newValue else {
                thumbnailsCollectionView.reloadData()
                // 有值 -> 无值， 取消 thumbnail selected 状态
                // 无值 -> 无值， selectedPhotos 改变
                return
            }
            guard idx != selectedThumbnailIndexPath else {
                // 没有选中时，thumbanail collectionView
                return
            }
            guard !isOperatingMainPhotos else { // 点击 thumbnail
                // reload thumbnailsCollectionView when scorlling mainCollectionView
                thumbnailsCollectionView.reloadData()
                return
            }
            // scroll mainCollectionView when selecting thumbnail cell
            let thumbnailPhoto = selectedPhotos[idx.item]
            let mainPhoto = photos[currentDisplayedIndexPath.item]
            if !thumbnailPhoto.isEqualTo(mainPhoto), mainCollectionView.superview != nil {
                if let firstIndex = firstIndexOfPhoto(thumbnailPhoto, in: photos) { // 点击thumbnail cell 滑动主collectionView
                    let mainPhotoIndexPath = IndexPath(item: firstIndex, section: 0)
                    mainCollectionView.scrollToItem(at: mainPhotoIndexPath, at: .centeredHorizontally, animated: true)
                    // scroll to item function doesn't trigger scrollview did end decelerating delegate function
                    currentDisplayedIndexPath = mainPhotoIndexPath
                }
            }
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
        }
    }

    fileprivate var isThumbnailIndexPathInitialized = false
    
    // main data source
    var selectedPhotos: [PhotoProtocol] = [] {
        didSet {
            guard supportThumbnails else { return }
            let assetIdentifiers = selectedPhotos.compactMap { $0.asset?.localIdentifier }
            delegate?.photoBrowser(self, selectedAssets: assetIdentifiers)
            
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
        currentPhoto = photos[currentDisplayedIndexPath.item]
                
        super.init(nibName: nil, bundle: nil)
        
        mainCollectionView = generateMainCollectionView()
    }
    
    public static func create(photos: [PhotoProtocol],
                              initialIndex: Int,
                              builder: ((Builder) -> Builder)?) -> PhotoBrowserViewController {
        let photoBrowser = PhotoBrowserViewController(photos: photos, initialIndex: initialIndex)
        let concretBuilder = Builder()
        builder?(concretBuilder).build(photoBrowser)
        return photoBrowser
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
        view.backgroundColor = UIColor.white
        edgesForExtendedLayout = .all
        cachePreviousData()
        // Set this value to true to fix a bug: when NavigationBar is opaque, photoBrowser show navigationbar again after hiding it,
        // but photoBrowser view is under a navigationBar height space
        extendedLayoutIncludesOpaqueBars = true
        setupVideoCache()
        setupCollectionView()
        setupNavigationBar()
        setupBottomToolBar()
        addSubviews()
        self.view.bringSubviewToFront(bottomToolView)
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
        stopPlayingIfNeeded()
        restorePreviousNavigationControllerData()
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
    
    func addSubviews() {
        addCollectionView()
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
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 20
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        flowLayout.scrollDirection = .horizontal
        return UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    }
    
    func generateThumbnailsCollectionView() -> UICollectionView {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 10
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 70, height: 70)
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        return UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    }
    
    func setupCollectionView() {
        mainCollectionView.register(PhotoDetailCell.self, forCellWithReuseIdentifier: PhotoDetailCell.reuseIdentifier)
        mainCollectionView.register(VideoDetailCell.self, forCellWithReuseIdentifier: VideoDetailCell.reuseIdentifier)
        mainCollectionView.isPagingEnabled = true
        mainCollectionView.delegate = self
        mainCollectionView.dataSource = self
//        collectionView.backgroundColor = .white
        mainCollectionView.contentInsetAdjustmentBehavior = .never
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
        button.setTitleColor(UIColor(red: 24/255.0, green: 135/255.0, blue: 251/255.0, alpha: 1), for: .normal)
        return button
    }()
    
    func setupNavigationBar() {
//        self.navigationController?.navigationBar.tintColor = .white
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
        collectionView.backgroundColor = UIColor.init(white: 0.1, alpha: 0.9)
        collectionView.contentInsetAdjustmentBehavior = .never
        return collectionView
    }()
        
    func addThumbnailCollectionView() {
        view.addSubview(thumbnailsCollectionView)
        thumbnailsCollectionView.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
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
                captionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
            ])
        } else {
            NSLayoutConstraint.activate([
                captionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
                captionView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),
                captionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
            ])
        }
    }
    
    func addCollectionView() {
        view.addSubview(mainCollectionView)
        mainCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainCollectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
            mainCollectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            mainCollectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            mainCollectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
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
            let photo = photos[indexPath.item]
            if photo.isVideo {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoDetailCell.reuseIdentifier,
                                                                 for: indexPath) as? VideoDetailCell {
                    return cell
                }
            } else {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoDetailCell.reuseIdentifier,
                                                                 for: indexPath) as? PhotoDetailCell {
                    cell.maximumZoomScale = 2
                    return cell
                }
            }
        } else { // thumbnails
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PBSelectedPhotosThumbnailCell.reuseIdentifier,
                                                             for: indexPath) as? PBSelectedPhotosThumbnailCell {
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

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        stopPlayingVideoIfNeeded(at: currentDisplayedIndexPath)
        var photo = photos[indexPath.item]
        photo.targetSize = assetSize
        if photo.isVideo {
            if let videoCell = cell as? VideoDetailCell {
                videoCell.photo = photo
                // setup video player
                setupPlayer(photo: photo, for: videoCell.playerView)
            }
        } else {
            if let photoCell = cell as? PhotoDetailCell {
                photoCell.photo = photo
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.thumbnailsCollectionView {
            isOperatingMainPhotos = false
            selectedThumbnailIndexPath = indexPath
        }
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // Device rotating
        // Instruct collection view how to handle changes in page size

        recalculateItemSize(inBoundingSize: size)
        if view.window == nil {
            view.frame = CGRect(origin: view.frame.origin, size: size)
            view.layoutIfNeeded()
        } else {
            let indexPath = self.mainCollectionView.indexPathsForVisibleItems.last
            coordinator.animate(alongsideTransition: { ctx in
                self.mainCollectionView.layoutIfNeeded()
                if let indexPath = indexPath {
                    self.mainCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                }
            }, completion: { _ in

            })
        }

        super.viewWillTransition(to: size, with: coordinator)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.mainCollectionView.frame != view.frame.insetBy(dx: -10.0, dy: 0.0) {
            self.mainCollectionView.frame = view.frame.insetBy(dx: -10.0, dy: 0.0)
        }
        if !resized && view.bounds.size != .zero {
            resized = true
            recalculateItemSize(inBoundingSize: view.bounds.size)
        }

        if (!self.initialScrollDone) {
            self.initialScrollDone = true
            self.mainCollectionView.scrollToItem(at: currentDisplayedIndexPath, at: .centeredHorizontally, animated: false)
            if isForSelection {
                updateAddBarItem(at: currentDisplayedIndexPath)
            }
            if supportCaption {
                updateCaption(at: currentDisplayedIndexPath)
            }
        }
    }

    // MARK: Bar item actions
    @objc func doneBarButtonClicked(_ sender: UIBarButtonItem) {
        assert(!selectedPhotos.isEmpty, "photos shouldn't be empty")
        delegate?.photoBrowser(self, didCompleteSelected: selectedPhotos)
    }
    
    @objc func addPhotoBarItemClicked(_ sender: UIButton) {
        defer {
            bottomToolView.disableDoneButton(selectedPhotos.isEmpty)
        }

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

        // update bar item: add, done
        if let firstIndex = firstIndexOfPhoto(photo, in: selectedPhotos) {
            updateAddBarItem(title: "\(firstIndex + 1)")
        }
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
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
        
    }
    
    func updateBottomViewPlayButton(_ showPlay: Bool) {
        bottomToolView.isPlaying = showPlay
    }

    func updateAddBarItem(at indexPath: IndexPath) {
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
    
    func updateAddBarItem(title: String) {
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

    func updateCaption(at indexPath: IndexPath) {
        let photo = photos[indexPath.item]
        captionView.setup(content: photo.captionContent, signature: photo.captionSignature)
    }

    func updateNavigationTitle(at indexPath: IndexPath) {
        if supportNavigationBar {
            if isForSelection {
                navigationItem.title = ""
            } else {
                navigationItem.title = "\(indexPath.item + 1)/\(photos.count)"
            }
        }
    }
    
    func updateThumbnails(at indexPath: IndexPath) {
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
    
    // MARK: Target action
    @objc func playerItemDidReachEnd(_ notification: Notification) {
        isPlaying = false
        seekToZeroBeforePlay = true
    }

    func recalculateItemSize(inBoundingSize size: CGSize) {
        guard let flowLayout = mainFlowLayout else { return }
        let itemSize = recalculateLayout(flowLayout,
                                         inBoundingSize: size)
        let scale = UIScreen.main.scale
        assetSize = CGSize(width: itemSize.width * scale, height: itemSize.height * scale)
    }

    @discardableResult
    func recalculateLayout(_ layout: UICollectionViewFlowLayout, inBoundingSize size: CGSize) -> CGSize {
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        layout.scrollDirection = .horizontal;
        layout.minimumLineSpacing = 20
        layout.itemSize = size
        return size
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        stopPlayingIfNeeded()
        player = nil
    }
}

extension PhotoBrowserViewController: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        let pageWidth = view.bounds.size.width
//        let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
        if scrollView == mainCollectionView {
            isOperatingMainPhotos = true
            let indexPath = mainCollectionView.indexPathsForVisibleItems.last ?? IndexPath(row: 0, section: 0)
            currentDisplayedIndexPath = indexPath
        }
    }
}

// MARK: - Router event
extension PhotoBrowserViewController {
    override func routerEvent(name: String, userInfo: [AnyHashable : Any]?) {
        if let tap = ImageViewGestureEvent(rawValue: name) {
            switch tap {
            case .singleTap:
                hideOrShowTopBottom()
            case .doubleTap:
                handleDoubleTap(userInfo)
            case .longPress:
                handleLongPress()
            }
        } else {
            // pass the event
            next?.routerEvent(name: name, userInfo: userInfo)
        }
    }

    fileprivate func hideOrShowTopBottom() {
        if supportNavigationBar {
            self.navigationController?.setNavigationBarHidden(!(self.navigationController?.isNavigationBarHidden ?? true), animated: true)
        }
        
        if supportBottomToolBar {
            let toolViewIsHidden = bottomToolView.isHidden
            let constant: CGFloat = toolViewIsHidden ? 0 : bottomToolViewHeight
            if toolViewIsHidden {
                self.bottomToolView.isHidden = false
            }
            UIView.animate(withDuration: 0.35) {
                self.bottomToolViewBottomConstraint?.constant = constant
                self.bottomToolView.layoutIfNeeded()
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

    fileprivate func handleDoubleTap(_ userInfo: [AnyHashable : Any]?) {
        if let userInfo = userInfo, let mediaType = userInfo["mediaType"] as? String {
            let cfstring = mediaType as CFString
            switch cfstring {
            case kUTTypeImage:
                if let touchPoint = userInfo["touchPoint"] as? CGPoint,
                   let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) as? PhotoDetailCell  {
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
    
    func handleLongPress() {
        guard !isForSelection else {
            return
        }
        // long press only work for pure browser, not for selection
        if let cell = mainCollectionView.cellForItem(at: currentDisplayedIndexPath) as? CellWithPhotoProtocol,
           let photo = cell.photo {
            delegate?.photoBrowser(self, longPressedOnPhoto: photo)
        }
    }
}

// MARK: - Video
extension PhotoBrowserViewController {
    fileprivate func setupPlayer(photo: PhotoProtocol, for playerView: PlayerView) {
        if let asset = photo.asset {
            setupPlayer(asset: asset, for: playerView)
        } else if let url = photo.url {
            setupPlayer(url: url, for: playerView)
        }
    }

    fileprivate func setupPlayer(asset: PHAsset, for playerView: PlayerView) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress, error, stop, info in
            print("request video from icloud progress: \(progress)")
        }
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { (item, info) in
            if let item = item {
                let player = self.preparePlayer(with: item)
                playerView.player = player
                self.player = player
            }
        }
    }
    
    fileprivate func setupPlayer(url: URL, for playerView: PlayerView) {
        if url.isFileURL {
            setupPlayerView(url, playerView: playerView)
        } else {
            if let cache = videoCache {
                cache.fetchFilePathWith(key: url) { (result) in
                    switch result {
                    case .success(let filePath):
                        self.setupPlayerView(filePath, playerView: playerView)
                    case .failure(let error):
                        print("FYPhoto fetch url error: \(error)")
                    }
                }
            } else {
                setupPlayerView(url, playerView: playerView)
            }
        }
    }
    
    fileprivate func setupPlayerView(_ url: URL, playerView: PlayerView) {
        // Create a new AVPlayerItem with the asset and an
        // array of asset keys to be automatically loaded
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: self.assetKeys)
        let player = self.preparePlayer(with: playerItem)
        playerView.player = player
        self.player = player
    }
    
    fileprivate func preparePlayer(with playerItem: AVPlayerItem) -> AVPlayer {
        if let currentItem = mPlayerItem {
            playerItemStatusToken?.invalidate()
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: currentItem)
        }
        self.mPlayerItem = playerItem
        // observing the player item's status property
        playerItemStatusToken = playerItem.observe(\.status, options: .new) { (item, change) in
            // Switch over status value
            switch change.newValue {
            case .readyToPlay:
                print("Player item is ready to play.")
            // Player item is ready to play.
            case .failed:
                print("Player item failed. See error.")
            // Player item failed. See error.
            case .unknown:
                print("unknown status")
            // Player item is not yet ready.
            case .none:
                break
            @unknown default:
                fatalError()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)

        seekToZeroBeforePlay = false
        // Associate the player item with the player

        if let player = self.player {
            player.pause()
            player.replaceCurrentItem(with: playerItem)
            return player
        } else {
            return AVPlayer(playerItem: playerItem)
        }
    }

    fileprivate func playVideo() {
        guard let player = player else { return }
        if seekToZeroBeforePlay {
            seekToZeroBeforePlay = false
            player.seek(to: .zero)
        }

        player.play()
        isPlaying = true
    }

    fileprivate func pauseVideo() {
        player?.pause()
        isPlaying = false
    }

    fileprivate func stopPlayingIfNeeded() {
        guard let player = player, isPlaying else {
            return
        }
        player.pause()
        player.seek(to: .zero)
        isPlaying = false
    }
    
    func stopPlayingVideoIfNeeded(at oldIndexPath: IndexPath) {
        if isPlaying {
            stopPlayingIfNeeded()
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
