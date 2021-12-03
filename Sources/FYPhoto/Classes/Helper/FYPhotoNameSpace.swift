//
//  FYPhotoNameSpace.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/7.
//

import Foundation

// Type wrapper
public protocol TypeWrapperProtocol {
    associatedtype WrappedType
    var wrappedValue: WrappedType { get }
    init(value: WrappedType)
}

public struct TypeWrapper<T>: TypeWrapperProtocol {
    public let wrappedValue: T

    public init(value: T) {
        self.wrappedValue = value
    }
}

// namespace
public protocol FYNameSpaceProtocol {
    associatedtype WrappedType
    var fyphoto: WrappedType { get }
    /// FYPhoto namespace for present or push animation
    static var fyphoto: WrappedType.Type { get }
}

public extension FYNameSpaceProtocol {
    var fyphoto: TypeWrapper<Self> {
        TypeWrapper(value: self)
    }

    static var fyphoto: TypeWrapper<Self>.Type {
        return TypeWrapper.self
    }
}
