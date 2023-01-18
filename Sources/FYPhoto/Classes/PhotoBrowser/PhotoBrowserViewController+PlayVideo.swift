//
//  PhotoBrowserViewController+PlayVideo.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/6/23.
//

import Foundation
import Photos
import UIKit

extension PhotoBrowserViewController {
    func setupPlayer(photo: PhotoProtocol, for cell: VideoDetailCell) {
        if let asset = photo.asset {
            setupPlayer(asset: asset, for: cell.playerView)
        } else if let url = photo.url {
            cell.startLoading()
            setupPlayer(url: url, for: cell.playerView, completion: { _ in                
                cell.endLoading()
            })
        }
    }

    fileprivate func setupPlayer(asset: PHAsset, for playerView: PlayerView) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress, _, _, _ in
            print("request video from icloud progress: \(progress)")
        }
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { (item, _) in
            if let item = item {
                self.configurePlayer(with: item)
                playerView.player = self.player
            }
        }
    }

    fileprivate func setupPlayer(url: URL, for playerView: PlayerView, completion: ((URL?) -> Void)?) {
        if let cache = videoCache {
            cache.fetchFilePathWith(key: url) { (result) in
                switch result {
                case .success(let filePath):
                    self.setupPlayerView(filePath, playerView: playerView)
                    completion?(filePath)
                case .failure(let error):
                    switch error {
                    case .underlyingError(_):
                        self.showError(error)
                    default: break
                    }
                    print("FYPhoto fetch url error: \(error)")
                    completion?(nil)
                }
            }
        } else {
            setupPlayerView(url, playerView: playerView)
            completion?(url)
        }
    }

    fileprivate func setupPlayerView(_ url: URL, playerView: PlayerView) {
        // Create a new AVPlayerItem with the asset and an
        // array of asset keys to be automatically loaded
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: self.assetKeys)
        configurePlayer(with: playerItem)
        playerView.player = self.player
    }

    fileprivate func configurePlayer(with playerItem: AVPlayerItem) {
        if let currentItem = mPlayerItem {
            playerItemStatusToken?.invalidate()
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: currentItem)
        }
        // Associate the player item with the player
                
        if let player = self.player {
            player.pause()
            player.replaceCurrentItem(with: playerItem)
        } else {
            player = AVPlayer(playerItem: playerItem)
        }
        
        self.mPlayerItem = playerItem
        // observing the player item's status property
        playerItemStatusToken = playerItem.observe(\.status, options: .new) { (_, change) in
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
    }

    func playVideo() {
        guard let player = player else { return }
        if seekToZeroBeforePlay {
            seekToZeroBeforePlay = false
            player.seek(to: .zero)
        }

        player.play()
        isPlaying = true
    }

    func pauseVideo() {
        player?.pause()
        isPlaying = false
    }

    func stopPlayingIfNeeded(at indexPath: IndexPath) {
        guard player != nil,
                photos[indexPath.item].isVideo,
              isPlaying else {
            return
        }
        stopPlayingAnyway()
    }

    func stopPlayingAnyway() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
    }

    // MARK: Target action
    @objc func playerItemDidReachEnd(_ notification: Notification) {
        isPlaying = false
        seekToZeroBeforePlay = true
    }
}
