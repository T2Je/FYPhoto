//
//  RangeSlider.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/2/20.
//

import UIKit

public class RangeSlider: UIControl {

    var leftHandleIsSelected: Bool = false
    var rightHandleIsSelected: Bool = false
    
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
    
    let leftHandleLayer = CAShapeLayer()
    let rightHandleLayer = CAShapeLayer()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .systemBlue
        initSublayers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
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
        
        let leftFrame = CGRect(x: leftCenter - handleWidth/2.0, y: 0, width: handleWidth, height: 50)
//        let leftFrame = CGRect(x: 128, y: 0, width: 12, height: 50)
        drawHandle(leftHandleLayer, withFrame: leftFrame)
                            
        let rightFrame = CGRect(x: rightCenter - handleWidth/2.0, y: 0, width: handleWidth, height: 50)
        drawHandle(rightHandleLayer, withFrame: rightFrame)
        print("left frame : \(leftHandleLayer.frame)")
//        print("right frame : \(rightHandleLayer.frame)")
    }
    
    func drawHandle(_ handle: CAShapeLayer, withFrame layerFrame: CGRect) {
        handle.frame = layerFrame
        let handleFrame = handle.bounds.insetBy(dx: 2.0, dy: 2.0) // should use bounds
        let cornerRadius = handleFrame.height * 0.5

        let handlePath = UIBezierPath(roundedRect: handleFrame, cornerRadius: cornerRadius)
        
        handle.fillColor = UIColor.red.cgColor
        handle.path = handlePath.cgPath
    }
    
    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        previousLocation = touch.location(in: self)
        print("touch location: \(previousLocation)")
        if leftHandleLayer.frame.contains(previousLocation) {
            leftHandleIsSelected = true
            return true
        } else if rightHandleLayer.frame.contains(previousLocation) {
            rightHandleIsSelected = true
            return true
        } else {
            return false
        }
    }
    
    public override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        
        let deltaLocation = Double(location.x - previousLocation.x)
        let deltaValue = (maximumValue - minimumValue) * deltaLocation / Double(bounds.width - handleWidth*2)
        print("delta location = \(deltaLocation)")
        
        previousLocation = location
        
        if leftHandleIsSelected {
            leftHandleValue = boundValue(leftHandleValue + deltaValue, toLower: minimumValue, upperValue: rightHandleValue - Double(handleWidth))
        } else {
            rightHandleValue = boundValue(rightHandleValue + deltaValue, toLower: leftHandleValue + Double(handleWidth), upperValue: maximumValue)
        }
        print("delta value: \(deltaValue)")

        sendActions(for: .valueChanged)
        return true
    }
    
    public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        leftHandleIsSelected = false
        rightHandleIsSelected = false
    }
    
    // Calculation
    func positionForValue(_ value: Double) -> CGFloat {
        return (bounds.size.width - handleWidth) * CGFloat(value - minimumValue) / CGFloat(maximumValue - minimumValue) + (handleWidth / 2)
    }
    
    func boundValue(_ value: Double, toLower lowerValue: Double, upperValue: Double) -> Double {
        return min(upperValue, max(value, lowerValue))
    }
    
    var gapBetweenThumbs: Double {
        return 0.6 * Double(handleWidth) * (maximumValue - minimumValue) / Double(bounds.width)
    }
}
