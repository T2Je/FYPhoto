//
//  AddPhotoBlogViewController.swift
//  FYPhotoPicker_Example
//
//  Created by xiaoyang on 2020/7/31.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import FYPhoto
import FGBase

private let cellIdentifier = "AddPhotoCollectionViewCell"

@objc class AddPhotoBlogViewController: BaseViewController {

    fileprivate var dataSource = [UIImage]()

    var hasAddButton = true

    var textView: FGPlaceholderTextViewSwift!
    let textCountLabel = UILabel()

    var lastSelectedIndexPath: IndexPath?

    var isInteractivelyDismissing = true

    @objc var selectedImageArray: [UIImage] = [] {
        willSet {
            dataSource = newValue
            if newValue.count < photosLimited {
                hasAddButton = true
                if let defaultPhoto = UIImage(named: "add_photo") {
                    dataSource.append(defaultPhoto)
                }
            } else {
                hasAddButton = false
            }
            collectionView.reloadData()
        }
    }

    fileprivate lazy var detailFlowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = self.view.bounds.size
        flowLayout.minimumInteritemSpacing = 30
        flowLayout.minimumLineSpacing = 0
        flowLayout.scrollDirection = .horizontal
        return flowLayout
    }()

    var collectionView: UICollectionView!
    var transitionController: PhotoTransitionController?

    let photoLauncher = PhotoLauncher()

    fileprivate let maxCharLength = 100
    fileprivate let maxWidthImage = 612
    fileprivate let photosLimited = 6

    init() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 100, height: 100)
        flowLayout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        flowLayout.minimumInteritemSpacing = 10

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        edgesForExtendedLayout = .all
        setupTextView()
        setupTextRemainLabel()
        setupCollectionView()
        addViews()
        addGestures()
        setupNavigation()
        setupTransitionController()
        photoLauncher.delegate = self
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func setupTransitionController() {
        guard let navigationController = self.navigationController else { return }
        transitionController = PhotoTransitionController(navigationController: navigationController)
        navigationController.delegate = transitionController
    }

    func setupTextView() {
        textView = FGPlaceholderTextViewSwift(frame: .zero,
                                              placeholder: NSLocalizedString("Text Something", comment: ""),
                                              color: UIColor(red: 66/255.0, green: 66/255.0, blue: 74/255.0, alpha: 1))
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.delegate = self
        textView.backgroundColor = .clear
        textView.placeholderColor = UIColor(red: 155/255.0, green: 155/255.0, blue: 155/255.0, alpha: 1)
    }

    func setupTextRemainLabel() {
        textCountLabel.textColor = UIColor(red: 155/255.0, green: 155/255.0, blue: 155/255.0, alpha: 1)
        textCountLabel.font = UIFont.systemFont(ofSize: 15)
        textCountLabel.textAlignment = .right
        textCountLabel.text = String(format: "%d %@", maxCharLength - self.textView.text.count, NSLocalizedString("Chars left", comment: ""))
    }

    func setupCollectionView() {

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .white
        collectionView.register(AddPhotoCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
    }

    func addViews() {
        view.addSubview(textView)
        view.addSubview(textCountLabel)
        view.addSubview(collectionView)

        textView.translatesAutoresizingMaskIntoConstraints = false
        textCountLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
                textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
                textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
            ])
        } else {
            NSLayoutConstraint.activate([
                textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
                textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
            ])
        }
        textView.heightAnchor.constraint(equalToConstant: 80).isActive = true

        textCountLabel.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 5).isActive = true
        if #available(iOS 11.0, *) {
            textCountLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
        } else {
            textCountLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
        }

        collectionView.topAnchor.constraint(equalTo: textCountLabel.bottomAnchor, constant: 10).isActive = true
        if #available(iOS 11.0, *) {
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10).isActive = true
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50).isActive = true
        } else {
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
        }
    }

    func addGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(AddPhotoBlogViewController.pan(_:)))
        view.addGestureRecognizer(panGesture)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(AddPhotoBlogViewController.longPress(_:)))
        collectionView.addGestureRecognizer(longPress)
    }

    func setupNavigation() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        navigationItem.title = NSLocalizedString("PhotoBlog", comment: "")
        let rightBarItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(AddPhotoBlogViewController.doneBarButtonItem(_:)))
        rightBarItem.tintColor = .white
        navigationItem.rightBarButtonItem = rightBarItem

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .plain, target: self, action: #selector(backBarButton(_:)))
        navigationItem.leftBarButtonItem?.tintColor = .white
    }

    // MARK: Actions
    @objc func pan(_ sender: UIPanGestureRecognizer) {
        view.endEditing(true)
    }

    @objc func longPress(_ gesture: UILongPressGestureRecognizer) {
//        view.endEditing(true)

        switch gesture.state {
        case UIGestureRecognizer.State.began:
            guard let selectedIndexPath = self.collectionView.indexPathForItem(at: gesture.location(in: self.collectionView)) else {
                break
            }
            self.collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case UIGestureRecognizer.State.changed:
            self.collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case UIGestureRecognizer.State.ended:
            self.collectionView.endInteractiveMovement()
        default:
            self.collectionView.cancelInteractiveMovement()
        }
    }

    @objc func backBarButton(_ sender: UIButton) {
        self.view.endEditing(true)
        guard !textView.text.isEmpty || !selectedImageArray.isEmpty else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        let alert = UIAlertController(
            title: nil,
            message: NSLocalizedString("DoQuitFromAddPhotoBlog", comment: ""),
            preferredStyle: .alert)
        let doneAction = UIAlertAction(title: NSLocalizedString("Done", comment: ""), style: .default, handler: { _ in
            self.dismiss(animated: true, completion: nil)
        })
        alert.addAction(doneAction)

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.width / 2, y: view.height / 2, width: 0, height: 0)
        present(alert, animated: true)
    }

    @objc func doneBarButtonItem(_ barButton: UIButton) {
        barButton.isEnabled = false
        guard !selectedImageArray.isEmpty else {
            FGTools.makeToast(NSLocalizedString("At least One Picture", comment: ""), duration: 1.0)
            barButton.isEnabled = true
            return
        }
        self.view.endEditing(true)
        showHUD()
        let text = textView.text ?? ""
//        uploadText(text, images: selectedImageArray, userID: UserManager.shared.user?.uid ?? "", userTrueName: UserManager.shared.user?.trueName ?? "")
    }

//    func uploadText(_ text: String, images: [UIImage], userID: String, userTrueName: String) {
//        let processor = PhotoBlogProccessor()
//        DispatchQueue.global(qos: .default).async {
//            let taskInfo = PhotoBlogRootTask()
//            taskInfo.text = text
//
//            var index = 0
//            var imageArray: [PhotoBlogImage] = []
//
//            for image in images {
//                print(String(format: "orgin image size w is %f, h is %f, data length is %lu", image.size.width, image.size.height, UInt(image.jpegData(compressionQuality: 1.0)?.count ?? 0)))
//                let scaledImage = image.scale(by: (CGFloat(self.maxWidthImage) / (image.size.width ) >= 1.0) ? 1.0 : (CGFloat(self.maxWidthImage) / (image.size.width )))
//                print(String(format: "scaled size w is %f, h is %f, data length is %lu", scaledImage?.size.width ?? 0.0, scaledImage?.size.height ?? 0.0, UInt(scaledImage?.jpegData(compressionQuality: 1.0)?.count ?? 0)))
//
//                if let data = scaledImage?.jpegData(compressionQuality: 0.8) {
//                    let localTaskID = taskInfo.localTaskID ?? ""
//                    let fileName = "\(kBaseLocalPrefix)\(localTaskID)_\(NSNumber(value: index).stringValue).jpg"
//                    let filePath = URL(fileURLWithPath: FileOperation.getUserDir(userID)).appendingPathComponent(fileName)
//                    let isSuccess: Bool
//                    do {
//                        try data.write(to: filePath, options: Data.WritingOptions.atomicWrite)
//                        isSuccess = true
//                    } catch {
//                        print("🤢\(error)🤮")
//                        isSuccess = false
//                    }
//                    print("save image \(NSNumber(value: isSuccess).stringValue)")
//
//                    let blogImage = PhotoBlogImage()
//                    blogImage.imageURLStr = fileName
//                    imageArray.append(blogImage)
//                }
//
//                index += 1
//
//            }
//
//            taskInfo.imageArray = NSMutableArray(array: imageArray)
//
//            taskInfo.subTaskDoneFlag = -1
//            taskInfo.userID = userID
//            taskInfo.createdDate = Date()
//            taskInfo.userName = userTrueName
//
//            processor.startPublishBlog(with: taskInfo)
//
//            DispatchQueue.main.async {
//                self.hideHUD()
//                self.dismiss(animated: true, completion: nil)
//            }
//        }
//    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        textView.setNeedsDisplay()
    }
}

extension AddPhotoBlogViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard let newText = textView.text else { return }

        if maxCharLength - newText.count <= 0 {
            let index = newText.index(newText.startIndex, offsetBy: maxCharLength)
            let subString = newText[..<index]
            textView.text = String(subString)
            self.textCountLabel.text = "\(maxCharLength)/\(maxCharLength)"
        } else {
            self.textCountLabel.text = "\(newText.count)/\(maxCharLength)"
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        var newText = textView.text
        newText?.removeAll { (character) -> Bool in
            return character == " " || character == "\n"
        }

        if let fixed = newText {
            print("fixed count:\(fixed.count), text count:\(text.count)")
            return (fixed.count + text.count) <= maxCharLength + 10
        } else {
            return text.count <= maxCharLength
        }
    }
}

extension AddPhotoBlogViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(photosLimited, dataSource.count)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? AddPhotoCollectionViewCell else { return UICollectionViewCell() }

        let image = dataSource[indexPath.row]
        cell.image = image
        cell.indexPath = indexPath
        cell.delete = { [weak self] idx in
            self?.removePhoto(at: idx.row)
        }
        if indexPath.row == dataSource.count - 1, hasAddButton {
            cell.isAdd = true
        } else {
            cell.isAdd = false
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        lastSelectedIndexPath = indexPath

        guard let cell = collectionView.cellForItem(at: indexPath) as? AddPhotoCollectionViewCell else { return }
        if cell.isAdd {
            // go to grid vc
            if #available(iOS 14, *) {
                photoLauncher.launchSystemPhotoPicker(in: self, maximumNumberCanChoose: photosLimited - selectedImageArray.count)
            } else {
                photoLauncher.launchCustomPhotoLibrary(in: self, maximumNumberCanChoose: photosLimited - selectedImageArray.count)
            }
        } else {
            var photos = [PhotoProtocol]()
            for index in 0..<selectedImageArray.count {
                let photo = Photo.photoWithUIImage(selectedImageArray[index])
                photos.append(photo)                
            }
            
            let photoBrowser = PhotoBrowserViewController.create(photos: photos, initialIndex: indexPath.item) {
                $0.quickBuildJustForBrowser()
                    .showDeleteButtonForBrowser()
            }
            
            photoBrowser.delegate = self
            self.navigationController?.pushViewController(photoBrowser, animated: true)
        }
    }

    func removePhoto(at index: Int) {
        selectedImageArray.remove(at: index)
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let data = dataSource.remove(at: sourceIndexPath.row)
        dataSource.insert(data, at: destinationIndexPath.row)
    }
}

extension AddPhotoBlogViewController: PhotoLauncherDelegate {
    func selectedPhotosInPhotoLauncher(_ photos: [UIImage]) {
        #if DEBUG
        print("selected \(photos.count) photos")
        #endif
        self.selectedImageArray += photos
    }
}

extension AddPhotoBlogViewController: PhotoBrowserViewControllerDelegate {

    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, scrollAt indexPath: IndexPath) {
        lastSelectedIndexPath = indexPath
    }

    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, selectedAssets identifiers: [String]) {

    }

    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, didCompleteSelected photos: [PhotoProtocol]) {

    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowserViewController, deletePhotoAtIndexWhenBrowsing index: Int) {
        selectedImageArray.remove(at: index)
    }

}

extension AddPhotoBlogViewController: PhotoTransitioning {
    public func transitionWillStart() {
        print(#file, #function)
        guard let indexPath = lastSelectedIndexPath else { return }
        collectionView.cellForItem(at: indexPath)?.isHidden = true
    }

    public func transitionDidEnd() {
        print(#file, #function)
        guard let indexPath = lastSelectedIndexPath else { return }
        collectionView.cellForItem(at: indexPath)?.isHidden = false
    }

    public func referenceImage() -> UIImage? {
        guard let indexPath = lastSelectedIndexPath else { return nil }
        guard let cell = collectionView.cellForItem(at: indexPath) as? AddPhotoCollectionViewCell else {
            return nil
        }
        return cell.imageView.image
    }

    public func imageFrame() -> CGRect? {
        guard
            let lastSelected = lastSelectedIndexPath,
            let cell = self.collectionView.cellForItem(at: lastSelected)
        else {
            return nil
        }
        return collectionView.convert(cell.frame, to: self.view)
    }
}
