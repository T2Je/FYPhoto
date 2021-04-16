//
//  CropOverlayHandlesView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/16.
//

import Foundation

class CropOverlayHandlesView: UIView {
    let edgeShapeView = UIView()
    
    private let cornerTopLeftHorizontalView = UIView()
    private let cornerTopLeftVerticalView = UIView()

    private let cornerTopRightHorizontalView = UIView()
    private let cornerTopRightVerticalView = UIView()

    private let cornerBottomLeftHorizontalView = UIView()
    private let cornerBottomLeftVerticalView = UIView()

    private let cornerBottomRightHorizontalView = UIView()
    private let cornerBottomRightVerticalView = UIView()
    
    init() {
        super.init(frame: .zero)
        addSubview(edgeShapeView)
        edgeShapeView.translatesAutoresizingMaskIntoConstraints = false
        
        [cornerTopLeftHorizontalView,
         cornerTopLeftVerticalView,
         cornerTopRightHorizontalView,
         cornerTopRightVerticalView,
         cornerBottomLeftHorizontalView,
         cornerBottomLeftVerticalView,
         cornerBottomRightHorizontalView,
         cornerBottomRightVerticalView
        ].forEach {
            $0.backgroundColor = .white
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        edgeShapeView.layer.borderWidth = 1
        edgeShapeView.layer.borderColor = UIColor.white.cgColor
        makeConstraints()
    }
    
    func makeConstraints() {
        let verticalHandleWidth: CGFloat = 3
        let verticalHandleHeight: CGFloat = 20
        
        let horizontalHandleWidth: CGFloat = verticalHandleHeight
        let horizontalHandleHeight: CGFloat = verticalHandleWidth
        
        let padding: CGFloat = verticalHandleWidth
        
        NSLayoutConstraint.activate([
            edgeShapeView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            edgeShapeView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            edgeShapeView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            edgeShapeView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0)
        ])
        
        NSLayoutConstraint.activate([
            cornerTopLeftHorizontalView.topAnchor.constraint(equalTo: topAnchor, constant: -padding),
            cornerTopLeftHorizontalView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -padding),
            cornerTopLeftHorizontalView.widthAnchor.constraint(equalToConstant: horizontalHandleWidth),
            cornerTopLeftHorizontalView.heightAnchor.constraint(equalToConstant: horizontalHandleHeight)
        ])
        
        NSLayoutConstraint.activate([
            cornerTopLeftVerticalView.topAnchor.constraint(equalTo: topAnchor, constant: -verticalHandleWidth),
            cornerTopLeftVerticalView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -verticalHandleWidth),
            cornerTopLeftVerticalView.widthAnchor.constraint(equalToConstant: verticalHandleWidth),
            cornerTopLeftVerticalView.heightAnchor.constraint(equalToConstant: verticalHandleHeight)
        ])
        
        NSLayoutConstraint.activate([
            cornerBottomLeftVerticalView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: padding),
            cornerBottomLeftVerticalView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -padding),
            cornerBottomLeftVerticalView.widthAnchor.constraint(equalToConstant: verticalHandleWidth),
            cornerBottomLeftVerticalView.heightAnchor.constraint(equalToConstant: verticalHandleHeight)
        ])
        
        NSLayoutConstraint.activate([
            cornerBottomLeftHorizontalView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: padding),
            cornerBottomLeftHorizontalView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -padding),
            cornerBottomLeftHorizontalView.widthAnchor.constraint(equalToConstant: horizontalHandleWidth),
            cornerBottomLeftHorizontalView.heightAnchor.constraint(equalToConstant: horizontalHandleHeight)
        ])
        
        NSLayoutConstraint.activate([
            cornerBottomRightHorizontalView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: padding),
            cornerBottomRightHorizontalView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: padding),
            cornerBottomRightHorizontalView.widthAnchor.constraint(equalToConstant: horizontalHandleWidth),
            cornerBottomRightHorizontalView.heightAnchor.constraint(equalToConstant: horizontalHandleHeight)
        ])
        
        NSLayoutConstraint.activate([
            cornerBottomRightVerticalView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: padding),
            cornerBottomRightVerticalView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: padding),
            cornerBottomRightVerticalView.widthAnchor.constraint(equalToConstant: verticalHandleWidth),
            cornerBottomRightVerticalView.heightAnchor.constraint(equalToConstant: verticalHandleHeight)
        ])
        
        NSLayoutConstraint.activate([
            cornerTopRightVerticalView.topAnchor.constraint(equalTo: topAnchor, constant: -padding),
            cornerTopRightVerticalView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: padding),
            cornerTopRightVerticalView.widthAnchor.constraint(equalToConstant: verticalHandleWidth),
            cornerTopRightVerticalView.heightAnchor.constraint(equalToConstant: verticalHandleHeight)
        ])
        
        NSLayoutConstraint.activate([
            cornerTopRightHorizontalView.topAnchor.constraint(equalTo: topAnchor, constant: -padding),
            cornerTopRightHorizontalView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: padding),
            cornerTopRightHorizontalView.widthAnchor.constraint(equalToConstant: horizontalHandleWidth),
            cornerTopRightHorizontalView.heightAnchor.constraint(equalToConstant: horizontalHandleHeight)
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
