//
//  VideoTrimmerViewController.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/2/23.
//

import UIKit
import AVFoundation
import Photos

public protocol VideoTrimmerViewControllerDelegate: class {
    func videoTrimmerDidCancel(_ videoTrimmer: VideoTrimmerViewController)
    func videoTrimmer(_ videoTrimmer: VideoTrimmerViewController, didFinishTrimingAt url: URL)
}

public class VideoTrimmerViewController: UIViewController {
    public weak var delegate: VideoTrimmerViewControllerDelegate?
    
    // player
    fileprivate var playerView = PlayerView()
    fileprivate let player: AVPlayer
    fileprivate let playerItem: AVPlayerItem
    fileprivate let asset: AVURLAsset
    
    fileprivate var previousAudioCategory: AVAudioSession.Category?
    fileprivate var previousAudioMode: AVAudioSession.Mode?
    fileprivate var previousAudioOptions: AVAudioSession.CategoryOptions?
    
    let pauseImage = Asset.icons8Pause.image.withRenderingMode(.alwaysTemplate)
    let playImage = Asset.icons8Play.image.withRenderingMode(.alwaysTemplate)
    
    var needSeekToZeroBeforePlay = false
    
    var isPlaying = false {
        didSet {
            playerStateValueChanged()
        }
    }
    
    // rangeSlider
    let trimmerToolView: VideoTrimmerToolView
    
    // bottom buttons
    let cancelButton = UIButton()
    let confirmButton = UIButton()
    let pauseButton = UIButton()
    
    // trimmed time
    var startTime: Double = 0 {
        didSet {
            seekVideo(to: startTime)
        }
    }
    
    var endTime: Double = 15 {
        didSet {
            seekVideo(to: endTime)
        }
    }
    
    var offsetTime: Double = 0 {
        didSet {
            
        }
    }
    
    let url: URL
    let maximumDuration: Double
    
    /// Init VideoTrimmerViewController
    /// - Parameters:
    ///   - url: video url
    ///   - maximumDuration: maximum video duration
    public init(url: URL, maximumDuration: Double) {
        self.url = url
        self.maximumDuration = maximumDuration
        self.asset = AVURLAsset(url: url)
        self.playerItem = AVPlayerItem(url: url)
        self.player = AVPlayer(playerItem: self.playerItem)
        trimmerToolView = VideoTrimmerToolView(maximumDuration: maximumDuration)
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        view.addSubview(playerView)
        view.addSubview(trimmerToolView)
        view.addSubview(cancelButton)
        view.addSubview(confirmButton)
        view.addSubview(pauseButton)
        
        setupPlayerView()
        setupTrimmerToolView()
        setupButtonButtons()
        createImageFrames(20)
        
        storePreviousAudioState()
        // Do any additional setup after loading the view.
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setAudioState()
        isPlaying = true
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        activateOtherInterruptedAudioSessions()
    }
     
    func storePreviousAudioState() {
        let audioSession = AVAudioSession.sharedInstance()
        previousAudioMode = audioSession.mode
        previousAudioCategory = audioSession.category
        previousAudioOptions = audioSession.categoryOptions
    }
    
    func setAudioState() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    // MARK: - SETUP
    func setupPlayerView() {
        playerView.player = player
        playerView.layer.contentsGravity = .resizeAspectFill
        playerView.translatesAutoresizingMaskIntoConstraints = false
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 20),
            playerView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 40),
            playerView.bottomAnchor.constraint(equalTo: trimmerToolView.topAnchor, constant: -10),
            playerView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -40)
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    func setupButtonButtons() {
        cancelButton.setTitle(L10n.cancel, for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        cancelButton.addTarget(self, action: #selector(cancelButtonClicked(_:)), for: .touchUpInside)
        
        confirmButton.setTitle(L10n.confirm, for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        confirmButton.addTarget(self, action: #selector(confirmButtonClicked(_:)), for: .touchUpInside)
        
        pauseButton.setImage(pauseImage, for: .normal)
        pauseButton.tintColor = .white
        pauseButton.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        pauseButton.addTarget(self, action: #selector(pauseButtonClicked(_:)), for: .touchUpInside)
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 15),
            cancelButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: 0),
            cancelButton.widthAnchor.constraint(equalToConstant: 50),
            cancelButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        NSLayoutConstraint.activate([
            confirmButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -15),
            confirmButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: 0),
            confirmButton.widthAnchor.constraint(equalToConstant: 60),
            confirmButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        NSLayoutConstraint.activate([
            pauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pauseButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: 0),
            pauseButton.widthAnchor.constraint(equalToConstant: 60),
            pauseButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func setupTrimmerToolView() {
        trimmerToolView.lowValue = { [weak self] low in
            guard let self = self else { return }
            self.isPlaying = false
            self.startTime = low + self.offsetTime
        }
        
        trimmerToolView.highValue = { [weak self] high in
            guard let self = self else { return }
            self.isPlaying = false
            self.endTime = high + self.offsetTime
        }
        
        trimmerToolView.scrollVideoFrames = { [weak self] (xOffset, contentSize) in
            guard let self = self else { return }
            self.isPlaying = false
            guard xOffset > 0 else { return }
            
            let durationSec = Double(CMTimeGetSeconds(self.asset.duration))
            let a = durationSec / Double(contentSize.width)
            self.offsetTime = xOffset * a
            self.seekVideo(to: self.startTime + self.offsetTime)
        }
        
        trimmerToolView.stopOperating = { [weak self] in
            guard let self = self else { return }
            self.seekVideo(to: self.startTime + self.offsetTime)
            self.isPlaying = true
        }
        
        trimmerToolView.translatesAutoresizingMaskIntoConstraints = false
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            trimmerToolView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 25),
            trimmerToolView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -25),
            trimmerToolView.bottomAnchor.constraint(equalTo: self.pauseButton.topAnchor, constant: -10),
            trimmerToolView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func createImageFrames(_ num: Int) {
        //creating assets
        let assetImgGenerate : AVAssetImageGenerator    = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter    = CMTime.zero;
        assetImgGenerate.requestedTimeToleranceBefore   = CMTime.zero;
        
        
        assetImgGenerate.appliesPreferredTrackTransform = true
        let videoDuration: CMTime = asset.duration
        let durationSeconds = Int(CMTimeGetSeconds(videoDuration))
        let maxLength = "\(durationSeconds)" as NSString

        let numberOfFrames = num
        let secPerFrame = durationSeconds/numberOfFrames
        var startTime = 1
        
        var frames: [UIImage] = []
        
        //loop for numberOfFrames number of frames
        for _ in 0...numberOfFrames
        {
            do {
                let time: CMTime = CMTimeMakeWithSeconds(Float64(startTime), preferredTimescale: Int32(maxLength.length))
                let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                let image = UIImage(cgImage: img)
                frames.append(image)
            } catch {
                print("Image generation failed with error: \(error)")
            }
                        
            startTime = startTime + secPerFrame
        }
        
        trimmerToolView.videoFrames = frames
    }
    
    // MARK: PLAY VIDEO
    
    func seekVideo(to time: Double) {
        print("seek to time: \(time)")
        let cmtime = CMTime(seconds: time, preferredTimescale: player.currentTime().timescale)
        player.seek(to: cmtime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    fileprivate func playerStateValueChanged() {
        if isPlaying {
            if needSeekToZeroBeforePlay {
                player.seek(to: .zero)
            }
            player.play()
            pauseButton.setImage(pauseImage, for: .normal)
        } else {
            player.pause()
            pauseButton.setImage(playImage, for: .normal)
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
    
    // MARK: BUTTON FUNCTIONS
    @objc func cancelButtonClicked(_ sender: UIButton) {
        delegate?.videoTrimmerDidCancel(self)
    }
    
    @objc func confirmButtonClicked(_ sender: UIButton) {
        PhotoPickerResource.shared.trimVideo(asset, from: startTime, to: endTime) { [weak self] (result) in
            guard let self = self else { return }
            self.delegate?.videoTrimmerDidCancel(self)
            switch result {
            case .success(let url):
                self.delegate?.videoTrimmer(self, didFinishTrimingAt: url)
            case .failure(let error):
                print("export trimmed video error: \(error)")
            }
        }        
    }
    
    @objc func pauseButtonClicked(_ sender: UIButton) {
        isPlaying = !isPlaying
    }
    
    @objc func playerItemDidReachEnd(_ notification: Notification) {
        isPlaying = false
        needSeekToZeroBeforePlay = true
    }
}
