//
//  CameraViewController+InfoKey.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/3/8.
//

import Foundation

extension CameraViewController {
    public struct InfoKey: Hashable, Equatable, RawRepresentable {
        public let rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let mediaType: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "mediaType")

        public static let originalImage: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "originalImage") // a UIImage

        public static let editedImage: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "editedImage")// a UIImage

        public static let cropRect: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "cropRect")// an NSValue (CGRect)

        public static let mediaURL: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "mediaURL") // an URL

        public static let mediaMetadata: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "mediaMetadata") // an NSDictionary containing metadata from a captured photo
        public static let livePhoto: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "livePhoto") // a PHLivePhoto

        public static let imageURL: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "imageURL") // a URL

        public static let watermarkImage: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "watermarkImage") // a UIImage
        public static let watermarkVideoURL: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "watermarkVideoURL") // a URL
    }

}
