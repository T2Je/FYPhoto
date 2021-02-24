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
    
    /// low value >= 0
    var lowValue: ((Double) -> Void)?
    /// high value <= 100
    var highValue: ((Double) -> Void)?
    
    var videoFrames: [UIImage] = [] {
        didSet {
            setupVideoFrames(videoFrames)
        }
    }
    
    let maximumDuration: Double
    
    /// Init VideoTimmerToolView.
    ///
    /// Trim the video duration less than maximumDuration.
    ///
    /// - Parameters:
    ///   - maximumDuration: maximum video duration
    ///   - frame: view frame
    init(maximumDuration: Double = 0, frame: CGRect = .zero) {
        self.maximumDuration = maximumDuration
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
        // TODO: 😴zZ test text
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
            frameScrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            frameScrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            frameScrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0)
        ])
    }
    
    func setupVideoFrames(_ videoFrames: [UIImage]) {
        var lastFrameView: UIImageView?
        for index in 0..<videoFrames.count {
            let videoFrame = videoFrames[index]
            let imageView = UIImageView(image: videoFrame)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            frameScrollView.addSubview(imageView)
            
            if let last = lastFrameView {
                if index == videoFrames.count - 1 {
                    NSLayoutConstraint.activate([
                        imageView.leadingAnchor.constraint(equalTo: last.trailingAnchor),
                        imageView.centerYAnchor.constraint(equalTo: frameScrollView.centerYAnchor),
                        imageView.widthAnchor.constraint(equalToConstant: 50),
                        imageView.heightAnchor.constraint(equalTo: frameScrollView.heightAnchor),
                        imageView.trailingAnchor.constraint(equalTo: frameScrollView.trailingAnchor)
                    ])
                } else {
                    NSLayoutConstraint.activate([
                        imageView.leadingAnchor.constraint(equalTo: last.trailingAnchor),
                        imageView.centerYAnchor.constraint(equalTo: frameScrollView.centerYAnchor),
                        imageView.widthAnchor.constraint(equalToConstant: 50),
                        imageView.heightAnchor.constraint(equalTo: frameScrollView.heightAnchor)
                    ])
                }
            } else {
                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: frameScrollView.leadingAnchor),
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
            rangeSlider.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
            rangeSlider.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            rangeSlider.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15)
        ])
    }
    
    @objc func rangeSliderValueChanged(_ rangeSlider: RangeSlider) {
        if rangeSlider.isLeftHandleSelected {
            lowValue?(rangeSlider.leftHandleValue)
        } else {
            highValue?(rangeSlider.rightHandleValue)
        }
    }
        
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == rangeSlider {
            // frame scrollView handles hit if rangeSlider left or right handle doesn't contain the touch point.
            if rangeSlider.isTouchingHandles(at: point) {
                return rangeSlider
            } else {
                return frameScrollView
            }
        } else {
            return view
        }
    }
}

extension VideoTrimmerToolView {
    
}
