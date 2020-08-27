//
//  ResourceTool.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/15.
//

import Foundation

class FYPickerResource { }

extension Bundle {
    @objc public class func ppBundle() -> Bundle {
        if let url = bundleURL() {
            return Bundle.init(url: url) ?? Bundle.main
        } else {
            return Bundle.main
        }
    }

    private class func bundleURL() -> URL? {
        let bundle = Bundle(for: FYPickerResource.self)
        return bundle.url(forResource: "FYPhotoPicker", withExtension: "bundle")
    }
}

extension String {
    var ppTablelocalized: String {
        let string = NSLocalizedString(self, tableName: "FYPhotoPicker", bundle: Bundle.ppBundle(), value: "", comment: "")
        return string
    }

    var ppImage: UIImage? {
        let image = UIImage(named: self, in: Bundle.ppBundle(), compatibleWith: nil)
        return image
    }
}

