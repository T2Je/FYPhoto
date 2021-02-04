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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        cancelButton.setTitle(L10n.cancel, for: .normal)
        cancelButton.setTitleColor(UIColor.systemBlue, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        cancelButton.addTarget(self, action: #selector(cancelButtonClicked(_:)), for: .touchUpInside)
        
        addSubview(cancelButton)
        addSubview(titleView)
        
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTitle(_ title: String) {
        titleView.title = title
    }
    
    fileprivate func makeConstraints() {
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            cancelButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15)
        ])
        
        titleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            titleView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            titleView.widthAnchor.constraint(equalToConstant: 90),
            titleView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc
    fileprivate func cancelButtonClicked(_ sender: UIButton) {
        dismiss?()
    }
    
}
