//
//  FYPhoto.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/22.
//

import Foundation
import Photos
import UIKit

public enum PhotoResourceType {
    case pureImage
    case asset
    case url
    case data
}

// MARK: Factory function
public protocol ImagePhotoFactoryFunction {
    static func photoWithUIImage(_ image: UIImage) -> PhotoProtocol
    static func photoWithCGImage(_ cgImage: CGImage) -> PhotoProtocol
    static func photoWithImageNamed(_ named: String) -> PhotoProtocol
    static func photoWithContentsOfFile(_ path: String) -> PhotoProtocol
}

public protocol MetaDataPhotoFactoryFunction {
    static func photoWithData(_ data: Data) -> PhotoProtocol
}

public protocol AssetPhotoFactoryFunction {
    static func photoWithPHAsset(_ asset: PHAsset) -> PhotoProtocol
}

public protocol URLPhotoFactoryFunction {
    static func photoWithURL(_ url: URL) -> PhotoProtocol
}

/// Photo factory
public class Photo: AssetPhotoFactoryFunction, ImagePhotoFactoryFunction, URLPhotoFactoryFunction, MetaDataPhotoFactoryFunction {

    public static func photoWithPHAsset(_ asset: PHAsset) -> PhotoProtocol {
        return PhotoAsset(asset: asset)
    }

    public static func photoWithUIImage(_ image: UIImage) -> PhotoProtocol {
        return PhotoImage(image: image)
    }

    public static func photoWithCGImage(_ cgImage: CGImage) -> PhotoProtocol {
        return PhotoImage(cgImage: cgImage)
    }

    public static func photoWithImageNamed(_ named: String) -> PhotoProtocol {
        PhotoImage(imageNamed: named)
    }

    public static func photoWithContentsOfFile(_ path: String) -> PhotoProtocol {
        PhotoImage(contentsOfFile: path)
    }

    public static func photoWithURL(_ url: URL) -> PhotoProtocol {
        PhotoURL(url: url)
    }

    public static func photoWithData(_ data: Data) -> PhotoProtocol {
        PhotoMetaData(data: data)
    }
}
