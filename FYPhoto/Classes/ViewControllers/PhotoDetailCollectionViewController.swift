//
//  PhotoDetailCollectionViewController.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/27.
//

import UIKit
import Photos

private let reuseIdentifier = "PhotoDetailCell"

public protocol PhotoDetailCollectionViewControllerDelegate: class {
    func showNavigationBar(in photoDetail: PhotoDetailCollectionViewController) -> Bool
    func showNavigationToolBar(in photoDetail: PhotoDetailCollectionViewController) -> Bool
    func canSelectPhoto(in photoDetail: PhotoDetailCollectionViewController) -> Bool
    func canEditPhoto(in photoDetail: PhotoDetailCollectionViewController) -> Bool
    func canDisplayCaption(in photoDetail: PhotoDetailCollectionViewController) -> Bool

//    func canShowSelectionButton(in photoDetail: PhotoDetailCollectionViewController) -> Bool
    func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, scrollAt indexPath: IndexPath)
    func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, selectedPhotos indexPaths: [IndexPath])
    func photoDetail(_ photoDetail: PhotoDetailCollectionViewController, didCompleteSelected photos: [PhotoProtocol])
}

public class PhotoDetailCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, PhotoDetailInteractiveDismissTransitionProtocol, PhotoDetailInteractivelyProtocol {
    public var isInteractivelyDismissing: Bool = false

    public weak var transitionController: PhotoDetailInteractiveDismissTransition? = nil

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
        }
    }

    fileprivate var initialScrollDone = false

    fileprivate let addLocalizedString = "add".photoTablelocalized

    fileprivate var originalNavigationBarHidden: Bool?
    fileprivate var originalToolBarHidden: Bool?

    fileprivate var originCaptionTransform: CGAffineTransform!

    // MARK: - LifeCycle
    public init(frame: CGRect, photos: [PhotoProtocol], initialIndex: Int) {
        self.photos = photos
        self.lastDisplayedIndexPath = IndexPath(row: initialIndex, section: 0)
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = frame.size
        flowLayout.minimumInteritemSpacing = 30
        flowLayout.minimumLineSpacing = 0
        flowLayout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: frame, collectionViewLayout: flowLayout)
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print(#file, #function, "☠☠☠☠☠☠☠☠☠☠")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        originalToolBarHidden = self.navigationController?.toolbar.isHidden
        originalNavigationBarHidden = self.navigationController?.navigationBar.isHidden

        view.addSubview(collectionView)
        view.addSubview(captionView)

        setupCollectionView()
//        setupPanGesture()

        setupNavigationBar()
        setupNavigationToolBar()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        makeConstraints()
    }

//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        hideNavigationViews(false, animated: false)
//        // FIXME: ToolBar comes up strangely. Maybe custom setToolIsHidden in CustomNavigationController is the way
//    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let showNavigationBar = delegate?.showNavigationBar(in: self) {
            self.navigationController?.setNavigationBarHidden(!showNavigationBar, animated: animated)
            if showNavigationBar {
                self.navigationController?.navigationBar.alpha = 1
            }
        } else {
            self.navigationController?.setNavigationBarHidden(true, animated: animated)
        }

        if let showToolBar = delegate?.showNavigationToolBar(in: self) {
            self.navigationController?.setToolbarHidden(!showToolBar, animated: animated)
            if showToolBar {
                self.navigationController?.toolbar.alpha = 1
            }
        } else {
            self.navigationController?.setToolbarHidden(true, animated: animated)
        }

        originCaptionTransform = captionView.transform
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let originalIsNavigationBarHidden = originalNavigationBarHidden {
            navigationController?.setNavigationBarHidden(originalIsNavigationBarHidden, animated: animated)
        }
        if let originalToolBarHidden = originalToolBarHidden {
            navigationController?.setToolbarHidden(originalToolBarHidden, animated: animated)
        }
    }

    func setupCollectionView() {
        collectionView.register(PhotoDetailCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.isPagingEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
    }

//    func setupPanGesture() {
//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(PhotoDetailCollectionViewController.dismissPanGestureDidChange(_:)))
//        panGesture.minimumNumberOfTouches = 1
//        panGesture.maximumNumberOfTouches = 1
//        view.addGestureRecognizer(panGesture)
//    }

    func setupNavigationBar() {
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        if let canSelect = delegate?.canSelectPhoto(in: self), canSelect {
            addPhotoBarItem = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(PhotoDetailCollectionViewController.addPhotoBarItemClicked(_:)))
            addPhotoBarItem.title = addLocalizedString
            addPhotoBarItem.tintColor = .black
            self.navigationItem.rightBarButtonItem = addPhotoBarItem
        }
    }

    func setupNavigationToolBar() {
        if let canSelect = delegate?.canSelectPhoto(in: self), canSelect {
            doneBarItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(PhotoDetailCollectionViewController.doneBarButtonClicked(_:)))
            doneBarItem.isEnabled = !selectedPhotos.isEmpty
            let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
            self.setToolbarItems([spaceItem, doneBarItem], animated: false)
        }
    }

    func makeConstraints() {
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
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

    func hideOrShowTopBottom() {
        if let showNavigationBar = delegate?.showNavigationBar(in: self), showNavigationBar {
            self.navigationController?.setNavigationBarHidden(!(self.navigationController?.isNavigationBarHidden ?? true), animated: true)
        }

        if let showToolBar = delegate?.showNavigationToolBar(in: self), showToolBar {
            self.navigationController?.setToolbarHidden(!(self.navigationController?.isToolbarHidden ?? true), animated: false)
        }

        if let canDisplay = delegate?.canDisplayCaption(in: self), canDisplay {
            hideCaptionView(!captionView.isHidden)
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoDetailCell
        cell.imageManager = imageManager
        cell.maximumZoomScale = 2
//        cell.setPhoto(photos[indexPath.row])
        return cell
    }


    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photoCell = cell as! PhotoDetailCell
        photoCell.setPhoto(photos[indexPath.row])
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // instruct collection view how to handle changes in page size
        // print("before")
        let visiblePage = self.collectionView.contentOffset.x / self.collectionView.bounds.size.width
        coordinator.animate(alongsideTransition: { (context) in
//            print("during")

            let newOffset = CGPoint(x: visiblePage * self.collectionView.bounds.size.width, y: self.collectionView.contentOffset.y)

            self.collectionView.contentOffset = newOffset

            guard let flowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
            flowLayout.itemSize = self.view.bounds.size
            flowLayout.invalidateLayout()
        }) { (context) in

            print("after")

        }
        // FIXME: - fix A warining here ⚠️
    }


    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

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

    func updateCaption(at indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        captionView.setup(content: photo.captionContent, signature: photo.captionSignature)
    }
}

extension PhotoDetailCollectionViewController: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.size.width
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
extension PhotoDetailCollectionViewController: AssetTransitioning {
    
    public func transitionWillStart() {
        guard let cell = collectionView.cellForItem(at: lastDisplayedIndexPath) else { return }
        cell.isHidden = true
    }

    public func transitionDidEnd() {
        guard let cell = collectionView.cellForItem(at: lastDisplayedIndexPath) else { return }
        cell.isHidden = false
    }

    public func referenceImage() -> UIImage? {
        guard let cell = collectionView.cellForItem(at: lastDisplayedIndexPath) as? PhotoDetailCell else { return nil }
        return cell.image
    }

    public func imageFrame() -> CGRect? {
        guard let cell = collectionView.cellForItem(at: lastDisplayedIndexPath) as? PhotoDetailCell else { return nil }
        let rect = CGRect.makeRect(aspectRatio: cell.image?.size ?? .zero, insideRect: cell.bounds)
        return rect
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
