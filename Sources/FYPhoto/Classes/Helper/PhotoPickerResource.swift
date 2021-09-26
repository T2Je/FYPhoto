//
//  PhotoPickerHelper.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/7/14.
//

import Foundation
import Photos
import UIKit

public class PhotoPickerResource {

    static var shared = PhotoPickerResource()

    private init() { }

    // image & video
    public func allAssets(ascending: Bool = false) -> PHFetchResult<PHAsset> {
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
    
    public func allVideos(_ ascending: Bool = false) -> PHFetchResult<PHAsset> {
        let predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
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

    public func getAssets(withMediaOptions options: MediaOptions) -> PHFetchResult<PHAsset> {
        if options == .image {
            return allImages()
        } else if options == .video {
            return allVideos()
        } else {
            return allAssets()
        }
    }
    
    public func getSmartAlbums(withMediaOptions options: MediaOptions) -> [PHAssetCollection] {
        if options == .all {
            if let favoritesAlbum = favorites() {
                return allImageAlbums() + allVideoAlbums() + [favoritesAlbum]
            } else {
                return allImageAlbums() + allVideoAlbums()
            }
        } else if options == .image {
            if let favoritesAlbum = favorites() {
                return allImageAlbums() + [favoritesAlbum]
            } else {
                return allImageAlbums()
            }
        } else if options == .video {
            if let favoritesAlbum = favorites() {
                return allImageAlbums() + [favoritesAlbum]
            } else {
                return allVideoAlbums()
            }
        } else {
            return []
        }
    }
    
    func allImageAlbums() -> [PHAssetCollection] {
        var albums = [PHAssetCollection]()
                
        if let selfies = selfies() {
            if selfies.getAssetCount(.image) > 0 {
                albums.append(selfies)
            }
        }
        if let panoramas = panoramas() {
            if panoramas.getAssetCount(.image) > 0 {
                albums.append(panoramas)
            }
        }
        if let slomos = slomos() {
            if slomos.getAssetCount(.image) > 0 {
                albums.append(slomos)
            }
        }
        if let screenShots = screenShots() {
            if screenShots.getAssetCount(.image) > 0 {
                albums.append(screenShots)
            }
        }
        if let animated = animated() {
            if animated.getAssetCount(.image) > 0 {
                albums.append(animated)
            }
        }
        if let longExposure = longExposure() {
            if longExposure.getAssetCount(.image) > 0 {
                albums.append(longExposure)
            }
        }
        return albums
    }
    
    func allVideoAlbums() -> [PHAssetCollection] {
        var albums = [PHAssetCollection]()
        if let videos = videos() {
            if videos.getAssetCount(.video) > 0 {
                albums.append(videos)
            }
        }
        return albums
    }
    
    /// favorites, selfies, live(>=iOS10.3), panoramas, slomos, videos, screenshots, animated(>= iOS11), longExposure(>= iOS11)
    public func filteredSmartAlbums(isOnlyImage: Bool = false) -> [PHAssetCollection] {
        var albums = [PHAssetCollection]()

        if let favorites = favorites() {
            if favorites.getAssetCount() > 0 {
                albums.append(favorites)
            }
        }
        if let selfies = selfies() {
            if selfies.getAssetCount(.image) > 0 {
                albums.append(selfies)
            }
        }
        if let live = live(), !isOnlyImage {
            if live.getAssetCount(.image) > 0 {
                albums.append(live)
            }
        }
        if let panoramas = panoramas() {
            if panoramas.getAssetCount(.image) > 0 {
                albums.append(panoramas)
            }
        }
        if let slomos = slomos() {
            if slomos.getAssetCount(.image) > 0 {
                albums.append(slomos)
            }
        }
        if let videos = videos(), !isOnlyImage {
            if videos.getAssetCount(.video) > 0 {
                albums.append(videos)
            }
        }
        if let screenShots = screenShots() {
            if screenShots.getAssetCount(.image) > 0 {
                albums.append(screenShots)
            }
        }
        if let animated = animated() {
            if animated.getAssetCount(.image) > 0 {
                albums.append(animated)
            }
        }
        if let longExposure = longExposure() {
            if longExposure.getAssetCount(.image) > 0 {
                albums.append(longExposure)
            }
        }
        return albums
    }

    // MARK: smart albums. Contains videos and images
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

    /// Fetch albums covers
    func fetchCover(in collection: PHAssetCollection, targetSize: CGSize, options: PHFetchOptions? = nil, completion: @escaping ((UIImage?) -> Void)) {
        let keyAssetResult = PHAsset.fetchKeyAssets(in: collection, options: options)
        if let keyAsset = keyAssetResult?.firstObject {
            let imageOptions = PHImageRequestOptions()
            imageOptions.isNetworkAccessAllowed = true
            imageOptions.deliveryMode = .fastFormat
            imageOptions.resizeMode = .fast
            PhotoPickerResource.shared.fetchImage(keyAsset, options: imageOptions, targetSize: targetSize) { (image, _) in
                completion(image)
            }
        } else {
            print("doesn't have any key asset")
            completion(nil)
        }
    }
    
    func requestAVAsset(for video: PHAsset, completion: @escaping((AVAsset?) -> Void)) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: video, options: options) { (avasset, _, _) in
            DispatchQueue.main.async {
                completion(avasset)
            }
        }
    }

    func requestAVAssetURL(for video: PHAsset, completion: @escaping((URL?) -> Void)) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: video, options: options) { (avasset, _, _) in
            DispatchQueue.main.async {
                if let avURLAsset = avasset as? AVURLAsset {
                    completion(avURLAsset.url)
                } else if let avComposition = avasset as? AVComposition {
                    self.exportAVComposition(avComposition) { (result) in
                        let url = try? result.get()
                        completion(url)
                    }
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    // Export Slow Mode video url
    func exportAVComposition(_ composition: AVComposition, completion: @escaping (Result<URL, Error>) -> Void) {
        do {
            var tempDirectory = try FileManager.tempDirectory(with: "avComposition")
            let videoName = UUID().uuidString + ".mp4"
            tempDirectory.appendPathComponent("\(videoName)")
            
            guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                completion(.failure(AVAssetExportSessionError.exportSessionCreationFailed))
                return
            }
            
            exporter.outputURL = tempDirectory
            exporter.outputFileType = .mp4
            exporter.shouldOptimizeForNetworkUse = true
            exporter.exportAsynchronously {
                DispatchQueue.main.async {
                    switch exporter.status {
                    case .waiting:
                        #if DEBUG
                        print("waiting to be exported")
                        #endif
                    case .exporting:
                        #if DEBUG
                        print("exporting video")
                        #endif
                    case .cancelled, .failed:
                        completion(.failure(exporter.error!))
                    case .completed:
                        #if DEBUG
                        print("finish exporting, video size: \(tempDirectory.sizePerMB()) MB")
                        #endif
                        completion(.success(tempDirectory))
                    case .unknown:
                        completion(.failure(AVAssetExportSessionError.exportStatuUnknown))
                    @unknown default:
                        completion(.failure(AVAssetExportSessionError.exportStatuUnknown))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func trimVideo(_ asset: AVAsset, from startTime: Double, to endTime: Double, completion: @escaping((Result<URL, Error>) -> Void)) {
        do {
            var tempDirectory = try FileManager.tempDirectory(with: "trimmedVideo")
            let videoName = UUID().uuidString + ".mp4"
            tempDirectory.appendPathComponent("\(videoName)")
            
            guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
                completion(.failure(AVAssetExportSessionError.exportSessionCreationFailed))
                return
            }
            
            let start = CMTime(seconds: startTime, preferredTimescale: 600)
            let end = CMTime(seconds: endTime, preferredTimescale: 600)
            exporter.timeRange = CMTimeRange(start: start, end: end)
            exporter.outputURL = tempDirectory
            exporter.outputFileType = .mp4
            exporter.exportAsynchronously {
                DispatchQueue.main.async {
                    switch exporter.status {
                    case .waiting:
                        #if DEBUG
                        print("waiting to be exported")
                        #endif
                    case .exporting:
                        #if DEBUG
                        print("exporting video")
                        #endif
                    case .cancelled, .failed:
                        completion(.failure(exporter.error!))
                    case .completed:
                        #if DEBUG
                        print("finish exporting, video size: \(tempDirectory.sizePerMB()) MB")
                        #endif
                        completion(.success(tempDirectory))
                    case .unknown:
                        completion(.failure(AVAssetExportSessionError.exportStatuUnknown))
                    @unknown default:
                        completion(.failure(AVAssetExportSessionError.exportStatuUnknown))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
}

extension PhotoPickerResource {

    @discardableResult
    func fetchImage(_ asset: PHAsset, options: PHImageRequestOptions? = nil, targetSize: CGSize, completion: @escaping ((UIImage?, PHImageRequestID?) -> Void)) -> PHImageRequestID {
        let _options: PHImageRequestOptions!
        if let options = options {
            _options = options
        } else {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            _options = options
        }
        return PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .default, options: _options) { (image, info) in
            completion(image, info?["PHImageResultRequestIDKey"] as? PHImageRequestID)
        }
    }
    
    func fetchImage(_ asset: PHAsset) -> UIImage? {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = true
        var image: UIImage?
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .default, options: options) { (_image, info) in
            image = _image
        }
        return image
    }
}

extension PHAssetCollection {
    func getAssetCount(_ mediaType: PHAssetMediaType? = nil) -> Int {
        if estimatedAssetCount == NSNotFound { // Returns NSNotFound if a count cannot be quickly returned.
            if let type = mediaType {
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "mediaType == %d", type.rawValue)
                return PHAsset.fetchAssets(in: self, options: fetchOptions).count
            } else {
                return PHAsset.fetchAssets(in: self, options: nil).count
            }
        } else {
            return estimatedAssetCount
        }
    }
}
