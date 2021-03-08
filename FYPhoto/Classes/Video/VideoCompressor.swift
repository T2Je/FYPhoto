//
//  VideoCompressor.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/22.
//

import Foundation
import AVKit

public class VideoCompressor {
    public enum QualityLevel: String {
        case AVAssetExportPresetLowQuality
        case AVAssetExportPresetMediumQuality
        case AVAssetExportPresetHighestQuality
        case AVAssetExportPreset640x480
        case AVAssetExportPreset960x540
        case AVAssetExportPreset1280x720
        case AVAssetExportPreset1920x1080
        case AVAssetExportPreset3840x2160
    }
    
    public static func compressVideo(_ url: URL,
                                     quality: QualityLevel,
                                     completion: @escaping (Result<URL, Error>) -> Void) {
        let urlAsset = AVURLAsset(url: url, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset,
                                                       presetName: quality.rawValue) else {
            completion(.failure(AVAssetExportSessionError.exportSessionCreationFailed))
            return
        }
        do {
            var tempDirectory = try FileManager.tempDirectory(with: "compressedVideo")
            let videoName = UUID().uuidString + ".mp4"
            tempDirectory.appendPathComponent("\(videoName)")
            #if DEBUG
            print("compression temp file path: \(tempDirectory)")
            print("original video size: \(url.sizePerMB()) MB")
            #endif
            exportSession.outputURL = tempDirectory
            exportSession.outputFileType = .mp4
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .waiting:
                    #if DEBUG
                    print("waiting to be compressed")
                    #endif
                case .exporting:
                    #if DEBUG
                    print("exporting compressed video")
                    #endif
                case .cancelled, .failed:
                    DispatchQueue.main.async {
                        completion(.failure(exportSession.error!))
                    }
                case .completed:
                    #if DEBUG
                    print("compressed video size: \(tempDirectory.sizePerMB()) MB")
                    #endif
                    DispatchQueue.main.async {
                        completion(.success(tempDirectory))
                    }
                case .unknown:
                    DispatchQueue.main.async {
                        completion(.failure(AVAssetExportSessionError.exportStatuUnknown))
                    }
                @unknown default:
                    DispatchQueue.main.async {
                        completion(.failure(AVAssetExportSessionError.exportStatuUnknown))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
        
    }
    
    
    ///  Your app should remove files from this directory when they are no longer needed;
    ///  however, the system may purge this directory when your app is not running.
    /// - Parameter path: path to remove
    public static func removeCompressedTempFile(at path: URL) {
        if FileManager.default.fileExists(atPath: path.path) {
            try? FileManager.default.removeItem(at: path)
        }
    }
}
