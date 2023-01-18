//
//  FileManager+TempDirectory.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/20.
//

import Foundation

extension FileManager {
    enum CreateTempDirectoryError: Error, LocalizedError {
        case fileExsisted

        var errorDescription: String? {
            switch self {
            case .fileExsisted:
                return "File exsisted"
            }
        }
    }
    
    /// Get temp directory. If it exsists, return it, else create it.
    /// - Parameter pathComponent: path to append to temp directory.
    /// - Returns: temp directory location.
    /// - Warning: Every time you call this function will return a different directory.
    static func tempDirectory(with pathComponent: String = ProcessInfo.processInfo.globallyUniqueString) -> URL {
        var tempURL: URL

        // Only the volume(卷) of cache url is used.
        let cacheURL = FileManager.default.temporaryDirectory
        if let url = try? FileManager.default.url(for: .itemReplacementDirectory,
                                                     in: .userDomainMask,
                                                     appropriateFor: cacheURL,
                                                     create: true) {
            tempURL = url
        } else {
            tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        }

        tempURL.appendPathComponent(pathComponent)

        if !FileManager.default.fileExists(atPath: tempURL.path) {
            do {
                try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(pathComponent, isDirectory: true)
            }
        }
        #if DEBUG
        print("temp directory path \(tempURL)")
        #endif
        return tempURL
    }
}

extension FileManager {
    static let trimmedVideoDirName = "TrimmedVideo"
    static let cachedWebVideoDirName = "FYPhotoVideoCache"
    static let avCompositionDirName = "AVCompositionDir"
}
