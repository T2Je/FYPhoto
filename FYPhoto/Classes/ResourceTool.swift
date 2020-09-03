//
//  ResourceTool.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/15.
//

import Foundation

class FYPhotoResource { }

extension Bundle {
    @objc public class func photoBundle() -> Bundle {
        if let url = bundleURL() {
            return Bundle.init(url: url) ?? Bundle.main
        } else {
            return Bundle.main
        }
    }

    private class func bundleURL() -> URL? {
        let bundle = Bundle(for: FYPhotoResource.self)
        return bundle.url(forResource: "FYPhoto", withExtension: "bundle")
    }
}

extension String {
    var photoTablelocalized: String {
        let string = NSLocalizedString(self, tableName: "FYPhoto", bundle: Bundle.photoBundle(), value: "", comment: "")
        return string
    }

    var photoImage: UIImage? {
        let image = UIImage(named: self, in: Bundle.photoBundle(), compatibleWith: nil)
        return image
    }
}

