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
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 249/255.0, green: 249/255.0, blue: 249/255.0, alpha: 1)
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
            let image = newValue ? "icons8-pause".photoImage : "icons8-play".photoImage
            playButton.setImage(image, for: .normal)
        }
    }
    
    fileprivate func addPlayButton() {
        addSubview(playButton)
        
        playButton.setImage("icons8-play".photoImage, for: .normal)
        playButton.addTarget(self, action: #selector(buttonClicked(_:)), for: .touchUpInside)
        
        playButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 30),
            playButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func addDoneButton() {
        addSubview(doneButton)
        
        doneButton.setTitle("Done".photoTablelocalized, for: .normal)
        doneButton.addTarget(self, action: #selector(buttonClicked(_:)), for: .touchUpInside)
        doneButton.setTitleColor(UIColor(red: 24/255.0, green: 135/255.0, blue: 251/255.0, alpha: 1), for: .normal)
        doneButton.setTitleColor(UIColor(red: 167/255.0, green: 171/255.0, blue: 177/255.0, alpha: 1), for: .disabled)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        doneButton.isEnabled = false
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15),
            doneButton.centerYAnchor.constraint(equalTo: self.centerYAnchor)
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
