//
//  VideoPreviewViewController.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/11/25.
//

import UIKit
import AVFoundation
import AVKit

public protocol VideoPreviewControllerDelegate: AnyObject {
    func videoPreviewController(_ preview: VideoPreviewController, didSaveVideoAt path: URL)
    func videoPreviewControllerDidCancel(_ preview: VideoPreviewController)
}

/// Preview video just token, save or discard it.
public class VideoPreviewController: UIViewController {

    let cancelButton = UIButton()
    let saveButton = UIButton()

    var playerView = PlayerView()

    let player: AVPlayer

    let videoURL: URL

    fileprivate var previousAudioCategory: AVAudioSession.Category?
    fileprivate var previousAudioMode: AVAudioSession.Mode?
    fileprivate var previousAudioOptions: AVAudioSession.CategoryOptions?

    public weak var delegate: VideoPreviewControllerDelegate?

    let playerItem: AVPlayerItem

    public init(videoURL: URL) {
        self.videoURL = videoURL
        playerItem = AVPlayerItem(url: videoURL)

        player = AVPlayer(playerItem: playerItem)
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(playerView)
        view.addSubview(cancelButton)
        view.addSubview(saveButton)

        playerView.backgroundColor = .black
        playerView.layer.contentsGravity = .resizeAspectFill

        cancelButton.setTitle(L10n.cancel, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        cancelButton.layer.masksToBounds = true
        cancelButton.layer.cornerRadius = 5
        cancelButton.addTarget(self, action: #selector(cancelButtonClicked(_:)), for: .touchUpInside)

        saveButton.setTitle(L10n.save, for: .normal)
        saveButton.backgroundColor = UIColor(red: 44/255.0, green: 118/255.0, blue: 227/255.0, alpha: 1)
        saveButton.setTitleColor(UIColor.white, for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        saveButton.layer.masksToBounds = true
        saveButton.layer.cornerRadius = 5
        saveButton.addTarget(self, action: #selector(saveButtonClicked(_:)), for: .touchUpInside)

        makeConstraints()
        storePreviousAudioState()
        setAudioState()

        playerView.player = player
//        player.play()
        // Do any additional setup after loading the view.
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        player.play()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
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

    @objc func cancelButtonClicked(_ sender: UIButton) {
        try? FileManager.default.removeItem(at: videoURL)
        delegate?.videoPreviewControllerDidCancel(self)
    }

    @objc func saveButtonClicked(_ sender: UIButton) {
        delegate?.videoPreviewController(self, didSaveVideoAt: videoURL)
    }

    func makeConstraints() {
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        playerView.translatesAutoresizingMaskIntoConstraints = false

        let safeLayoutGuide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: safeLayoutGuide.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: safeLayoutGuide.leadingAnchor),
            playerView.bottomAnchor.constraint(equalTo: safeLayoutGuide.bottomAnchor),
            playerView.trailingAnchor.constraint(equalTo: safeLayoutGuide.trailingAnchor)
        ])

        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            cancelButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 44),
            cancelButton.widthAnchor.constraint(equalToConstant: 64),
            cancelButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        NSLayoutConstraint.activate([
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            saveButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 44),
            saveButton.widthAnchor.constraint(equalToConstant: 64),
            saveButton.heightAnchor.constraint(equalToConstant: 32)
        ])

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
}
