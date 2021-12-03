//
//  CropViewBackBlurredView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/22.
//

import UIKit

class CropViewMaskManager {

    private let effectView: CropVisualEffectView
    private let dimmingView: CropDimmingView

    let dimmingOpacity: Float
    init(effect: UIBlurEffect = UIBlurEffect(style: .dark),
         dimmingOpacity: Float = 0.5) {
        self.dimmingOpacity = dimmingOpacity

        effectView = CropVisualEffectView(effect: effect)
        dimmingView = CropDimmingView()
        dimmingView.alpha = 0

        effectView.isUserInteractionEnabled = false
        dimmingView.isUserInteractionEnabled = false
    }

    private var effectFilledLayer: CALayer?
    private var dimmingFilledLayer: CALayer?

    func showIn(_ view: UIView) {
        view.addSubview(effectView)
        view.addSubview(dimmingView)

        effectView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: view.topAnchor),
            effectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            effectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            effectView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        dimmingView.removeFromSuperview()
        effectView.removeFromSuperview()
    }

    func showVisualEffectBackground() {
        UIView.animate(withDuration: 0.5) {
            self.dimmingView.alpha = 0
            self.effectView.alpha = 1
        }
    }

    func showDimmingBackground() {
        UIView.animate(withDuration: 0.1) {
            self.effectView.alpha = 0
            self.dimmingView.alpha = 1
        }
    }

    func rotateMask(_ rect: CGRect) {
        effectView.createBrandNewMask(rect)
        dimmingView.setMask(rect, animated: false)
    }

    func recreateTransparentRect(_ rect: CGRect, animated: Bool) {
        createTransparentRect(with: rect, animated: animated)
    }

    func createTransparentRect(with insideRect: CGRect, animated: Bool) {
        effectView.setMask(insideRect, animated: animated)
        dimmingView.setMask(insideRect, animated: animated)
    }
}
