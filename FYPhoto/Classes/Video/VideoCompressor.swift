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
    
    public enum CompressionError: Error {
        case exportSessionCreationFailed
        case exportStatuUnknown
    }
    
    public static func compressVideo(url: URL,
                              quality: QualityLevel,
                              completion: @escaping (Result<URL, Error>) -> Void) {
        let urlAsset = AVURLAsset(url: url, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset,
                                                       presetName: quality.rawValue) else {
            completion(.failure(CompressionError.exportSessionCreationFailed))
            return
        }
        do {
            var tempDirectory = try VideoCompressor.tempDirectory()
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
                        completion(.failure(CompressionError.exportStatuUnknown))
                    }
                @unknown default:
                    DispatchQueue.main.async {
                        completion(.failure(CompressionError.exportStatuUnknown))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
        
    }
    
    public static func removeCompressedTempFile(at path: URL) {
        if FileManager.default.fileExists(atPath: path.path) {
            try? FileManager.default.removeItem(at: path)
        }
    }
    
    public static func tempDirectory() throws -> URL {
        let cacheURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        do {
            // Only the volume(卷) of cache url is used.
            let temp = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: cacheURL, create: true)
            let subDirectory = "compressedVideo"
            let compressedDirectory = temp.appendingPathComponent(subDirectory)
            
            if !FileManager.default.fileExists(atPath: compressedDirectory.absoluteString) {
                do {
                    try FileManager.default.createDirectory(at: compressedDirectory, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    throw error
                }
            }
            #if DEBUG
            print("temp directory path👉\(temp)👈")
            #endif
            return temp
        } catch {
            throw error
        }
    }
}
