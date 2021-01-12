//
//  NamSpaceTest.swift
//  FYPhoto_Example
//
//  Created by xiaoyang on 2021/1/8.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import FYPhoto

extension UICollectionView: FYNameSpaceProtocol {}

extension TypeWrapperProtocol where WrappedType == UICollectionView {
    func registerCell<T: UITableViewCell>(_ cell: T.Type) {
        
    }
}
