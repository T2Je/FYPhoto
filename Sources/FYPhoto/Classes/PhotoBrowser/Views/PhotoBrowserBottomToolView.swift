//
//  PhotoBrowserBottomToolView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/19.
//

import UIKit

protocol PhotoBrowserBottomToolViewDelegate: AnyObject {
    func browserBottomToolViewPlayButtonClicked()
    func browserBottomToolViewDoneButtonClicked()
    func browserBottomToolViewEditButtonClicked()
}

extension PhotoBrowserBottomToolViewDelegate {
    func browserBottomToolViewPlayButtonClicked() {}
    func browserBottomToolViewDoneButtonClicked() {}
}

class PhotoBrowserBottomToolView: UIView {
    weak var delegate: PhotoBrowserBottomToolViewDelegate?

    let editButton = UIButton()
    let playButton = UIButton()
    let doneButton = UIButton()
    private let safeAreaInsetsBottom: CGFloat
    private let colorStyle: FYColorConfiguration.BarColor

    init(colorStyle: FYColorConfiguration.BarColor, safeAreaInsetsBottom: CGFloat = 0) {
        self.colorStyle = colorStyle
        self.safeAreaInsetsBottom = safeAreaInsetsBottom
        super.init(frame: .zero)
        backgroundColor = colorStyle.backgroundColor
        self.layer.masksToBounds = true
        addPlayButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isVideo: Bool = false {
        willSet {
            playButton.isHidden = !newValue
        }
    }

    var isPlaying: Bool = false {
        willSet {
            if newValue != isPlaying {
                updatePlayButtonImage(isPlaying: newValue)
            }            
        }
    }

    fileprivate func addPlayButton() {
        addSubview(playButton)
        playButton.isEnabled = false
        playButton.setImage(Asset.icons8Play.image, for: .normal)
        playButton.addTarget(self, action: #selector(buttonClicked(_:)), for: .touchUpInside)
        playButton.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        let centerOffset = safeAreaInsetsBottom == 0 ? 0 : -(safeAreaInsetsBottom/2-5)
        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: centerOffset),
            playButton.widthAnchor.constraint(equalToConstant: 35),
            playButton.heightAnchor.constraint(equalToConstant: 35)
        ])
    }

    func addDoneButton() {
        addSubview(doneButton)
        doneButton.backgroundColor = colorStyle.itemBackgroundColor
        doneButton.setTitle(L10n.done, for: .normal)
        doneButton.addTarget(self, action: #selector(buttonClicked(_:)), for: .touchUpInside)
        doneButton.setTitleColor(colorStyle.itemTintColor, for: .normal)
        doneButton.setTitleColor(colorStyle.itemDisableColor, for: .disabled)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        doneButton.isEnabled = false
        doneButton.layer.cornerRadius = 4
        doneButton.layer.masksToBounds = true
        doneButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        let centerOffset = safeAreaInsetsBottom == 0 ? 0 : -(safeAreaInsetsBottom/2-5)
        NSLayoutConstraint.activate([
            doneButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15),
            doneButton.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: centerOffset)
        ])
    }

    func addEditButton() {
        addSubview(editButton)
        editButton.isHidden = true
        editButton.setTitle(L10n.cropPhoto, for: .normal)
        editButton.addTarget(self, action: #selector(buttonClicked(_:)), for: .touchUpInside)
        editButton.setTitleColor(.white, for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)

        editButton.translatesAutoresizingMaskIntoConstraints = false
        let centerOffset = safeAreaInsetsBottom == 0 ? 0 : -(safeAreaInsetsBottom/2-5)
        NSLayoutConstraint.activate([
            editButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            editButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: centerOffset)
        ])
    }

    func showPlayButton(_ show: Bool) {
        playButton.isHidden = !show
        if show {
            updatePlayButtonImage(isPlaying: isPlaying)
        }
    }

    func disableDoneButton(_ disable: Bool) {
        doneButton.isEnabled = !disable
    }
    
    func updatePlayButtonImage(isPlaying: Bool) {
        let image = isPlaying ? Asset.icons8Pause.image : Asset.icons8Play.image
        playButton.setImage(image, for: .normal)
    }

    @objc func buttonClicked(_ sender: UIButton) {
        if sender == playButton {
            delegate?.browserBottomToolViewPlayButtonClicked()
        } else if sender == doneButton {
            delegate?.browserBottomToolViewDoneButtonClicked()
        } else if sender == editButton {
            delegate?.browserBottomToolViewEditButtonClicked()
        } else {

        }
    }

}
