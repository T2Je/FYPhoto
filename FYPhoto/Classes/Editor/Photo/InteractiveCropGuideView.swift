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
    
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    var constraintsWhenPanning: [NSLayoutConstraint] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        
//        translatesAutoresizingMaskIntoConstraints = false
        
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
        
        NSLayoutConstraint.activate([
            bottomLeftControlPointView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomLeftControlPointView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomLeftControlPointView.widthAnchor.constraint(equalToConstant: length),
            bottomLeftControlPointView.heightAnchor.constraint(equalToConstant: length)
        ])
        
        NSLayoutConstraint.activate([
            topRightControlPointView.topAnchor.constraint(equalTo: topAnchor),
            topRightControlPointView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topRightControlPointView.widthAnchor.constraint(equalToConstant: length),
            topRightControlPointView.heightAnchor.constraint(equalToConstant: length)
        ])
        
        NSLayoutConstraint.activate([
            bottomRightControlPointView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomRightControlPointView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomRightControlPointView.widthAnchor.constraint(equalToConstant: length),
            bottomRightControlPointView.heightAnchor.constraint(equalToConstant: length)
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
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.insetBy(dx: -16, dy: -16).contains(point)
    }
    
    // Pan actions
    
    @objc func handleTopLeftViewPanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panGestureBegan()
            activeBottomConstraint()
            activeTrailingConstraint()
            activeWidthConstraint()
            activeHeightConstraint()
            fallthrough
        case .changed:
            defer {
              gesture.setTranslation(.zero, in: self)
            }
            let translation = gesture.translation(in: self)
            widthConstraint?.constant -= translation.x
            heightConstraint?.constant -= translation.y
        case .ended, .cancelled, .failed:
            panGestureEnded()
        default:
            break
        }
    }
    
    @objc func handleTopRightViewPanGesture(_ gesture: UIPanGestureRecognizer) {
        
    }
    
    @objc func handleBottomLeftViewPanGesture(_ gesture: UIPanGestureRecognizer) {
        
    }
    
    @objc func handleBottomRightViewPanGesture(_ gesture: UIPanGestureRecognizer) {
        
    }
    
    func panGestureBegan() {
        handlesView.startResizing()
    }
    
    func panGestureEnded() {
        handlesView.endResizing()
    }
    
    // Constraints for pan gestures
    func activeBottomConstraint() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        let temp = bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: frame.maxY - superview.frame.maxY)
        temp.isActive = true
        constraintsWhenPanning.append(temp)
    }
    
    func activeTrailingConstraint() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        let temp = trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: frame.maxX - superview.frame.maxX)
        temp.isActive = true
        constraintsWhenPanning.append(temp)
    }
    
    func activeWidthConstraint() {
        translatesAutoresizingMaskIntoConstraints = false
        widthConstraint = widthAnchor.constraint(equalToConstant: bounds.width)
        widthConstraint?.isActive = true
        widthConstraint?.priority = .defaultLow
        
        let temp = widthAnchor.constraint(greaterThanOrEqualToConstant: minimumSize.width)
        temp.isActive = true
        constraintsWhenPanning.append(temp)
    }
    
    func activeHeightConstraint() {
        translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = heightAnchor.constraint(equalToConstant: bounds.height)
        heightConstraint?.isActive = true
        heightConstraint?.priority = .defaultLow
        
        let temp = heightAnchor.constraint(greaterThanOrEqualToConstant: minimumSize.height)
        temp.isActive = true
        constraintsWhenPanning.append(temp)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
