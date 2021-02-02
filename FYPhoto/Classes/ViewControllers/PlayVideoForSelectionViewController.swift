//
//  PlayVideoForSelectionViewController.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/23.
//

import UIKit
import Photos
import AVFoundation

/// Play video
class PlayVideoForSelectionViewController: UIViewController {
    var selectedVideo: ((URL) -> Void)?
    
    fileprivate let cancelButton = UIButton()
    fileprivate let selectButton = UIButton()
    
    fileprivate var playerView = PlayerView()
    fileprivate var player: AVPlayer?
    fileprivate var playerItem: AVPlayerItem?
    
    fileprivate var previousAudioCategory: AVAudioSession.Category?
    fileprivate var previousAudioMode: AVAudioSession.Mode?
    fileprivate var previousAudioOptions: AVAudioSession.CategoryOptions?
    
    var isCreatedByURL = false
    
    var asset: PHAsset!
    var url: URL!
    
    private init() {
        super.init(nibName: nil, bundle: nil)
    }
        
    static func playVideo(_ url: URL) -> PlayVideoForSelectionViewController {
        let playerVC = PlayVideoForSelectionViewController()
        playerVC.isCreatedByURL = true
        playerVC.url = url
        let playerItem = AVPlayerItem(url: url)
        playerVC.player = AVPlayer(playerItem: playerItem)
        playerVC.playerItem = playerItem
        return playerVC
    }
        
    static func playVideo(_ asset: PHAsset) -> PlayVideoForSelectionViewController {
        let playerVC = PlayVideoForSelectionViewController()
        playerVC.asset = asset
        playerVC.isCreatedByURL = false
        return playerVC
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(playerView)
        view.addSubview(cancelButton)
        view.addSubview(selectButton)

        playerView.backgroundColor = .black
        
        cancelButton.setTitle(L10n.cancel, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        cancelButton.layer.masksToBounds = true
        cancelButton.layer.cornerRadius = 5
        cancelButton.addTarget(self, action: #selector(cancelButtonClicked(_:)), for: .touchUpInside)
                
        selectButton.setTitle(L10n.select, for: .normal)
        selectButton.backgroundColor = UIColor(red: 44/255.0, green: 118/255.0, blue: 227/255.0, alpha: 1)
        selectButton.setTitleColor(UIColor.white, for: .normal)
        selectButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        selectButton.layer.masksToBounds = true
        selectButton.layer.cornerRadius = 5
        selectButton.addTarget(self, action: #selector(selectButtonClicked(_:)), for: .touchUpInside)
        
        makeConstraints()
        
        playVideo()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
    
    func makeConstraints() {
        // playerView 使用约束会导致视频没法全屏展示
//        playerView.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        
//        let safeLayoutGuide = view.safeAreaLayoutGuide
//        NSLayoutConstraint.activate([
//            playerView.topAnchor.constraint(equalTo: view.topAnchor),
//            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
//        ])
        
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            cancelButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 25),
            cancelButton.widthAnchor.constraint(equalToConstant: 64),
            cancelButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        NSLayoutConstraint.activate([
            selectButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            selectButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 25),
            selectButton.widthAnchor.constraint(equalToConstant: 64),
            selectButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        
    }
    
    fileprivate func playVideo() {
        if isCreatedByURL {
            playURLVideo(url)
        } else {
            playAssetVideo(asset)
        }
    }
    
    fileprivate func playURLVideo(_ url: URL) {
        playerView.frame = UIScreen.main.bounds
        playerView.player = player
        player?.play()        
    }
    
    fileprivate func playAssetVideo(_ asset: PHAsset) {
        let option = PHVideoRequestOptions()
        option.isNetworkAccessAllowed = true
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: option) { (playerItem, _) in
            self.playerItem = playerItem
            let player = AVPlayer(playerItem: playerItem)
            self.playerView.frame = UIScreen.main.bounds
            self.playerView.player = player
            player.play()
            self.player = player
        }
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
    
    @objc func cancelButtonClicked(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func selectButtonClicked(_ sender: UIButton) {
        if isCreatedByURL {
            self.dismiss(animated: true, completion: nil)
            selectedVideo?(url)
        } else {
            let option = PHVideoRequestOptions()
            option.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(forVideo: asset, options: option) { (avAsset, _, _) in
                DispatchQueue.main.async {
                    guard let urlAsset = avAsset as? AVURLAsset else {
                        self.dismiss(animated: true, completion: nil)
                        return
                    }
                    self.dismiss(animated: true, completion: nil)
                    self.selectedVideo?(urlAsset.url)                    
                }
            }
        }
        
    }
}
