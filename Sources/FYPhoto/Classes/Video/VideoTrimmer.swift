//
//  VideoTrimmer.swift
//  
//
//  Created by xiaoyang on 2021/11/9.
//

import Foundation
import AVFoundation

class VideoTrimmer {
    static let shared = VideoTrimmer()

    let tempDirectory: URL

    private init() {
        tempDirectory = FileManager.tempDirectory(with: FileManager.trimmedVideoDirName)
    }

    func trimVideo(_ asset: AVAsset, from startTime: Double, to endTime: Double, completion: @escaping((Result<URL, Error>) -> Void)) {
        var tempFile = tempDirectory
        let videoName = UUID().uuidString + ".mp4"
        tempFile.appendPathComponent("\(videoName)")

        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(AVAssetExportSessionError.exportSessionCreationFailed))
            return
        }

        let start = CMTime(seconds: startTime, preferredTimescale: 600)
        let end = CMTime(seconds: endTime, preferredTimescale: 600)
        exporter.timeRange = CMTimeRange(start: start, end: end)
        exporter.outputURL = tempFile
        exporter.outputFileType = .mp4
        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                switch exporter.status {
                case .waiting:
                    #if DEBUG
                    print("waiting to be exported")
                    #endif
                case .exporting:
                    #if DEBUG
                    print("exporting video")
                    #endif
                case .cancelled, .failed:
                    completion(.failure(exporter.error!))
                case .completed:
                    #if DEBUG
                    print("finish exporting, video size: \(tempFile.sizePerMB()) MB")
                    #endif
                    completion(.success(tempFile))
                case .unknown:
                    completion(.failure(AVAssetExportSessionError.exportStatuUnknown))
                @unknown default:
                    completion(.failure(AVAssetExportSessionError.exportStatuUnknown))
                }
            }
        }
    }

    func clear() {
        try? FileManager.default.removeItem(at: tempDirectory)
    }
}
