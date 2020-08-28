//
//  Bundle+FGBase.swift
//  FGBase
//
//  Created by xiaoyang on 2019/1/18.
//

import Foundation

class FGBaseResource { }

extension Bundle {
    class func baseBundle() -> Bundle {
        if let url = resourceBundle() {
            return Bundle.init(url: url) ?? Bundle.main
        } else {
            return Bundle.main
        }
    }

    private class func resourceBundle() -> URL? {
        let bundle = Bundle(for: FGBaseResource.self)
        return bundle.url(forResource: "FGBase", withExtension: "bundle")
    }
}

extension String {
    public var baseTablelocalized: String {
        let string = NSLocalizedString(self, tableName: "FGBaseLocalizable", bundle: Bundle.baseBundle(), value: "", comment: "")
        return string
    }

    public var baseImage: UIImage? {
        return UIImage(named: self, in: Bundle.baseBundle(), compatibleWith: nil)
    }
}
