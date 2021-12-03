//
//  RangeSlider.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/2/20.
//

import UIKit

class RangeSlider: UIControl {

    var isLeftHandleSelected: Bool = false
    var isRightHandleSelected: Bool = false

    var minimumValue: Double = 0.0 {
        willSet(newValue) {
            assert(newValue < maximumValue, "RangeSlider: minimumValue should be lower than maximumValue")
        }
    }

    var maximumValue: Double = 100.0 {
        willSet(newValue) {
            assert(newValue > minimumValue, "RangeSlider: minimumValue should be lower than maximumValue")
        }
    }

    var leftHandleValue: Double = 0.0 {
        didSet {
            updateLayerFrames()
        }
    }

    var rightHandleValue: Double = 100.0 {
        didSet {
            updateLayerFrames()
        }
    }

    var runningLayerValue: Double = 0 {
        didSet {
//            updateLayerFrames()
        }
    }

    var previousLocation: CGPoint = .zero

    lazy var handleHeight: CGFloat = {
        frame.size.height - 10
    }()

    let topBottomPadding: CGFloat = 10

    let handleWidth: CGFloat = 13
    let runningWidth: CGFloat = 7

    lazy var gapBetweenHandles: Double = 0.6 * Double(handleWidth) * (maximumValue - minimumValue) / Double(bounds.width)

    let leftHandleLayer = CAShapeLayer()
    let rightHandleLayer = CAShapeLayer()
    let runningLayer = CAShapeLayer()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        initSublayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerFrames()
    }

    func initSublayers() {
        leftHandleLayer.contentsScale = UIScreen.main.scale
        rightHandleLayer.contentsScale = UIScreen.main.scale
        runningLayer.contentsScale = UIScreen.main.scale

        leftHandleLayer.fillColor = UIColor.white.cgColor
        rightHandleLayer.fillColor = UIColor.white.cgColor

        runningLayer.fillColor = UIColor(white: 1, alpha: 0.7).cgColor
        layer.addSublayer(leftHandleLayer)
        layer.addSublayer(rightHandleLayer)
        layer.addSublayer(runningLayer)
    }

    func updateLayerFrames() {
        let leftCenter = positionForValue(leftHandleValue, layerWidth: handleWidth)
        let rightCenter = positionForValue(rightHandleValue, layerWidth: handleWidth)
        let runningCenter = positionForValue(runningLayerValue, layerWidth: runningWidth)

        let handleY = topBottomPadding / 2
        let runningY = handleY + 2.5
        let leftFrame = CGRect(x: leftCenter - handleWidth/2.0, y: handleY, width: handleWidth, height: handleHeight)
        let rightFrame = CGRect(x: rightCenter - handleWidth/2.0, y: handleY, width: handleWidth, height: handleHeight)
        let runningFrame = CGRect(x: runningCenter - runningWidth/2.0, y: runningY, width: runningWidth, height: handleHeight-5)

        leftHandleLayer.isHidden = false
        leftHandleLayer.isHidden = false
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        drawLayer(leftHandleLayer, withFrame: leftFrame)
        drawLayer(rightHandleLayer, withFrame: rightFrame)
        drawLayer(runningLayer, withFrame: runningFrame)
        CATransaction.commit()
    }

    /// Run a indicator at value.
    /// value is in range of low to high. Any value out of this range will be ignored.
    /// - Parameter value: indicator value
    func run(at value: Double) {
        if value > rightHandleValue || value < leftHandleValue { return }
        runningLayerValue = value

        let runningCenter = positionForValue(runningLayerValue, layerWidth: runningWidth)
        let runningY = (topBottomPadding + 5) / 2
        let runningFrame = CGRect(x: runningCenter - runningWidth/2.0, y: runningY, width: runningWidth, height: handleHeight-5)
        runningLayer.isHidden = false
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        drawLayer(runningLayer, withFrame: runningFrame)
        CATransaction.commit()
    }

    func drawLayer(_ layer: CAShapeLayer, withFrame layerFrame: CGRect) {
        layer.frame = layerFrame
        let handleFrame = layer.bounds.insetBy(dx: 2.0, dy: 2.0) // should use bounds
        let cornerRadius = handleFrame.height * 0.5
        let handlePath = UIBezierPath(roundedRect: handleFrame, cornerRadius: cornerRadius)
        layer.path = handlePath.cgPath
    }

    func isTouchingHandles(at point: CGPoint) -> Bool {
        return leftHandleLayer.frame.contains(point) || rightHandleLayer.frame.contains(point)
    }

    func hideRunningIndicator(_ willBeHidden: Bool) {
        runningLayer.isHidden = willBeHidden
    }

    // MARK: TOUCH EVENT
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        previousLocation = touch.location(in: self)
        hideRunningIndicator(true)
        if leftHandleLayer.frame.contains(previousLocation) {
            isLeftHandleSelected = true
            return true
        } else if rightHandleLayer.frame.contains(previousLocation) {
            isRightHandleSelected = true
            return true
        } else {
            return false
        }
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)

        let deltaLocation = Double(location.x - previousLocation.x)
        let deltaValue = deltaLocation * (maximumValue - minimumValue) / Double(bounds.width - handleWidth)

        previousLocation = location

        if isLeftHandleSelected {
            leftHandleValue = boundValue(leftHandleValue + deltaValue, toLower: minimumValue, upperValue: rightHandleValue - gapBetweenHandles)
        } else {
            rightHandleValue = boundValue(rightHandleValue + deltaValue, toLower: leftHandleValue + gapBetweenHandles, upperValue: maximumValue)
        }

        sendActions(for: .valueChanged)
        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        isLeftHandleSelected = false
        isRightHandleSelected = false
        sendActions(for: .touchDragExit)
    }

    // MARK: Calculation
    func positionForValue(_ value: Double, layerWidth: CGFloat) -> CGFloat {
        return (bounds.size.width - layerWidth) * CGFloat(value - minimumValue) / CGFloat(maximumValue - minimumValue) + (layerWidth / 2)
    }

    func boundValue(_ value: Double, toLower lowerValue: Double, upperValue: Double) -> Double {
        return min(upperValue, max(value, lowerValue))
    }
}
