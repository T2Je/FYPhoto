//
//  InteractiveCropGuideView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/3/26.
//

import Foundation

class InteractiveCropGuideView: UIView {
    private let topLeftControlPointView = TapExpandedView(horizontal: 16, vertical: 16)
    private let topRightControlPointView = TapExpandedView(horizontal: 16, vertical: 16)
    private let bottomLeftControlPointView = TapExpandedView(horizontal: 16, vertical: 16)
    private let bottomRightControlPointView = TapExpandedView(horizontal: 16, vertical: 16)

    private let topControlPointView = TapExpandedView(horizontal: 0, vertical: 16)
    private let rightControlPointView = TapExpandedView(horizontal: 16, vertical: 0)
    private let leftControlPointView = TapExpandedView(horizontal: 16, vertical: 0)
    private let bottomControlPointView = TapExpandedView(horizontal: 0, vertical: 16)
    
    private let handlesView = CropOverlayHandlesView()
    
    private let minimumSize = CGSize(width: 80, height: 80)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    
        addSubview(handlesView)
        
        [topLeftControlPointView,
         topRightControlPointView,
         bottomLeftControlPointView,
         bottomRightControlPointView,
         topControlPointView,
         rightControlPointView,
         leftControlPointView,
         bottomControlPointView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
    
        makeConstraints()
        
        addGestures()
        
    }
    
    func makeConstraints() {
        handlesView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            handlesView.topAnchor.constraint(equalTo: topAnchor),
            handlesView.leadingAnchor.constraint(equalTo: leadingAnchor),
            handlesView.bottomAnchor.constraint(equalTo: bottomAnchor),
            handlesView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        let length: CGFloat = 1
        NSLayoutConstraint.activate([
            topLeftControlPointView.topAnchor.constraint(equalTo: topAnchor),
            topLeftControlPointView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topLeftControlPointView.widthAnchor.constraint(equalToConstant: length),
            topLeftControlPointView.heightAnchor.constraint(equalToConstant: length)
        ])
    }
    
    func addGestures() {
        let topLeftGesture = UIPanGestureRecognizer(target: self, action: #selector(handleTopLeftViewPanGesture(_:)))
        topLeftControlPointView.addGestureRecognizer(topLeftGesture)
        
        let bottomLeftGesture = UIPanGestureRecognizer(target: self, action: #selector(handleBottomLeftViewPanGesture(_:)))
        bottomLeftControlPointView.addGestureRecognizer(bottomLeftGesture)
        
        let bottomRightGesture = UIPanGestureRecognizer(target: self, action: #selector(handleBottomRightViewPanGesture(_:)))
        bottomRightControlPointView.addGestureRecognizer(bottomRightGesture)
        
        let topRightGesture = UIPanGestureRecognizer(target: self, action: #selector(handleTopRightViewPanGesture(_:)))
        topRightControlPointView.addGestureRecognizer(topRightGesture)
    }
    
    // Pan actions
    @objc func handleTopLeftViewPanGesture(_ panGesture: UIPanGestureRecognizer) {
        
    }
    
    @objc func handleTopRightViewPanGesture(_ panGesture: UIPanGestureRecognizer) {
        
    }
    
    @objc func handleBottomLeftViewPanGesture(_ panGesture: UIPanGestureRecognizer) {
        
    }
    
    @objc func handleBottomRightViewPanGesture(_ panGesture: UIPanGestureRecognizer) {
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
