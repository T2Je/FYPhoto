//
//  VideoTrimmerViewController.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/2/23.
//

import UIKit
import AVFoundation

public protocol VideoTrimmerViewControllerDelegate: class {
    func videoTrimmerDidCancel(_ videoTrimmer: VideoTrimmerViewController)
    func videoTrimmer(_ videoTrimmer: VideoTrimmerViewController, didFinishTrimingAt url: URL)
}

public class VideoTrimmerViewController: UIViewController {
    public weak var delegate: VideoTrimmerViewControllerDelegate?
    
    // rangeSlider
    let trimmerToolView = VideoTrimmerToolView()
    
    // bottom buttons
    let cancelButton = UIButton()
    let confirmButton = UIButton()
    let pauseButton = UIButton()
    
    let asset: AVAsset
    
    public init(asset: AVAsset) {
        self.asset = asset
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(trimmerToolView)
        view.addSubview(cancelButton)
        view.addSubview(confirmButton)
        view.addSubview(pauseButton)
        
        setupTrimmerToolView()
        setupButtonButtons()
        // Do any additional setup after loading the view.
    }
    
    
    func setupButtonButtons() {
        cancelButton.setTitle(L10n.cancel, for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonClicked(_:)), for: .touchUpInside)
        
        confirmButton.setTitle(L10n.confirm, for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.addTarget(self, action: #selector(confirmButtonClicked(_:)), for: .touchUpInside)
        
        pauseButton.setImage(Asset.icons8Pause.image, for: .normal)
        pauseButton.tintColor = .white
        pauseButton.addTarget(self, action: #selector(pauseButtonClicked(_:)), for: .touchUpInside)
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        
        let safeArea = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 15),
            cancelButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: 0),
            cancelButton.widthAnchor.constraint(equalToConstant: 50),
            cancelButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        NSLayoutConstraint.activate([
            confirmButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -15),
            confirmButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: 0),
            confirmButton.widthAnchor.constraint(equalToConstant: 50),
            confirmButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        NSLayoutConstraint.activate([
            pauseButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            pauseButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: 0),
            pauseButton.widthAnchor.constraint(equalToConstant: 50),
            pauseButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func setupTrimmerToolView() {
        trimmerToolView.lowValue = { [weak self] low in
            print(low)
        }
        
        trimmerToolView.highValue = { [weak self] high in
            print(high)
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
    // MARK: BUTTON FUNCTIONS
    @objc func cancelButtonClicked(_ sender: UIButton) {
        delegate?.videoTrimmerDidCancel(self)
    }
    
    @objc func confirmButtonClicked(_ sender: UIButton) {
        // TODO: 😴zZ finish trimming
        delegate?.videoTrimmerDidCancel(self)
    }
    
    @objc func pauseButtonClicked(_ sender: UIButton) {
        
    }
    
}
