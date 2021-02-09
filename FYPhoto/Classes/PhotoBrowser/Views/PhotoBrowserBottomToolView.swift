//
//  PhotoBrowserBottomToolView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/19.
//

import UIKit

protocol PhotoBrowserBottomToolViewDelegate: class {
    func browserBottomToolViewPlayButtonClicked()
    func browserBottomToolViewDoneButtonClicked()
}

extension PhotoBrowserBottomToolViewDelegate {
    func browserBottomToolViewPlayButtonClicked() {}
    func browserBottomToolViewDoneButtonClicked() {}
}

class PhotoBrowserBottomToolView: UIView {
    weak var delegate: PhotoBrowserBottomToolViewDelegate?
    
    let playButton = UIButton()
    let doneButton = UIButton()
    private let safeAreaInsetsBottom: CGFloat
    private let colorStyle: FYUIConfiguration.BarColorSytle

    init(colorStyle: FYUIConfiguration.BarColorSytle, safeAreaInsetsBottom: CGFloat = 0) {
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
            let image = newValue ? Asset.icons8Pause.image : Asset.icons8Play.image
            playButton.setImage(image, for: .normal)
        }
    }
    
    fileprivate func addPlayButton() {
        addSubview(playButton)
        
        playButton.setImage(Asset.icons8Play.image, for: .normal)
        playButton.addTarget(self, action: #selector(buttonClicked(_:)), for: .touchUpInside)
        playButton.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -(safeAreaInsetsBottom/2-5)),
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
        NSLayoutConstraint.activate([
            doneButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15),
            doneButton.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -(safeAreaInsetsBottom/2-5)),
        ])
    }
    
    func showPlayButton(_ show: Bool) {
        playButton.isHidden = !show
    }
    
    func disableDoneButton(_ disable: Bool) {
        doneButton.isEnabled = !disable
    }
    
    @objc func buttonClicked(_ sender: UIButton) {
        if sender == playButton {
            delegate?.browserBottomToolViewPlayButtonClicked()
        } else if sender == doneButton {
            delegate?.browserBottomToolViewDoneButtonClicked()
        } else {
            
        }
    }
}
