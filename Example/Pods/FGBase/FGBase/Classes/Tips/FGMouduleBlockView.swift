//
//  FGMouduleBlockView.swift
//  FGBase
//
//  Created by kun wang on 2019/09/05.
//

import UIKit

@objc public class FGMouduleBlockView: UIView {
    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 210, height: 215))
        imageView.image = "fg_ic_module_block".baseImage
        addSubview(imageView)
        imageView.center = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
