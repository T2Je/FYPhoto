//
//  PhotoPickerBottomToolView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/18.
//

import UIKit

protocol PhotoPickerBottomToolViewDelegate: AnyObject {
    func bottomToolViewPreviewButtonClicked()
    func bottomToolViewDoneButtonClicked()
}

final class PhotoPickerBottomToolView: UIView {
    weak var delegate: PhotoPickerBottomToolViewDelegate?

    private let previewButton = UIButton()
    private let countLabel = UILabel()
    private let doneButton = UIButton()

    var count: Int = 0 {
        willSet {
            countLabel.text = "\(newValue)/\(selectionLimit)"
            if newValue > 0 {
                countLabel.textColor = previewButton.titleColor(for: .normal)
            } else {
                countLabel.textColor = previewButton.titleColor(for: .disabled)
            }
            previewButton.isEnabled = newValue > 0
            doneButton.isEnabled = newValue > 0
        }
    }

    private let selectionLimit: Int
    private let safeAreaInsetsBottom: CGFloat

    init(selectionLimit: Int, colorStyle: FYColorConfiguration.BarColor, safeAreaInsetsBottom: CGFloat = 0) {
        self.selectionLimit = selectionLimit
        self.safeAreaInsetsBottom = safeAreaInsetsBottom
        super.init(frame: .zero)
        backgroundColor = colorStyle.backgroundColor

        addSubview(previewButton)
        addSubview(countLabel)
        addSubview(doneButton)

        previewButton.setTitle(L10n.preview, for: .normal)
        previewButton.layer.cornerRadius = 4
        previewButton.layer.masksToBounds = true
        previewButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        previewButton.backgroundColor = colorStyle.itemBackgroundColor
        previewButton.setTitleColor(colorStyle.itemTintColor, for: .normal)
        previewButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
        previewButton.addTarget(self, action: #selector(buttonClicked(_:)), for: .touchUpInside)
        previewButton.isEnabled = false
        previewButton.setTitleColor(colorStyle.itemDisableColor, for: .disabled)

        doneButton.setTitle(L10n.done, for: .normal)
        doneButton.layer.cornerRadius = 4
        doneButton.layer.masksToBounds = true
        doneButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        doneButton.backgroundColor = colorStyle.itemBackgroundColor
        doneButton.setTitleColor(colorStyle.itemTintColor, for: .normal)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        doneButton.addTarget(self, action: #selector(buttonClicked(_:)), for: .touchUpInside)
        doneButton.isEnabled = false
        doneButton.setTitleColor(colorStyle.itemDisableColor, for: .disabled)

        countLabel.textColor = colorStyle.itemDisableColor
        countLabel.font = UIFont.systemFont(ofSize: 13, weight: .thin)
        countLabel.textAlignment = .right
        countLabel.text = "0/\(selectionLimit)"

        makeConstraints()
    }

    func makeConstraints() {
        previewButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            previewButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
            previewButton.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -safeAreaInsetsBottom/2)
        ])

        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15),
            doneButton.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -safeAreaInsetsBottom/2)
        ])

        countLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            countLabel.trailingAnchor.constraint(equalTo: self.doneButton.leadingAnchor, constant: -10),
            countLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -safeAreaInsetsBottom/2)
        ])
    }

    @objc func buttonClicked(_ sender: UIButton) {
        if sender == previewButton {
            delegate?.bottomToolViewPreviewButtonClicked()
        } else {
            delegate?.bottomToolViewDoneButtonClicked()
        }
    }

    func updateCount(_ count: Int) {
        self.count = count
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

