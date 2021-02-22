//
//  RangeSlider.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/2/20.
//

import UIKit

class RangeSlider: UIControl {

    var leftHandleIsSelected: Bool = true
    
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
    
    var leftHandleValue: Double = 0.0
    
    var rightHandleValue: Double = 100.0
    
    var previousLocation: CGPoint = .zero
    
    let handleWidth: CGFloat = 13
    
    let leftHandleLayer = CAShapeLayer()
    let rightHandleLayer = CAShapeLayer()
    
    func initSublayers() {
        layer.addSublayer(leftHandleLayer)
        layer.addSublayer(rightHandleLayer)
    }
    
    func updateLayerFrames() {
        let leftCenter = positionForValue(leftHandleValue)
        let rightCenter = positionForValue(rightHandleValue)
        
        let leftFrame = CGRect(x: leftCenter - handleWidth/2.0, y: -5.0, width: handleWidth, height: 50)
        drawHandle(leftHandleLayer, withFrame: leftFrame)
                    
        let rightFrame = CGRect(x: rightCenter - handleWidth/2.0, y: -5.0, width: handleWidth, height: 50)
        drawHandle(rightHandleLayer, withFrame: rightFrame)
    }
    
    func drawHandle(_ handle: CAShapeLayer, withFrame frame: CGRect) {
        handle.frame = frame
        let thumbFrame = frame.insetBy(dx: 2.0, dy: 2.0)
        let cornerRadius = thumbFrame.height * 0.5
        let thumbPath = UIBezierPath(roundedRect: thumbFrame, cornerRadius: cornerRadius)
        
        handle.fillColor = UIColor.white.cgColor
        handle.path = thumbPath.cgPath
    }
    
    func positionForValue(_ value: Double) -> CGFloat {
        return (bounds.size.width - handleWidth) * CGFloat(value - minimumValue) / CGFloat(maximumValue - minimumValue) + (handleWidth / 2)
    }
}
