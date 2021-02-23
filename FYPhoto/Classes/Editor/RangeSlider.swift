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
    
    var previousLocation: CGPoint = .zero
    
    let handleWidth: CGFloat = 13
    
    lazy var gapBetweenHandle: Double = 0.6 * Double(handleWidth) * (maximumValue - minimumValue) / Double(bounds.width)
    
    let leftHandleLayer = CAShapeLayer()
    let rightHandleLayer = CAShapeLayer()
    
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
        layer.addSublayer(leftHandleLayer)
        layer.addSublayer(rightHandleLayer)
    }
    
    func updateLayerFrames() {
        let leftCenter = positionForValue(leftHandleValue)
        let rightCenter = positionForValue(rightHandleValue)
        
        let leftFrame = CGRect(x: leftCenter - handleWidth/2.0, y: 5, width: handleWidth, height: 50)
        let rightFrame = CGRect(x: rightCenter - handleWidth/2.0, y: 5, width: handleWidth, height: 50)
                
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        drawHandle(leftHandleLayer, withFrame: leftFrame)
        drawHandle(rightHandleLayer, withFrame: rightFrame)
        CATransaction.commit()
    }
    
    func drawHandle(_ handle: CAShapeLayer, withFrame layerFrame: CGRect) {
        handle.frame = layerFrame
        
        let handleFrame = handle.bounds.insetBy(dx: 2.0, dy: 2.0) // should use bounds
        let cornerRadius = handleFrame.height * 0.5

        let handlePath = UIBezierPath(roundedRect: handleFrame, cornerRadius: cornerRadius)
        
        handle.fillColor = UIColor.red.cgColor
        handle.path = handlePath.cgPath
    }
    
    //  MARK: TOUCH EVENT
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        previousLocation = touch.location(in: self)
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
            leftHandleValue = boundValue(leftHandleValue + deltaValue, toLower: minimumValue, upperValue: rightHandleValue - gapBetweenHandle)
        } else {
            rightHandleValue = boundValue(rightHandleValue + deltaValue, toLower: leftHandleValue + gapBetweenHandle, upperValue: maximumValue)
        }

        sendActions(for: .valueChanged)
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        isLeftHandleSelected = false
        isRightHandleSelected = false
    }
    
    // MARK: Calculation
    func positionForValue(_ value: Double) -> CGFloat {
        return (bounds.size.width - handleWidth) * CGFloat(value - minimumValue) / CGFloat(maximumValue - minimumValue) + (handleWidth / 2)
    }
    
    func boundValue(_ value: Double, toLower lowerValue: Double, upperValue: Double) -> Double {
        return min(upperValue, max(value, lowerValue))
    }
}
