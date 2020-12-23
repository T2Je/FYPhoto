//
//  PhotoPickerHelper.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/7/14.
//

import Foundation
import Photos

public class PhotoPickerResource {

    public static var shared = PhotoPickerResource()

    private init() { }

    // image & video
    public func allAssets(ascending: Bool = true) -> PHFetchResult<PHAsset> {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: ascending)]
        return PHAsset.fetchAssets(with: allPhotosOptions)
    }

    public func allImages(_ ascending: Bool = false) -> PHFetchResult<PHAsset> {
        let predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = predicate
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: ascending)]
        return PHAsset.fetchAssets(with: fetchOptions)
    }

    public func smartAlbums() -> PHFetchResult<PHAssetCollection> {
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
    }

    public func userCollection() -> PHFetchResult<PHCollection> {
        return PHCollectionList.fetchTopLevelUserCollections(with: nil)
    }

    /// favorites, selfies, live(>=iOS10.3), panoramas, slomos, videos, screenshots, animated(>= iOS11), longExposure(>= iOS11)
    public func filteredSmartAlbums(isOnlyImage: Bool = false) -> [PHAssetCollection] {
        var albums = [PHAssetCollection]()

        if let favorites = favorites(), !isOnlyImage, favorites.estimatedAssetCount > 0 {
            albums.append(favorites)
        }
        if let selfies = selfies(), selfies.estimatedAssetCount > 0 {
            albums.append(selfies)
        }
        if let live = live(), !isOnlyImage, live.estimatedAssetCount > 0 {
            albums.append(live)
        }
        if let panoramas = panoramas(), panoramas.estimatedAssetCount > 0 {
            albums.append(panoramas)
        }
        if let slomos = slomos(), slomos.estimatedAssetCount > 0 {
            albums.append(slomos)
        }
        if let videos = videos(), !isOnlyImage, videos.estimatedAssetCount > 0 {
            albums.append(videos)
        }
        if let screenShots = screenShots(), screenShots.estimatedAssetCount > 0 {
            albums.append(screenShots)
        }
        if let animated = animated(), animated.estimatedAssetCount > 0 {
            albums.append(animated)
        }
        if let longExposure = longExposure(), longExposure.estimatedAssetCount > 0 {
            albums.append(longExposure)
        }
        //        if let bursts = bursts() {
        //            albums.append(bursts)
        //        }
        return albums
    }

    // MARK: smart albums
    func favorites() -> PHAssetCollection? {
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: nil).firstObject
    }

    // 全景
    func panoramas() -> PHAssetCollection? {
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumPanoramas, options: nil).firstObject
    }

    func videos() -> PHAssetCollection? {
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumVideos, options: nil).firstObject
    }

    func screenShots() -> PHAssetCollection? {
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumScreenshots, options: nil).firstObject
    }

    func selfies() -> PHAssetCollection? {
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSelfPortraits, options: nil).firstObject
    }

    /// 慢动作
    func slomos() -> PHAssetCollection? {
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSlomoVideos, options: nil).firstObject
    }

    @available(iOS 11, *)
    func animated() -> PHAssetCollection? {
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumAnimated, options: nil).firstObject
    }

    func longExposure() -> PHAssetCollection? {
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumLongExposures, options: nil).firstObject
    }

    func live() -> PHAssetCollection? {
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumLivePhotos, options: nil).firstObject
    }

    func bursts() -> PHAssetCollection? {
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumBursts, options: nil).firstObject
    }

    /// 相簿封面
    func fetchCover(in collection: PHAssetCollection, targetSize: CGSize, options: PHFetchOptions? = nil, completion: @escaping ((UIImage?) -> Void)) {
        let keyAssetResult = PHAsset.fetchKeyAssets(in: collection, options: options)
        if let keyAsset = keyAssetResult?.firstObject {
            let imageOptions = PHImageRequestOptions()
            imageOptions.isNetworkAccessAllowed = false
            imageOptions.deliveryMode = .fastFormat
            imageOptions.resizeMode = .fast
            PhotoPickerResource.shared.fetchImage(keyAsset, options: imageOptions) { (image, _) in
                completion(image)
            }
        } else {
            print("doesn't have any key asset")
            completion(nil)
        }
    }

}

extension PhotoPickerResource {
    
    /// Fetch hight quality images synchronously
    /// - Parameters:
    ///   - assets: image assets
    ///   - completion: images call back
    func fetchHighQualityImages(_ assets: [PHAsset], completion: @escaping (([UIImage]) -> Void)) {
        let group = DispatchGroup()
        var requestIDs = [PHImageRequestID]()

        var imagesDic = [PHImageRequestID: UIImage]()

        assets.forEach {
            group.enter()
            let id = fetchImage($0) { (image, requestID)  in
                if let image = image, let requestID = requestID {
                    imagesDic[requestID] = image
                }
                group.leave()
            }
            requestIDs.append(id)
        }

        group.notify(queue: .main) {
            let images = imagesDic.sorted { $0.key < $1.key }.map { $0.value }
            completion(images)
        }
    }

    @discardableResult
    func fetchImage(_ asset: PHAsset, options: PHImageRequestOptions? = nil, completion: @escaping ((UIImage?, PHImageRequestID?) -> Void)) -> PHImageRequestID {
        let _options: PHImageRequestOptions!
        if let options = options {
            _options = options
        } else {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            _options = options
        }

        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)

        return PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .default, options: _options) { (image, info) in
            completion(image, info?["PHImageResultRequestIDKey"] as? PHImageRequestID)
        }
    }
}

extension PhotoPickerResource {

    /// Get time string from timeInterval, timeInterval > 3600, retrun '> 1 hour'. TimeInterval in (60, 3600), return 'xx:yy'.
    /// TimeInterval less than 10, return '00:xx'.
    ///
    /// - Parameter timeInterval: timeInterval
    /// - Returns: e.g. 00:00
    func time(of timeInterval: TimeInterval) -> String {
        // per_minute == 60
        // per_hour == 3600

        guard timeInterval / Double(3600) < 1 else {
            return String(format: "> 1 %@", "hour".photoTablelocalized)
        }
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60

        if minutes == 0 {
            let fixedSeconds = seconds < 10 ? "0\(seconds)" : "\(seconds)"
            return "00:\(fixedSeconds)"
        } else {
            return String(format: "%d:%d", minutes, seconds)
        }
    }
}
