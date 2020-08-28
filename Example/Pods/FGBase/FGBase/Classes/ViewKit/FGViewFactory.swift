//
//  FGViewFactory.swift
//  FGBase
//
//  Created by kun wang on 2019/09/05.
//

import Foundation

@objc public class FGViewFactory: NSObject {
    @objc public static func commitButton(withFrame rect: CGRect, title: String?) -> UIButton {

        let button = UIButton(frame: rect)
        let normalImage = UIImage(color: FGUIConfiguration.shared.navBGColor,
                                  size: CGSize(width: button.frame.size.width,
                                               height: button.frame.size.height))
        let highlightedImage = UIImage(color: FGUIConfiguration.shared.navBGColor.withAlphaComponent(0.8),
                                       size: CGSize(width: button.frame.size.width,
                                                    height: button.frame.size.height))
        button.setBackgroundImage(normalImage, for: .normal)
        button.setBackgroundImage(highlightedImage, for: .highlighted)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.setTitle(title, for: .normal)
        button.setTitle(title, for: .highlighted)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.white, for: .highlighted)
        return button
    }

    @objc public static func nextImageView(withTintColor color: UIColor?) -> UIImageView {
        let imageView = UIImageView()
        if color != nil {
            imageView.image = "fg_ic_more_gray".baseImage?.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = UIColor.white
        } else {
            imageView.image = "fg_ic_more_gray".baseImage
        }
        return imageView
    }
}
