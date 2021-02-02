//
//  PhotoPickerBottomToolView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/18.
//

import UIKit

protocol PhotoPickerBottomToolViewDelegate: class {
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
            previewButton.isEnabled = newValue > 0
            doneButton.isEnabled = newValue > 0
        }
    }
    
    private let selectionLimit: Int
    
    init(selectionLimit: Int, frame: CGRect = .zero) {
        self.selectionLimit = selectionLimit        
        super.init(frame: frame)
        backgroundColor = UIColor(red: 249/255.0, green: 249/255.0, blue: 249/255.0, alpha: 1)
        
        addSubview(previewButton)
        addSubview(countLabel)
        addSubview(doneButton)
        
        previewButton.setTitle(L10n.preview, for: .normal)
        previewButton.setTitleColor(UIColor(red: 24/255.0, green: 135/255.0, blue: 251/255.0, alpha: 1), for: .normal)
        previewButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        previewButton.addTarget(self, action: #selector(buttonClicked(_:)), for: .touchUpInside)
        previewButton.isEnabled = false
        previewButton.setTitleColor(UIColor(red: 167/255.0, green: 171/255.0, blue: 177/255.0, alpha: 1), for: .disabled)
        
        doneButton.setTitle(L10n.done, for: .normal)
        doneButton.setTitleColor(UIColor(red: 24/255.0, green: 135/255.0, blue: 251/255.0, alpha: 1), for: .normal)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        doneButton.addTarget(self, action: #selector(buttonClicked(_:)), for: .touchUpInside)
        doneButton.isEnabled = false
        doneButton.setTitleColor(UIColor(red: 167/255.0, green: 171/255.0, blue: 177/255.0, alpha: 1), for: .disabled)
        
        countLabel.textColor = UIColor(red: 123/255.0, green: 130/255.0, blue: 141/255.0, alpha: 1)
        countLabel.font = UIFont.systemFont(ofSize: 13, weight: .thin)
        countLabel.textAlignment = .right
        countLabel.text = "0/\(selectionLimit)"
        
        makeConstraints()
    }
    
    func makeConstraints() {
        previewButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
            previewButton.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15),
            doneButton.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            countLabel.trailingAnchor.constraint(equalTo: self.doneButton.leadingAnchor, constant: -10),
            countLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
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
 
