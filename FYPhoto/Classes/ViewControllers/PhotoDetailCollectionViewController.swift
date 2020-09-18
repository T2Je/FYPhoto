//
//  PhotoDetailCollectionViewController.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/27.
//

import UIKit
import Photos

private let photoCellReuseIdentifier = "PhotoDetailCell"
private let videoCellReuseIdentifier = "VideoDetailCell"


public protocol PhotoDetailCollectionViewControllerDelegate: class {
    func showNavigationBar(in photoDetail: PhotoDetailCollectionViewController) -> Bool
    func showBottomToolBar(in photoDetail: PhotoDetailCollectionViewController) -> Bool
    func canSelectPhoto(in photoDetail: PhotoDetailCollectionViewController) -> Bool
    func canEditPhoto(in photoDetail: PhotoDetailCollectionViewController) -> Bool
    func canDisplayCaption(in photoDetail: PhotoDetailCollectionViewController) -> Bool

    func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, scrollAt indexPath: IndexPath)
    func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, selectedPhotos indexPaths: [IndexPath])
    func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, didCompleteSelected photos: [PhotoProtocol])
}

public extension PhotoDetailCollectionViewControllerDelegate {
    func showNavigationBar(in photoDetail: PhotoDetailCollectionViewController) -> Bool {
        true
    }
    func showBottomToolBar(in photoDetail: PhotoDetailCollectionViewController) -> Bool {
        false
    }

    func canSelectPhoto(in photoDetail: PhotoDetailCollectionViewController) -> Bool {
        false
    }
    func canEditPhoto(in photoDetail: PhotoDetailCollectionViewController) -> Bool {
        false
    }
    func canDisplayCaption(in photoDetail: PhotoDetailCollectionViewController) -> Bool {
        false
    }

    func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, scrollAt indexPath: IndexPath) {

    }
    func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, selectedPhotos indexPaths: [IndexPath]) {

    }
    func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, didCompleteSelected photos: [PhotoProtocol]) {

    }
}

public class PhotoDetailCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    public weak var delegate: PhotoDetailCollectionViewControllerDelegate?

    var selectedPhotos: [PhotoProtocol] = []

    var selectedPhotoIndexPaths: [IndexPath] = [] {
        willSet {
            delegate?.photoDetail(self, selectedPhotos: newValue)
        }
    }

    /// the maximum number of photos you can select
    var maximumNumber: Int = 0

    // bar item
    fileprivate var doneBarItem: UIBarButtonItem!
    fileprivate var addPhotoBarItem: UIBarButtonItem!

    fileprivate let photos: [PhotoProtocol]

    fileprivate let imageManager = PHCachingImageManager()

    fileprivate let collectionView: UICollectionView

    fileprivate let captionView = CaptionView()

    fileprivate var lastDisplayedIndexPath: IndexPath {
        willSet {
            if lastDisplayedIndexPath != newValue {
                delegate?.photoDetail(self, scrollAt: newValue)
            }

            if let canSelect = delegate?.canSelectPhoto(in: self), canSelect {
                updateAddBarItem(at: newValue)
            }

            if let canDisplay = delegate?.canDisplayCaption(in: self), canDisplay {
                updateCaption(at: newValue)
            }

            updateNavigationTitle(at: newValue)

            stopPlayingVideoIfNeeded(at: lastDisplayedIndexPath)
        }
    }

    fileprivate var initialScrollDone = false

    fileprivate let addLocalizedString = "add".photoTablelocalized

    fileprivate var previousNavigationBarHidden: Bool?
    fileprivate var previousToolBarHidden: Bool?
    fileprivate var previousInteractivePop: Bool?
    fileprivate var previousNavigationTitle: String?

    fileprivate var originCaptionTransform: CGAffineTransform!

    fileprivate var flowLayout: UICollectionViewFlowLayout? {
        return collectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }

    fileprivate var assetSize: CGSize?

    // MARK: - LifeCycle
    public init(photos: [PhotoProtocol], initialIndex: Int) {
        self.photos = photos
        self.lastDisplayedIndexPath = IndexPath(row: initialIndex, section: 0)
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 20
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        flowLayout.scrollDirection = .horizontal
//        flowLayout.itemSize = frame.size
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print(#file, #function, "☠️☠️☠️☠️☠️☠️")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = true
        view.backgroundColor = UIColor.white
        edgesForExtendedLayout = .all

        previousToolBarHidden = self.navigationController?.toolbar.isHidden
        previousNavigationBarHidden = self.navigationController?.navigationBar.isHidden
        previousInteractivePop = self.navigationController?.interactivePopGestureRecognizer?.isEnabled
        previousNavigationTitle = self.navigationController?.navigationItem.title

        view.addSubview(collectionView)
        view.addSubview(captionView)

        setupCollectionView()

        setupNavigationBar()
        setupNavigationToolBar()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        makeConstraints()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        if let showNavigationBar = delegate?.showNavigationBar(in: self) {
            self.navigationController?.setNavigationBarHidden(!showNavigationBar, animated: true)
        } else {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
        }

        if let showToolBar = delegate?.showBottomToolBar(in: self) {
            self.navigationController?.setToolbarHidden(!showToolBar, animated: true)
        } else {
            self.navigationController?.setToolbarHidden(true, animated: false)
        }

        originCaptionTransform = captionView.transform
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreNavigationControllerData()
    }

    func setupCollectionView() {
        collectionView.register(PhotoDetailCell.self, forCellWithReuseIdentifier: photoCellReuseIdentifier)
        collectionView.register(VideoDetailCell.self, forCellWithReuseIdentifier: videoCellReuseIdentifier)
        collectionView.isPagingEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
//        collectionView.backgroundColor = .white
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        self.automaticallyAdjustsScrollViewInsets = false
    }

    func setupNavigationBar() {
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        if let canSelect = delegate?.canSelectPhoto(in: self), canSelect {
            addPhotoBarItem = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(PhotoDetailCollectionViewController.addPhotoBarItemClicked(_:)))
            addPhotoBarItem.title = addLocalizedString
            addPhotoBarItem.tintColor = .black
            self.navigationItem.rightBarButtonItem = addPhotoBarItem
        }
        updateNavigationTitle(at: lastDisplayedIndexPath)
    }

    func setupNavigationToolBar() {
        if let canSelect = delegate?.canSelectPhoto(in: self), canSelect {
            doneBarItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(PhotoDetailCollectionViewController.doneBarButtonClicked(_:)))
            doneBarItem.isEnabled = !selectedPhotos.isEmpty
            let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
            self.setToolbarItems([spaceItem, doneBarItem], animated: false)
        }
    }

    fileprivate func restoreNavigationControllerData() {
        if let title = previousNavigationTitle {
            navigationItem.title = title
        }

        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = previousInteractivePop ?? true

        if let originalIsNavigationBarHidden = previousNavigationBarHidden {
            navigationController?.setNavigationBarHidden(originalIsNavigationBarHidden, animated: false)
        }
        // Drag to dismiss quickly canceled, may result in a navigation hide animation bug
        if let originalToolBarHidden = previousToolBarHidden {
            //            navigationController?.setToolbarHidden(originalToolBarHidden, animated: false)
            navigationController?.isToolbarHidden = originalToolBarHidden
        }
    }

    func makeConstraints() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])

        captionView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                captionView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
                captionView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
                captionView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            ])
        } else {
            NSLayoutConstraint.activate([
                captionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10),
                captionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -10),
                captionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10),
            ])
        }
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
        return photos.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let collectionCell: UICollectionViewCell
        let photo = photos[indexPath.row]
        if photo.isVideo {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: videoCellReuseIdentifier, for: indexPath) as? VideoDetailCell {                
                return cell
            }
        } else {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellReuseIdentifier, for: indexPath) as? PhotoDetailCell {
                cell.maximumZoomScale = 2
                return cell
            }
        }

        return UICollectionViewCell()
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        stopPlayingVideoIfNeeded(at: lastDisplayedIndexPath)

        var photo = photos[indexPath.row]
        photo.assetSize = assetSize
        if photo.isVideo {
            if let videoCell = cell as? VideoDetailCell {
                videoCell.photo = photo
            }
        } else {
            if let photoCell = cell as? PhotoDetailCell {
                photoCell.setPhoto(photo)
            }
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
            let indexPath = self.collectionView.indexPathsForVisibleItems.last
            coordinator.animate(alongsideTransition: { ctx in
                self.collectionView.layoutIfNeeded()
                if let indexPath = indexPath {
                    self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                }
            }, completion: { _ in

            })
        }

        super.viewWillTransition(to: size, with: coordinator)
    }

    var resized = false

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.collectionView.frame != view.frame.insetBy(dx: -10.0, dy: 0.0) {
            self.collectionView.frame = view.frame.insetBy(dx: -10.0, dy: 0.0)
        }
        if !resized && view.bounds.size != .zero {
            resized = true
            recalculateItemSize(inBoundingSize: view.bounds.size)
        }

        if (!self.initialScrollDone) {
            self.initialScrollDone = true
            self.collectionView.scrollToItem(at: lastDisplayedIndexPath, at: .centeredHorizontally, animated: false)
            if let canSelect = delegate?.canSelectPhoto(in: self), canSelect {
                updateAddBarItem(at: lastDisplayedIndexPath)
            }
            if let canDisplay = delegate?.canDisplayCaption(in: self), canDisplay {
                updateCaption(at: lastDisplayedIndexPath)
            }
        }
    }

    // MARK: -Bar item actions
    @objc func doneBarButtonClicked(_ sender: UIBarButtonItem) {
        assert(!selectedPhotos.isEmpty, "photos shouldn't be empty")
        delegate?.photoDetail(self, didCompleteSelected: selectedPhotos)
    }

    @objc func addPhotoBarItemClicked(_ sender: UIBarButtonItem) {
        defer {
            doneBarItem.isEnabled = !selectedPhotos.isEmpty
        }

        let photo = photos[lastDisplayedIndexPath.row]

        // already added, remove it from selections
        if let exsit = firstIndexOfPhoto(photo, in: selectedPhotos) {
            selectedPhotos.remove(at: exsit)
            addPhotoBarItem.title = addLocalizedString
            addPhotoBarItem.tintColor = .black
            selectedPhotoIndexPaths.remove(at: exsit)
            return
        }

        // add photo
        selectedPhotos.append(photo)
        selectedPhotoIndexPaths.append(lastDisplayedIndexPath)

        // update bar item: add, done
        if let firstIndex = firstIndexOfPhoto(photo, in: selectedPhotos) {
            addPhotoBarItem.title = "\(firstIndex + 1)"
            addPhotoBarItem.tintColor = .systemBlue
        }

        // filter different media type
    }

    func updateAddBarItem(at indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        guard let firstIndex = firstIndexOfPhoto(photo, in: selectedPhotos) else {
            addPhotoBarItem.title = addLocalizedString
            addPhotoBarItem.isEnabled = selectedPhotos.count < maximumNumber
            addPhotoBarItem.tintColor = .black
            return
        }
        addPhotoBarItem.isEnabled = true
        addPhotoBarItem.title = "\(firstIndex + 1)"
        addPhotoBarItem.tintColor = .systemBlue
    }

    func stopPlayingVideoIfNeeded(at oldIndexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: oldIndexPath) as? VideoDetailCell else { return }
        cell.stopPlayingIfNeeded()
    }

    func updateCaption(at indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        captionView.setup(content: photo.captionContent, signature: photo.captionSignature)
    }

    func updateNavigationTitle(at indexPath: IndexPath) {
        if let showNavigationBar = delegate?.showNavigationBar(in: self), showNavigationBar {
            if let canSelect = delegate?.canSelectPhoto(in: self), canSelect {
                navigationItem.title = ""
            } else {
                navigationItem.title = "\(indexPath.item + 1) /\(photos.count)"
            }
        }
    }

    func recalculateItemSize(inBoundingSize size: CGSize) {
        guard let flowLayout = flowLayout else { return }
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
}

extension PhotoDetailCollectionViewController: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = view.bounds.size.width
        let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
        lastDisplayedIndexPath = IndexPath(row: currentPage, section: 0)
    }
}

// MARK: - Router event
extension PhotoDetailCollectionViewController {
    override func routerEvent(name: String, userInfo: [AnyHashable : Any]?) {
        if let tap = ImageViewTap(rawValue: name) {
            switch tap {
            case .singleTap:
                hideOrShowTopBottom()
//                use navigationController?.hidesBarsOnTap instead
//                break
            case .doubleTap:
                guard let userInfo = userInfo, let touchPoint = userInfo["touchPoint"] as? CGPoint  else { return }
                guard let cell = collectionView.cellForItem(at: lastDisplayedIndexPath) as? PhotoDetailCell else { return }
                handleDoubleTap(touchPoint, on: cell)
            }
        } else {
            // pass the event
            next?.routerEvent(name: name, userInfo: userInfo)
        }
    }
    func hideOrShowTopBottom() {
        if let showNavigationBar = delegate?.showNavigationBar(in: self), showNavigationBar {
            self.navigationController?.setNavigationBarHidden(!(self.navigationController?.isNavigationBarHidden ?? true), animated: true)
        }

        if let showToolBar = delegate?.showBottomToolBar(in: self), showToolBar {
            self.navigationController?.setToolbarHidden(!(self.navigationController?.isToolbarHidden ?? true), animated: true)
        }

        if let canDisplay = delegate?.canDisplayCaption(in: self), canDisplay {
            hideCaptionView(!captionView.isHidden)
        }
    }

    func handleDoubleTap(_ touchPoint: CGPoint, on cell: PhotoDetailCell) {
        let scale = min(cell.zoomingView.zoomScale * 2, cell.zoomingView.maximumZoomScale)
        if cell.zoomingView.zoomScale == 1 {
            let zoomRect = zoomRectForScale(scale: scale, center: touchPoint, for: cell.zoomingView)
            cell.zoomingView.zoom(to: zoomRect, animated: true)
        } else {
            cell.zoomingView.setZoomScale(1, animated: true)
        }
    }

    func zoomRectForScale(scale: CGFloat, center: CGPoint, for scroolView: UIScrollView) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = scroolView.frame.size.height / scale
        zoomRect.size.width  = scroolView.frame.size.width  / scale

        zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
}

// MARK: - PhotoDetailTransitionAnimatorDelegate
extension PhotoDetailCollectionViewController: PhotoTransitioning {

    public func transitionWillStart() {
        guard let cell = collectionView.cellForItem(at: lastDisplayedIndexPath) else { return }
        cell.isHidden = true
    }

    public func transitionDidEnd() {
        guard let cell = collectionView.cellForItem(at: lastDisplayedIndexPath) else { return }
        cell.isHidden = false
    }

    public func referenceImage() -> UIImage? {
        if let cell = collectionView.cellForItem(at: lastDisplayedIndexPath) as? PhotoDetailCell {
            return cell.image
        }
        if let cell = collectionView.cellForItem(at: lastDisplayedIndexPath) as? VideoDetailCell {
            return cell.image
        }
        return nil
    }

    public func imageFrame() -> CGRect? {
        if let cell = collectionView.cellForItem(at: lastDisplayedIndexPath) as? PhotoDetailCell {
            return CGRect.makeRect(aspectRatio: cell.image?.size ?? .zero, insideRect: cell.bounds)
        }
        if let cell = collectionView.cellForItem(at: lastDisplayedIndexPath) as? VideoDetailCell {
            return CGRect.makeRect(aspectRatio: cell.image?.size ?? .zero, insideRect: cell.bounds)
        }
        return nil
    }
}

extension PhotoDetailCollectionViewController {
    func firstIndexOfPhoto(_ photo: PhotoProtocol, in photos: [PhotoProtocol]) -> Int? {
        if let equals = selectedPhotos as? [Photo], let photo = photo as? Photo {
            let index = equals.firstIndex(of: photo)

            return index
        } else {
            let index = selectedPhotos.firstIndex { (photoPro) -> Bool in
                if let proAsset = photoPro.asset, let photoAsset = photo.asset {
                    return proAsset.localIdentifier == photoAsset.localIdentifier
                }
                if let proURL = photoPro.url, let photoURL = photo.url {
                    return proURL == photoURL
                }
                return photoPro.index == photo.index
            }
            return index
        }
    }

}
