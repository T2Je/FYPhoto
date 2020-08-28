//
//  UITableView+Register.swift
//  FGProcess
//
//  Created by xiaoyang on 2018/10/15.
//

import Foundation

extension UITableView {
    public func register<T: UITableViewCell>(_: T.Type) {
        self.register(T.self, forCellReuseIdentifier: T.reuseIdentifier)
    }

    public func register<T: UITableViewHeaderFooterView>(_: T.Type) {
        register(T.self, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
    }
}
