//
//  FYDetectingImageView.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/22.
//

import UIKit

protocol FYDetectingImageViewDelegate: class {
    func handleImageViewSingleTap(_ touchPoint: CGPoint)
    func handleImageViewDoubleTap(_ touchPoint: CGPoint)
}

class FYDetectingImageView: UIImageView {

    weak var delegate: FYDetectingImageViewDelegate?

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        isUserInteractionEnabled = true

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(FYDetectingImageView.doubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)

//         use navigationcontroller.hideBarsOnTap instead
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(FYDetectingImageView.singleTap(_:)))
        singleTap.require(toFail: doubleTap)
        addGestureRecognizer(singleTap)


    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func singleTap(_ tap: UITapGestureRecognizer) {
        delegate?.handleImageViewSingleTap(tap.location(in: self))
    }

    @objc func doubleTap(_ tap: UITapGestureRecognizer) {
        delegate?.handleImageViewDoubleTap(tap.location(in: self))
    }
}
