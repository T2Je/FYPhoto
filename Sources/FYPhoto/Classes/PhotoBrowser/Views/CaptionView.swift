//
//  CaptionView.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/8/21.
//

import UIKit

class CaptionView: UIStackView {

    let contentLabel = UILabel()
    let signatureLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .vertical
        spacing = 5
        distribution = .fillProportionally
        contentLabel.backgroundColor = .clear
        contentLabel.textAlignment = .left
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.font = UIFont.systemFont(ofSize: 17)
        contentLabel.textColor = .white
        contentLabel.numberOfLines = 0

        signatureLabel.backgroundColor = .clear
        signatureLabel.textAlignment = .right
        signatureLabel.textColor = .white
        signatureLabel.font = UIFont.systemFont(ofSize: 14)

        addArrangedSubview(contentLabel)
        addArrangedSubview(signatureLabel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(content: String?, signature: String?) {
        contentLabel.text = content
        signatureLabel.text = signature
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: contentLabel.intrinsicContentSize.height + signatureLabel.intrinsicContentSize.height + 5)
    }
}
