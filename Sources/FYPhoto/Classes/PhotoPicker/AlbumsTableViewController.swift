//
//  AlbumsTableViewController.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/30.
//

import UIKit
import Photos

protocol AlbumsTableViewControllerDelegate: AnyObject {
    func albumsTableViewController(_ albums: AlbumsTableViewController, didSelectPhassetAt indexPath: IndexPath)
}

class AlbumsTableViewController: UITableViewController {
    // MARK: Types for managing sections, cell, and segue identifiers
    enum Section: Int {
        case recentPhotos = 0
        case smartAlbums
        case userCollections

        static let count = 3
    }

    enum CellIdentifier: String {
        case allPhotos, collection
    }

    weak var delegate: AlbumsTableViewControllerDelegate?

    let allPhotos: PHFetchResult<PHAsset>
    let smartAlbums: [PHAssetCollection]!
    let userCollections: PHFetchResult<PHCollection>

    let sectionLocalizedTitles = ["", L10n.smartAlbums, L10n.userAlbums]

    var selectedIndexPath: IndexPath

    /// 封面
    fileprivate let coverSize = CGSize(width: 50, height: 50)

    fileprivate let coverPlaceholder = Asset.coverPlaceholder.image

//    <a target="_blank" href="https://icons8.com/icons/set/full-image">Full Image icon</a> icon by <a target="_blank" href="https://icons8.com">Icons8</a>
    init(allPhotos: PHFetchResult<PHAsset>,
         smartAlbums: [PHAssetCollection],
         userCollections: PHFetchResult<PHCollection>,
         selectedIndexPath: IndexPath) {
        self.allPhotos = allPhotos
        self.smartAlbums = smartAlbums
        self.userCollections = userCollections
        self.selectedIndexPath = selectedIndexPath
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print(#function, #file)
    }
    override func viewDidLoad() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier.allPhotos.rawValue)
        tableView.register(AlbumCell.self, forCellReuseIdentifier: CellIdentifier.collection.rawValue)
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return sectionLocalizedTitles.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .recentPhotos: return 1

        case .smartAlbums: return smartAlbums.count
        case .userCollections: return userCollections.count
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell!
        switch Section(rawValue: indexPath.section)! {
        case .recentPhotos:
            cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.allPhotos.rawValue, for: indexPath)
            cell.textLabel?.text = L10n.allPhotos
        case .smartAlbums:
            let albumCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.collection.rawValue, for: indexPath) as! AlbumCell
            albumCell.name = smartAlbums[indexPath.row].localizedTitle
            albumCell.cover = coverPlaceholder
            PhotoPickerResource.shared.fetchCover(in: smartAlbums[indexPath.row], targetSize: coverSize, options: nil) { (image) in
                albumCell.cover = image ?? self.coverPlaceholder
            }
            cell = albumCell
        case .userCollections:
            let albumCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.collection.rawValue, for: indexPath) as! AlbumCell
            albumCell.name = userCollections.object(at: indexPath.row).localizedTitle
            albumCell.cover = coverPlaceholder
            if let assetCollection = userCollections.object(at: indexPath.row) as? PHAssetCollection {
                PhotoPickerResource.shared.fetchCover(in: assetCollection, targetSize: coverSize, options: nil) { (image) in
                    albumCell.cover = image ?? self.coverPlaceholder
                }
            }
            cell = albumCell
        }
        if selectedIndexPath == indexPath {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionLocalizedTitles[section]
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark

        let preCell = tableView.cellForRow(at: selectedIndexPath)
        preCell?.accessoryType = .none

        selectedIndexPath = indexPath
        delegate?.albumsTableViewController(self, didSelectPhassetAt: indexPath)

        dismiss(animated: true, completion: nil)
    }
}
