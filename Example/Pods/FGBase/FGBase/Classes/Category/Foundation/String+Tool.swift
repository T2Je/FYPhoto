//
//  String+Tool.swift
//  FGBase
//
//  Created by wangkun on 2018/2/3.
//

import Foundation

extension NSString {
    @objc public func phoneNumberFormat() -> NSString {
        let string = self as String
        let phone = string.phoneNumberFormat()
        return phone as NSString
    }
    
    @objc public func isContainChineseString() -> Bool {
        return (self as String).isContainsChineseCharacters
    }
}

extension String {
    public func phoneNumberFormat() -> String {
        let set = CharacterSet.decimalDigits.inverted
        let phoneString = components(separatedBy: set).joined(separator: "")
        let length = 11
        if phoneString.count > length {
            let index = phoneString.index(phoneString.startIndex, offsetBy: length)
            return String(phoneString[..<index])
        } else {
            return phoneString
        }
    }
    
    public var isContainsChineseCharacters: Bool {
        return self.range(of: "\\p{Han}", options: .regularExpression) != nil
    }
    
    public func stringByTrimingWhitespace() -> String {
        return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

extension String {
    public var containsEmoji: Bool {
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1F64F, // Emoticons
            0x1F300...0x1F5FF, // Misc Symbols and Pictographs
            0x1F680...0x1F6FF, // Transport and Map
            0x1F1E6...0x1F1FF, // Regional country flags
            0x2600...0x26FF, // Misc symbols
            0x2700...0x27BF, // Dingbats
            0xE0020...0xE007F, // Tags
            0xFE00...0xFE0F, // Variation Selectors
            0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
            0x1F018...0x1F270, // Various asian characters
            0x238C...0x2454, // Misc items
            0x20D0...0x20FF: // Combining Diacritical Marks for Symbols
                return true

            default: return false
            }
        }
        return false
    }

}

