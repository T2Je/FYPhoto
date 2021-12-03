//
//  PhotoPickerTopBar.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/2/4.
//

import UIKit

class PhotoPickerTopBar: UIView {
    let cancelButton = UIButton()
    let titleView = PickerAlbulmTitleView()

    var dismiss: (() -> Void)?

    var albulmTitleTapped: (() -> Void)? {
        didSet {
            titleView.tapped = albulmTitleTapped
        }
    }

    init(colorStyle: FYColorConfiguration.BarColor, safeAreaInsetsTop: CGFloat) {
        super.init(frame: .zero)
        backgroundColor = colorStyle.backgroundColor
        cancelButton.layer.cornerRadius = 4
        cancelButton.layer.masksToBounds = true
        cancelButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        cancelButton.backgroundColor = colorStyle.itemBackgroundColor
        cancelButton.setTitle(L10n.cancel, for: .normal)
        cancelButton.setTitleColor(colorStyle.itemTintColor, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        cancelButton.addTarget(self, action: #selector(cancelButtonClicked(_:)), for: .touchUpInside)

        addSubview(cancelButton)
        addSubview(titleView)
        titleView.titleColor = colorStyle.itemTintColor
        titleView.imageColor = colorStyle.itemTintColor

        makeConstraints(safeAreaInsetsTop: safeAreaInsetsTop)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String) {
        titleView.title = title
    }

    fileprivate func makeConstraints(safeAreaInsetsTop: CGFloat) {
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelButton.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: safeAreaInsetsTop/2),
            cancelButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15)
        ])

        titleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleView.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor),
            titleView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            titleView.widthAnchor.constraint(equalToConstant: 100),
            titleView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc
    fileprivate func cancelButtonClicked(_ sender: UIButton) {
        dismiss?()
    }

}
