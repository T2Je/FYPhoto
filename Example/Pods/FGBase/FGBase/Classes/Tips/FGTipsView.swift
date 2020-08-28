//
//  FGTipsView.swift
//  FGBase
//
//  Created by kun wang on 2018/7/19.
//

import Foundation


//_label.textColor = [UIColor fg_colorWithHex:0x9F9F9F];
//_label.font = [UIFont systemFontOfSize:14];

@objc class FGTipsView: UIView {
    @objc init(container: UIView, tips: NSAttributedString, image: UIImage) {
        super.init(frame: CGRect(x: 0, y: 0, width: container.bounds.size.width, height: container.bounds.size.height))
        self.backgroundColor = .white
        addSubview(label)
        addSubview(imageView)
        label.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        label.attributedText = tips

        // center imageView horizontally in self
        self.addConstraint(NSLayoutConstraint(item: imageView, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1.0, constant: 0.0));

        // center imageView vertically in self
        self.addConstraint(NSLayoutConstraint(item: imageView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1.0, constant: -80.0));

        // center label horizontally in self
        self.addConstraint(NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1.0, constant: 0.0));

        // center label vertically in self
        self.addConstraint(NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: imageView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 20.0));
        // align label from the left and right
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[view]-15-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["view": label]));


    }

    @objc static func hideTipsView(at container: UIView) {
        var tipsView: FGTipsView? = nil
        for view in container.subviews where view is FGTipsView {
            tipsView = view as? FGTipsView
        }
        tipsView?.removeFromSuperview()
        tipsView = nil
    }

    lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    var imageView = UIImageView()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
