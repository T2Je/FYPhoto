//
//  VideoTrimmerToolView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/2/23.
//

import UIKit

class VideoTrimmerToolView: UIView {
    let startTimeLabel = UILabel()
    let endTimeLabel = UILabel()
    let durationLabel = UILabel()
    
    let rangeSlider = RangeSlider()
    
    let frameScrollView = UIScrollView()
    
    var lowValue: ((Double) -> Void)?
    var highValue: ((Double) -> Void)?
    
    var videoFrames: [UIImage] = [] {
        didSet {
            setupVideoFrames(videoFrames)
        }
    }
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        addSubview(startTimeLabel)
        addSubview(endTimeLabel)
        addSubview(durationLabel)
        addSubview(frameScrollView)
        addSubview(rangeSlider)
        
        setupLabels()
        setupRangeSlider()
        setupFrameScrollView()
    }
    
    func setupLabels() {
        startTimeLabel.text = "00:00"
        endTimeLabel.text = "00:30"
        durationLabel.text = "00:30"
        
        startTimeLabel.textColor = .white
        startTimeLabel.font = UIFont.systemFont(ofSize: 12)
        
        endTimeLabel.textColor = .white
        endTimeLabel.font = UIFont.systemFont(ofSize: 12)
                
        durationLabel.textColor = .white
        durationLabel.font = UIFont.systemFont(ofSize: 12)
        
        startTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        endTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
                  
        NSLayoutConstraint.activate([
            startTimeLabel.topAnchor.constraint(equalTo: topAnchor),
            startTimeLabel.heightAnchor.constraint(equalToConstant: 15),
            startTimeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30)
        ])
                
        NSLayoutConstraint.activate([
            endTimeLabel.topAnchor.constraint(equalTo: self.topAnchor),
            endTimeLabel.heightAnchor.constraint(equalToConstant: 15),
            endTimeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30)
        ])
        
        NSLayoutConstraint.activate([
            durationLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            durationLabel.topAnchor.constraint(equalTo: self.frameScrollView.bottomAnchor),
            durationLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    func setupFrameScrollView() {
        frameScrollView.showsHorizontalScrollIndicator = false
        frameScrollView.showsVerticalScrollIndicator = false
        frameScrollView.isDirectionalLockEnabled = true
        
        frameScrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            frameScrollView.topAnchor.constraint(equalTo: self.topAnchor, constant: 15),
            frameScrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            frameScrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            frameScrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    func setupVideoFrames(_ videoFrames: [UIImage]) {
        var lastFrameView: UIImageView?
        for index in 0..<videoFrames.count {
            let videoFrame = videoFrames[index]
            let imageView = UIImageView(image: videoFrame)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            if let last = lastFrameView {
                if index == videoFrames.count - 1 {
                    NSLayoutConstraint.activate([
                        imageView.leadingAnchor.constraint(equalTo: last.trailingAnchor),
                        imageView.centerYAnchor.constraint(equalTo: frameScrollView.centerYAnchor),
                        imageView.widthAnchor.constraint(equalToConstant: 40),
                        imageView.heightAnchor.constraint(equalTo: frameScrollView.heightAnchor),
                        imageView.trailingAnchor.constraint(equalTo: frameScrollView.trailingAnchor)
                    ])
                } else {
                    NSLayoutConstraint.activate([
                        imageView.leadingAnchor.constraint(equalTo: last.trailingAnchor),
                        imageView.centerYAnchor.constraint(equalTo: frameScrollView.centerYAnchor),
                        imageView.widthAnchor.constraint(equalToConstant: 40),
                        imageView.heightAnchor.constraint(equalTo: frameScrollView.heightAnchor)
                    ])
                }
            } else {
                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: frameScrollView.trailingAnchor),
                    imageView.centerYAnchor.constraint(equalTo: frameScrollView.centerYAnchor),
                    imageView.widthAnchor.constraint(equalToConstant: 40),
                    imageView.heightAnchor.constraint(equalTo: frameScrollView.heightAnchor)
                ])
            }
            lastFrameView = imageView
        }
    }
    
    func setupRangeSlider() {
        rangeSlider.addTarget(self, action: #selector(rangeSliderValueChanged(_:)), for: .valueChanged)
        rangeSlider.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            rangeSlider.topAnchor.constraint(equalTo: self.topAnchor, constant: 15),
            rangeSlider.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            rangeSlider.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            rangeSlider.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    @objc func rangeSliderValueChanged(_ rangeSlider: RangeSlider) {
        
    }
}

extension VideoTrimmerToolView {
    
}
