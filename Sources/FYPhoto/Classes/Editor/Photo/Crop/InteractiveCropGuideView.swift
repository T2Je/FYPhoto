//
//  InteractiveCropGuideView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/3/26.
//

import Foundation
import UIKit

class InteractiveCropGuideView: UIView {

    var resizeBegan: ((CropViewHandle) -> Void)?
    var resizeCancelled = {}
    var resizeEnded: ((_ frame: CGRect) -> Void)?

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

    var maximumRect: CGRect = .zero

    var aspectRatio: Double?

    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    var constraintsWhenPanning: [NSLayoutConstraint] = []

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true

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

        NSLayoutConstraint.activate([
            topControlPointView.topAnchor.constraint(equalTo: topAnchor),
            topControlPointView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            topControlPointView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            topControlPointView.heightAnchor.constraint(equalToConstant: 1)
        ])

        NSLayoutConstraint.activate([
            leftControlPointView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            leftControlPointView.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftControlPointView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            leftControlPointView.widthAnchor.constraint(equalToConstant: 1)
        ])

        NSLayoutConstraint.activate([
            bottomControlPointView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomControlPointView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            bottomControlPointView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            bottomControlPointView.heightAnchor.constraint(equalToConstant: 1)
        ])

        NSLayoutConstraint.activate([
            rightControlPointView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            rightControlPointView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            rightControlPointView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightControlPointView.widthAnchor.constraint(equalToConstant: 1)
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

        let topGesture = UIPanGestureRecognizer(target: self, action: #selector(handleTopControlViewPanGesture(_:)))
        topControlPointView.addGestureRecognizer(topGesture)
        let leftGesture = UIPanGestureRecognizer(target: self, action: #selector(handleLeftControlViewPanGesture(_:)))
        leftControlPointView.addGestureRecognizer(leftGesture)
        let bottomGesture = UIPanGestureRecognizer(target: self, action: #selector(handleBottomControlViewPanGesture(_:)))
        bottomControlPointView.addGestureRecognizer(bottomGesture)
        let rightGesture = UIPanGestureRecognizer(target: self, action: #selector(handleRightControlViewPanGesture(_:)))
        rightControlPointView.addGestureRecognizer(rightGesture)
    }

    // MARK: - Pan actions
    // Corner points
    @objc func handleTopLeftViewPanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panGestureBegan(.leftTop)

            activeLockedRatioConstraint()

            activeTopMaxConstraint()
            activeLeadingMaxConstraint()

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
        case .cancelled:
            panGestureCancelled()
        case .ended, .failed:
            panGestureEnded()
        default:
            break
        }
    }

    @objc func handleTopRightViewPanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panGestureBegan(.rightTop)

            activeLockedRatioConstraint()

            activeTopMaxConstraint()
            activeTrailingMaxConstraint()

            activeBottomConstraint()
            activeLeadingConstraint()
            activeWidthConstraint()
            activeHeightConstraint()
            fallthrough
        case .changed:
            defer {
              gesture.setTranslation(.zero, in: self)
            }
            let translation = gesture.translation(in: self)
            widthConstraint?.constant += translation.x
            heightConstraint?.constant -= translation.y
        case .cancelled:
            panGestureCancelled()
        case .ended, .failed:
            panGestureEnded()
        default:
            break
        }
    }

    @objc func handleBottomLeftViewPanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panGestureBegan(.leftBottom)

            activeLockedRatioConstraint()

            activeBottomMaxConstraint()
            activeLeadingMaxConstraint()

            activeTopConstraint()
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
            heightConstraint?.constant += translation.y
        case .cancelled:
            panGestureCancelled()
        case .ended, .failed:
            panGestureEnded()
        default:
            break
        }
    }

    @objc func handleBottomRightViewPanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panGestureBegan(.rightBottom)

            activeLockedRatioConstraint()

            activeTrailingMaxConstraint()
            activeBottomMaxConstraint()

            activeTopConstraint()
            activeLeadingConstraint()
            activeWidthConstraint()
            activeHeightConstraint()
            fallthrough
        case .changed:
            defer {
              gesture.setTranslation(.zero, in: self)
            }
            let translation = gesture.translation(in: self)
            widthConstraint?.constant += translation.x
            heightConstraint?.constant += translation.y
        case .cancelled:
            panGestureCancelled()
        case .ended, .failed:
            panGestureEnded()
        default:
            break
        }
    }

    // Control lines
    @objc func handleTopControlViewPanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panGestureBegan(.top)

            activeLockedRatioConstraint()

            activeTopMaxConstraint()

            activeBottomConstraint()
            activeTrailingConstraint()
            activeHeightConstraint()
            activeWidthConstraint()
            fallthrough
        case .changed:
            defer {
              gesture.setTranslation(.zero, in: self)
            }
            let translation = gesture.translation(in: self)
            heightConstraint?.constant -= translation.y
        case .cancelled:
            panGestureCancelled()
        case .ended, .failed:
            panGestureEnded()
        default:
            break
        }
    }

    @objc func handleLeftControlViewPanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panGestureBegan(.left)

            activeLockedRatioConstraint()

            activeLeadingConstraint()

            activeTopConstraint()
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
        case .cancelled:
            panGestureCancelled()
        case .ended, .failed:
            panGestureEnded()
        default:
            break
        }
    }

    @objc func handleBottomControlViewPanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panGestureBegan(.bottom)

            activeLockedRatioConstraint()

            activeBottomMaxConstraint()

            activeTopConstraint()
            activeLeadingConstraint()
            activeWidthConstraint()
            activeHeightConstraint()
            fallthrough
        case .changed:
            defer {
              gesture.setTranslation(.zero, in: self)
            }
            let translation = gesture.translation(in: self)
            heightConstraint?.constant += translation.y
        case .cancelled:
            panGestureCancelled()
        case .ended, .failed:
            panGestureEnded()
        default:
            break
        }
    }

    @objc func handleRightControlViewPanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panGestureBegan(.right)

            activeLockedRatioConstraint()

            activeTrailingMaxConstraint()

            activeTopConstraint()
            activeLeadingConstraint()
            activeWidthConstraint()
            activeHeightConstraint()
            fallthrough
        case .changed:
            defer {
              gesture.setTranslation(.zero, in: self)
            }
            let translation = gesture.translation(in: self)
            widthConstraint?.constant += translation.x
        case .cancelled:
            panGestureCancelled()
        case .ended, .failed:
            panGestureEnded()
        default:
            break
        }
    }

    func panGestureBegan(_ handle: CropViewHandle) {
        resizeBegan?(handle)
        handlesView.startResizing()
    }

    func panGestureCancelled() {
        deactivePanningConstraints()
        resizeCancelled()
        handlesView.endResizing()
    }

    func panGestureEnded() {
        handlesView.endResizing()
        deactivePanningConstraints()
        resizeEnded?(frame)
    }

    // MARK: - Constraints for pan gestures
    func activeBottomConstraint() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        let temp = bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: frame.maxY - superview.bounds.maxY)
        temp.isActive = true
        constraintsWhenPanning.append(temp)
    }

    func activeTrailingConstraint() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        let temp = trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: frame.maxX - superview.bounds.maxX)
        temp.isActive = true
        constraintsWhenPanning.append(temp)
    }

    func activeLeadingConstraint() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        let temp = leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: frame.minX - superview.bounds.minX)
        temp.isActive = true
        constraintsWhenPanning.append(temp)
    }

    func activeTopConstraint() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        let temp = topAnchor.constraint(equalTo: superview.topAnchor, constant: frame.minY - superview.bounds.minY)
        temp.isActive = true
        constraintsWhenPanning.append(temp)
    }

    func activeWidthConstraint() {
        translatesAutoresizingMaskIntoConstraints = false
        widthConstraint = widthAnchor.constraint(equalToConstant: bounds.width)
        widthConstraint?.priority = .defaultLow
        widthConstraint?.isActive = true

        let temp = widthAnchor.constraint(greaterThanOrEqualToConstant: minimumSize.width)
        temp.isActive = true
        constraintsWhenPanning.append(temp)
    }

    func activeHeightConstraint() {
        translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = heightAnchor.constraint(equalToConstant: bounds.height)
        heightConstraint?.priority = .defaultLow
        heightConstraint?.isActive = true

        let temp = heightAnchor.constraint(greaterThanOrEqualToConstant: minimumSize.height)
        temp.isActive = true
        constraintsWhenPanning.append(temp)
    }

    func activeTopMaxConstraint() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        let temp = topAnchor.constraint(greaterThanOrEqualTo: superview.topAnchor, constant: maximumRect.minY)
        temp.isActive = true
        constraintsWhenPanning.append(temp)
    }

    func activeLeadingMaxConstraint() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        let temp = leadingAnchor.constraint(greaterThanOrEqualTo: superview.leadingAnchor, constant: maximumRect.minX)
        temp.isActive = true
        constraintsWhenPanning.append(temp)
    }

    func activeBottomMaxConstraint() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        let temp = bottomAnchor.constraint(lessThanOrEqualTo: superview.bottomAnchor, constant: maximumRect.maxY-superview.bounds.maxY)
        temp.isActive = true
        constraintsWhenPanning.append(temp)
    }

    func activeTrailingMaxConstraint() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        let temp = trailingAnchor.constraint(lessThanOrEqualTo: superview.trailingAnchor, constant: maximumRect.maxX-superview.bounds.maxX)
        temp.isActive = true
        constraintsWhenPanning.append(temp)
    }

    func activeLockedRatioConstraint() {
        if let ratio = aspectRatio {
            translatesAutoresizingMaskIntoConstraints = false
            let temp = widthAnchor.constraint(equalTo: heightAnchor, multiplier: CGFloat(ratio), constant: 1)
            temp.isActive = true
            constraintsWhenPanning.append(temp)
        }
    }

    func deactivePanningConstraints() {
        translatesAutoresizingMaskIntoConstraints = true
        let activedCons = [widthConstraint, heightConstraint].compactMap { $0 } + constraintsWhenPanning
        NSLayoutConstraint.deactivate(activedCons)
    }

    // MARK: - Ignore touches inside the control area
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)

        if view == self && bounds.insetBy(dx: 16, dy: 16).contains(point) {

            return nil
        }
        return view
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.insetBy(dx: -16, dy: -16).contains(point)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
