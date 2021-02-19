//
//  URL+FileSize.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/22.
//

import Foundation

extension URL {
    func sizePerMB() -> Double {
        guard isFileURL else { return 0 }
        do {
            let attribute = try FileManager.default.attributesOfItem(atPath: path)
            if let size = attribute[FileAttributeKey.size] as? NSNumber {
                return size.doubleValue / (1024 * 1024)
            }
        } catch {
            print("Error: \(error)")
        }
        return 0.0
    }
}
