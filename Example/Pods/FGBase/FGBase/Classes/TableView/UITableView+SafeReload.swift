//
//  UITableView+SafeReload.swift
//  FGBase
//
//  Created by xiaoyang on 2019/1/4.
//

import Foundation
import UIKit

extension UITableView {
    public func reloadRowsIfExsist(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        indexPaths.forEach { (indexPath) in
            reloadRowIfExsist(at: indexPath, with: animation)
        }
    }

    public func reloadRowIfExsist(at indexPath: IndexPath, with animation: UITableView.RowAnimation) {
        if (cellForRow(at: indexPath) != nil) {
            reloadRows(at: [indexPath], with: animation)
        } else {
            reloadData()
        }
    }
}
