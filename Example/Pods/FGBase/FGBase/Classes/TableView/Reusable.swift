//
//  Reusable.swift
//  FGProcess
//
//  Created by xiaoyang on 2018/10/15.
//

import Foundation

public protocol Reusable {
    static var reuseIdentifier: String { get}
}

extension Reusable {
    public static var reuseIdentifier: String {
        return String(describing: self)
    }
}
