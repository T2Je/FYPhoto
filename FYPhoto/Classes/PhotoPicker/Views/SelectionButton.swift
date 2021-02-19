//
//  SelectionButton.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/2/19.
//

import UIKit

class SelectionButton: UIButton {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {        
        if CGRect(x: -20, y: -10, width: self.frame.width + 32, height: self.frame.height + 32).contains(point) {
            return self
        }
        return super.hitTest(point, with: event)
    }
}
