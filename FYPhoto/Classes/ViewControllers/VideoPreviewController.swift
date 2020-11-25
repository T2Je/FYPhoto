//
//  VideoPreviewViewController.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/11/25.
//

import UIKit
import AVFoundation
import AVKit

public protocol VideoPreviewControllerDelegate: class {
    func videoPreviewController(_ preview: VideoPreviewController, didSaveVideoAt path: URL)
    func videoPreviewControllerDidCancel(_ preview: VideoPreviewController)
}

public class VideoPreviewController: UIViewController {

    let cancelButton = UIButton()
    let saveButton = UIButton()
    
    var playerView = PlayerView()
    
    let player: AVPlayer
    
    let videoURL: URL
    
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

        view.addSubview(playerView)
        view.addSubview(cancelButton)
        view.addSubview(saveButton)
        
        cancelButton.setTitle("Cancel".photoTablelocalized, for: .normal)
        cancelButton.layer.masksToBounds = true
        cancelButton.layer.cornerRadius = 5
        cancelButton.addTarget(self, action: #selector(cancelButtonClicked(_:)), for: .touchUpInside)
        
        saveButton.setTitle("Save".photoTablelocalized, for: .normal)
        saveButton.layer.masksToBounds = true
        saveButton.layer.cornerRadius = 5
        saveButton.addTarget(self, action: #selector(saveButtonClicked(_:)), for: .touchUpInside)
        
        makeConstraints()
        playerView.player = player
//        player.play()
        // Do any additional setup after loading the view.
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        player.play()
    }
    
    @objc func cancelButtonClicked(_ sender: UIButton) {
        try? FileManager.default.removeItem(at: videoURL)
        delegate?.videoPreviewControllerDidCancel(self)
    }
    
    @objc func saveButtonClicked(_ sender: UIButton) {
        delegate?.videoPreviewController(self, didSaveVideoAt: videoURL)
    }
    
    func makeConstraints() {
        playerView.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        let safeLayoutGuide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: safeLayoutGuide.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: safeLayoutGuide.leadingAnchor),
            playerView.bottomAnchor.constraint(equalTo: safeLayoutGuide.bottomAnchor),
            playerView.trailingAnchor.constraint(equalTo: safeLayoutGuide.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: safeLayoutGuide.leadingAnchor, constant: 10),
            cancelButton.topAnchor.constraint(equalTo: safeLayoutGuide.topAnchor, constant: 25),
            cancelButton.widthAnchor.constraint(equalToConstant: 60),
            cancelButton.heightAnchor.constraint(equalToConstant: 35)
        ])
        
        NSLayoutConstraint.activate([
            saveButton.trailingAnchor.constraint(equalTo: safeLayoutGuide.trailingAnchor, constant: -10),
            saveButton.topAnchor.constraint(equalTo: safeLayoutGuide.topAnchor, constant: 25),
            saveButton.widthAnchor.constraint(equalToConstant: 60),
            saveButton.heightAnchor.constraint(equalToConstant: 35)
        ])
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
