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

    let rangeSlider = RangeSlider()

    let frameScrollView = UIScrollView()

    let sliderLeading: CGFloat = 40

    /// low value >= 0
    var lowValue: ((Double) -> Void)?
    /// high value <= maximum duration
    var highValue: ((Double) -> Void)?

    /// stopOperating this view
    var stopOperating: (() -> Void)?

    var scrollVideoFrames: ((_ offsetTime: Double) -> Void)?

    var videoFrames: [UIImage] = [] {
        didSet {
            if videoFrames.isEmpty {
                isEnable = false
            } else {
                isEnable = true
                setupVideoFrames(videoFrames)
            }
        }
    }

    let maximumDuration: Double
    let assetDuration: Double
    let numberOfFramesInSlider: Int

    var isEnable: Bool = false {
        didSet {
            rangeSlider.isEnabled = isEnable
        }
    }
    /// Init VideoTimmerToolView.
    ///
    /// Trim the video duration less than maximumDuration.
    ///
    /// - Parameters:
    ///   - maximumDuration: maximum video duration
    ///   - assetDuration: asset duration
    ///   - numberOfFramesInSlider: number of frames in slider range
    ///   - frame: view frame
    init(maximumDuration: Double = 0, assetDuration: Double, numberOfFramesInSlider: Int, frame: CGRect = .zero) {
        self.maximumDuration = maximumDuration
        self.assetDuration = assetDuration
        self.numberOfFramesInSlider = numberOfFramesInSlider
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        addSubview(startTimeLabel)
        addSubview(endTimeLabel)
        addSubview(frameScrollView)
        addSubview(rangeSlider)

        setupLabels()
        setupRangeSlider()
        setupFrameScrollView()
    }

    func setupLabels() {
        startTimeLabel.text = 0.videoDurationFormat()
        let endSecStr = maximumDuration.videoDurationFormat()
        endTimeLabel.text = endSecStr

        startTimeLabel.textColor = .white
        startTimeLabel.font = UIFont.systemFont(ofSize: 12)

        endTimeLabel.textColor = .white
        endTimeLabel.font = UIFont.systemFont(ofSize: 12)

        startTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        endTimeLabel.translatesAutoresizingMaskIntoConstraints = false

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
    }

    func setupFrameScrollView() {
        frameScrollView.showsHorizontalScrollIndicator = false
        frameScrollView.showsVerticalScrollIndicator = false
        frameScrollView.isDirectionalLockEnabled = true
        frameScrollView.delegate = self
        frameScrollView.contentInsetAdjustmentBehavior = .never
        frameScrollView.contentInset = UIEdgeInsets(top: 0, left: sliderLeading, bottom: 0, right: sliderLeading)

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
        // scrollView's contentSize is decided by asset duration, maximum duration and frames count
        let framesCount = videoFrames.count
        let multiplier = CGFloat(1.0/Double(numberOfFramesInSlider))
//        print("multiplier: \(multiplier)")
        for index in 0..<framesCount {
            let videoFrame = videoFrames[index]
            let imageView = UIImageView(image: videoFrame)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            frameScrollView.addSubview(imageView)

            NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: self.rangeSlider, attribute: .width, multiplier: multiplier, constant: 0).isActive = true
            if let last = lastFrameView {
                if index == framesCount - 1 {
                    NSLayoutConstraint.activate([
                        imageView.leadingAnchor.constraint(equalTo: last.trailingAnchor),
                        imageView.centerYAnchor.constraint(equalTo: frameScrollView.centerYAnchor),
//                        imageView.widthAnchor.constraint(equalToConstant: 40),
                        imageView.heightAnchor.constraint(equalTo: frameScrollView.heightAnchor),
                        imageView.trailingAnchor.constraint(equalTo: frameScrollView.trailingAnchor)
                    ])
                } else {
                    NSLayoutConstraint.activate([
                        imageView.leadingAnchor.constraint(equalTo: last.trailingAnchor),
                        imageView.centerYAnchor.constraint(equalTo: frameScrollView.centerYAnchor),
//                        imageView.widthAnchor.constraint(equalToConstant: 40),
                        imageView.heightAnchor.constraint(equalTo: frameScrollView.heightAnchor)
                    ])
                }
            } else {
                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: frameScrollView.leadingAnchor),
                    imageView.centerYAnchor.constraint(equalTo: frameScrollView.centerYAnchor),
//                    imageView.widthAnchor.constraint(equalToConstant: 40),
                    imageView.heightAnchor.constraint(equalTo: frameScrollView.heightAnchor)
                ])
            }
            lastFrameView = imageView
        }
        layoutIfNeeded()
    }

    func setupRangeSlider() {
        rangeSlider.isEnabled = isEnable
        rangeSlider.addTarget(self, action: #selector(rangeSliderValueChanged(_:)), for: .valueChanged)
        rangeSlider.addTarget(self, action: #selector(rangeSliderTouchDragExit(_:)), for: .touchDragExit)

        rangeSlider.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            rangeSlider.topAnchor.constraint(equalTo: self.topAnchor, constant: 15),
            rangeSlider.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: sliderLeading),
            rangeSlider.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            rangeSlider.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -sliderLeading)
        ])
    }

    @objc func rangeSliderValueChanged(_ rangeSlider: RangeSlider) {
        let a = maximumDuration / (rangeSlider.maximumValue - rangeSlider.minimumValue)
        if rangeSlider.isLeftHandleSelected {
            let startTime = a * rangeSlider.leftHandleValue
            lowValue?(startTime)
        } else {
            let endTime = a * rangeSlider.rightHandleValue
            highValue?(endTime)
        }
    }

    @objc func rangeSliderTouchDragExit(_ rangeSlider: RangeSlider) {
        stopOperating?()
    }

    func runningAIndicator(at time: Double) {
        let a = maximumDuration / (rangeSlider.maximumValue - rangeSlider.minimumValue)
        let value = time / a
        rangeSlider.run(at: value)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == rangeSlider {
            // frame scrollView handles hit if rangeSlider left or right handle doesn't contain the touch point.
            let fixPoint = CGPoint(x: point.x - rangeSlider.frame.origin.x, y: point.y)
            if rangeSlider.isTouchingHandles(at: fixPoint) {
                return rangeSlider
            } else {
                return frameScrollView
            }
        } else {
            return view
        }
    }

}

extension VideoTrimmerToolView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x + scrollView.contentInset.left
        if offsetX < 0 {
            return
        } else if offsetX == 0 {
            scrollVideoFrames?(0)
        } else {
            let offsetTime = assetDuration / Double(scrollView.contentSize.width) * Double(offsetX)
//            print("offsetTime: \(offsetTime)")
            scrollVideoFrames?(offsetTime)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        stopOperating?()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            stopOperating?()
        }
    }
}
