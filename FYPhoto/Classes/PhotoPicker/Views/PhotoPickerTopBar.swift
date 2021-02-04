//
//  PhotoPickerTopBar.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/2/4.
//

import UIKit

class PhotoPickerTopBar: UIView {
    let cancelButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        cancelButton.setTitle(L10n.cancel, for: .normal)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
