//
//  CircularProgressView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/9/24.
//

import UIKit

protocol CircularProgressValueFormatter: AnyObject {
    func string(for value: Any) -> String
}

class CircularProgressView: UIView {

    // First create two layer properties
    private var circleLayer = CAShapeLayer()
    private var progressLayer = CAShapeLayer()

    var progressLabel = UILabel()

    var valueFormatter: CircularProgressValueFormatter?

    var outerCircleColor: UIColor = .systemGray {
        didSet {
            circleLayer.strokeColor = outerCircleColor.cgColor
        }
    }
    var innerCircleColor: UIColor = .systemBlue {
        didSet {
            progressLayer.strokeColor = innerCircleColor.cgColor
        }
    }

    var minValue: CGFloat = 0.0
    var maxValue: CGFloat = 100.0

    private var _value: CGFloat = 0.0
    var value: CGFloat = 0.0 {
        didSet {
            if value < minValue {
                _value = minValue
            } else if value > maxValue {
                _value = maxValue
            } else {
                _value = value
            }
        }
    }

    var currentValue: CGFloat = 0.0 {
        didSet {
            if let valueFormatter = valueFormatter {
                progressLabel.text = valueFormatter.string(for: currentValue)
            } else {
                progressLabel.text = "\(Int(currentValue))"
            }
        }
    }

    private var timer: Timer?

    var progressCompletion: (() -> Void)?

    init() {
        super.init(frame: .zero)
        createCircularPath()
        addProgressLabel()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        createCircularPath()
        addProgressLabel()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createCircularPath()
        addProgressLabel()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if frame.size != .zero {
            updatePaths()
            progressLabel.frame = bounds
            bringSubviewToFront(progressLabel)
        }
    }

    func createCircularPath() {
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineCap = .round
        circleLayer.lineWidth = 10.0
        circleLayer.strokeColor = outerCircleColor.cgColor

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.lineWidth = 10.0
        progressLayer.strokeEnd = 0
        progressLayer.strokeColor = innerCircleColor.cgColor
        layer.addSublayer(circleLayer)
        layer.addSublayer(progressLayer)
    }

    func updatePaths() {
        let radius = min(frame.size.width, frame.size.height) / 2
        let circularPath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2, y: frame.size.height / 2),
                                        radius: radius, startAngle: -.pi / 2,
                                        endAngle: 3 * .pi / 2,
                                        clockwise: true)
        circleLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
        circleLayer.frame = bounds
        progressLayer.frame = bounds
    }

    func addProgressLabel() {
        addSubview(progressLabel)
        progressLabel.textAlignment = .center
        progressLabel.font = .systemFont(ofSize: 21)
    }

    // MARK: Animation
    fileprivate func createAnimation(_ duration: TimeInterval, _ from: CGFloat) {
        let circularProgressAnimation = CABasicAnimation(keyPath: "strokeEnd")
        circularProgressAnimation.duration = duration
        circularProgressAnimation.fromValue = from
        circularProgressAnimation.toValue = 1.0
        circularProgressAnimation.fillMode = .forwards
        circularProgressAnimation.isRemovedOnCompletion = false
        progressLayer.add(circularProgressAnimation, forKey: "progressAnim")
    }

    func startAnimation() {
        currentValue = _value
        if let timer = timer {
            timer.invalidate()
        } else {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _timer in
                self?.timerAction(_timer)
            })
        }

        createAnimation(maxValue, value / (maxValue - minValue))

        timer?.fire()
    }

    func stopAnimation() {
        progressLayer.removeAnimation(forKey: "progressAnim")
        timer?.invalidate()
        timer = nil
        progressLabel.text = nil
    }

    func timerAction(_ timer: Timer) {
        currentValue += 1
//        print("current value\(self.currentValue)")
        if currentValue == maxValue {
            progressCompletion?()
            stopAnimation()
        }
    }

}
