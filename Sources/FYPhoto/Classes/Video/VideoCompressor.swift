//
//  VideoCompressor.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/22.
//

import Foundation
import AVKit

/// Compress video class
/// Video
public final class VideoCompressor {
    public enum VideoCompressorError: Error, LocalizedError {
        case noVideo
        case compressedFailed(_ error: Error)
        
        public var errorDescription: String? {
            switch self {
            case .noVideo:
                return L10n.noVideo
            case .compressedFailed(let error):
                return error.localizedDescription
            }
        }
    }
    
    /// Compressed video target quality
    public enum VideoQuality {
        /// Reduce size proportionally with video size, reduce FPS, reduce bit rate.
        /// The video will be compressed using H.264
        case lowQuality
        
        /// Reduce size proportionally with video size, reduce bit rate.
        /// The video will be compressed using H.264
        case mediumQuality // sssss
        
        /// Reduce size proportionally with video size, reduce FPS, reduce bit rate.
        /// The video will be compressed using H.264
        case custom(fps: Float = 24, bitRateTimes: Int = 6)
        
        // fps and bit rate divided by times
        var value: (Float, Int) {
            switch self {
            case .lowQuality:
                return (24, 10)
            case .mediumQuality:
                return (30, 6)
            case .custom(fps: let fps, bitRateTimes: let times):
                return (fps, times)
            }
        }
    }
    
    let group = DispatchGroup.init()
    let videoCompressQueue = DispatchQueue.init(label: "video_compress_queue")
    lazy var audioCompressQueue = DispatchQueue.init(label: "audio_compress_queue")
    var reader: AVAssetReader?
    var writer: AVAssetWriter?
        
    static public let shared: VideoCompressor = VideoCompressor()
    
    /// Compress video method.
    ///
    /// - Parameters:
    ///   - url: video file path
    ///   - quality: target quality
    ///   - completion: completion callBack with a compressed video or a failed error.
    ///   - Caution: compress video method uses many AVFoundation APIs, it's better to test it via real device otherwise odd errors will occurr.
    public func compressVideo(_ url: URL, quality: VideoQuality, completion: @escaping (Result<URL, Error>) -> Void) {
        do {
            let asset = AVAsset.init(url: url)
            let reader = try AVAssetReader(asset: asset)
            var outputURL = try FileManager.tempDirectory(with: "CompressedVideo")
            let videoName = UUID().uuidString + ".mp4"
            outputURL.appendPathComponent("\(videoName)")
            let writer =  try AVAssetWriter.init(url: outputURL, fileType: .mp4)
            self.reader = reader
            self.writer = writer
            // video
            guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                completion(.failure(VideoCompressorError.noVideo))
                return
            }
            let videoOutput = AVAssetReaderTrackOutput.init(track: videoTrack, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String:  kCVPixelFormatType_32BGRA])
            
            let outputSettings = videoCompressSettings(videoTrack, quality: quality)
//            print("output setting: \(outputSettings)")
            
            let videoInput = AVAssetWriterInput.init(mediaType: .video, outputSettings: outputSettings)
            
            if reader.canAdd(videoOutput) {
                reader.add(videoOutput)
                videoOutput.alwaysCopiesSampleData = false
            }
            if writer.canAdd(videoInput) {
                writer.add(videoInput)
            }
            // audio
            var audioInput: AVAssetWriterInput?
            var audioOutput: AVAssetReaderTrackOutput?
            if let audioTrack = asset.tracks(withMediaType: .audio).first {
                let adOutput = AVAssetReaderTrackOutput.init(track: audioTrack, outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM])
                audioOutput = adOutput
                
                let audioSettings = audioCompressSettings(audioTrack)
                let adInput = AVAssetWriterInput.init(mediaType: .audio, outputSettings: audioSettings)
                audioInput = adInput
                if reader.canAdd(adOutput) {
                    reader.add(adOutput)
                }
                if writer.canAdd(adInput) {
                    writer.add(adInput)
                }
            }
            
            reader.startReading()
            writer.startWriting()
            writer.startSession(atSourceTime: CMTime.zero)
            
            // output video
            group.enter()
            let reduceFPS = quality.value.0 < videoTrack.nominalFrameRate
            if reduceFPS {
                outputMediaDataByReducingFPS(originFPS: videoTrack.nominalFrameRate,
                                             targetFPS: quality.value.0,
                                             videoInput: videoInput,
                                             videoOutput: videoOutput) {
                    self.group.leave()
                }
            } else {
                outputMediaData(videoInput, videoOutput: videoOutput) {
//                    print("finish video appending")
                    self.group.leave()
                }
            }
            
            // output audio
            if let realAudioInput = audioInput, let realAudioOutput = audioOutput {
                group.enter()
                realAudioInput.requestMediaDataWhenReady(on: audioCompressQueue) {
                    while realAudioInput.isReadyForMoreMediaData {
                        if let buffer = realAudioOutput.copyNextSampleBuffer() {
                            realAudioInput.append(buffer)
                        } else {
//                            print("finish audio appending")
                            realAudioInput.markAsFinished()
                            self.group.leave()
                            break
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                switch writer.status {
                case .writing, .completed:
                    writer.finishWriting {
                        DispatchQueue.main.sync {
                            completion(.success(outputURL))
                        }
                    }
                default:
                    completion(.failure(writer.error!))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func videoCompressSettings(_ videoTrack: AVAssetTrack, quality: VideoQuality) -> [String : Any] {
        let targetBitRateTimes = quality.value.1
        // bit rate
        let originBitRate = videoTrack.estimatedDataRate
        let tempBitRate = originBitRate / Float(targetBitRateTimes)
        let compressedBitRate = tempBitRate > 200_000 ? tempBitRate : 200_000
        print("original bit rate: \(originBitRate) b/s")
        print("target bit rate: \(compressedBitRate) b/s")
        // aspect ratio
        var compressedWidth: CGFloat = videoTrack.naturalSize.width
        var compressedHeight: CGFloat = videoTrack.naturalSize.height
        if compressedWidth > 640 {
            let aspectRatio: CGFloat = videoTrack.naturalSize.width / videoTrack.naturalSize.height
            compressedWidth = 640
            compressedHeight = compressedWidth / aspectRatio
        }
        
        print("original size: \(videoTrack.naturalSize)")
        print("target size: (\(compressedWidth), \(compressedHeight))")
        
        let outputSeting: [String : Any] = [AVVideoCodecKey: AVVideoCodecType.h264,
                                            AVVideoWidthKey: compressedWidth,
                                            AVVideoHeightKey: compressedHeight,
                                            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
                                            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: compressedBitRate,
                                                                              AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                                                                              AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC
                                            ]
        ]
        return outputSeting
    }
    
    func audioCompressSettings(_ audioTrack: AVAssetTrack) -> [String: Any] {
        var formatDescription: CMFormatDescription?
        if let audioFormatDescs = audioTrack.formatDescriptions as? [CMFormatDescription] {
            formatDescription = audioFormatDescs.first
        }
        guard let formatDesc = formatDescription else {
            var channelLayout =  AudioChannelLayout.init()
            channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo
            channelLayout.mChannelBitmap = AudioChannelBitmap(rawValue: 0)
            channelLayout.mNumberChannelDescriptions = 0
                    
            let compressSetting: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 96_000,
                AVSampleRateKey: 44100,
                AVChannelLayoutKey: Data(bytes: &channelLayout, count: MemoryLayout<AudioChannelLayout>.size),
            ]
            return compressSetting
        }
//        print(formatDescription)
        
        var sampleRate: Float64 = 44100
        var channels: UInt32 = 2
        var formatID: AudioFormatID = kAudioFormatMPEG4AAC
        
        if let streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc) {
            if sampleRate > streamBasicDescription.pointee.mSampleRate {
                sampleRate = streamBasicDescription.pointee.mSampleRate
            }
            channels = streamBasicDescription.pointee.mChannelsPerFrame
            formatID = streamBasicDescription.pointee.mFormatID
        }
        
        var layoutSize: Int = 0
        var layoutData: Data = Data()
        if let currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(formatDescription!, sizeOut: &layoutSize) {
            // handle a special case 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
            // use AAC_HE instead of AAC
            if currentChannelLayout.pointee.mChannelLayoutTag == kAudioChannelLayoutTag_MPEG_5_1_D && formatID != kAudioFormatMPEG4AAC_HE {
                formatID = kAudioFormatMPEG4AAC_HE
            }
            layoutData = layoutSize > 0 ? Data(bytes: currentChannelLayout, count: layoutSize) : Data()
        }
        
        let compressSetting: [String: Any] = [
            AVFormatIDKey: formatID,
            AVNumberOfChannelsKey: channels,
            AVEncoderBitRateKey: 96_000,
            AVSampleRateKey: sampleRate,
            AVChannelLayoutKey: layoutData,
        ]
        return compressSetting
    }
    
    private func outputMediaDataByReducingFPS(originFPS: Float,
                                              targetFPS: Float,
                                              videoInput: AVAssetWriterInput,
                                              videoOutput: AVAssetReaderTrackOutput,
                                              completion: @escaping(() -> Void)) {
//        let ratio: Float64 = Float64(originFPS / targetFPS)
        let droppedFrameIndex = Int(ceil(originFPS / (originFPS - targetFPS)))
        
        var counter = 0
        videoInput.requestMediaDataWhenReady(on: videoCompressQueue) {
            while videoInput.isReadyForMoreMediaData {
                if let buffer = videoOutput.copyNextSampleBuffer() {
                    // append first frame
                    if counter % droppedFrameIndex != 0 || counter == 0 { // drop some frames
                        let timingInfo = UnsafeMutablePointer<CMSampleTimingInfo>.allocate(capacity: 1)
                        let newSample = UnsafeMutablePointer<CMSampleBuffer?>.allocate(capacity: 1)

                        // Should check call succeeded
                        CMSampleBufferGetSampleTimingInfo(buffer, at: 0, timingInfoOut: timingInfo)
                        
                        // timingInfo.pointee.duration is 0
//                        timingInfo.pointee.duration = CMTimeMultiplyByFloat64(timingInfo.pointee.duration, multiplier: ratio)

                        // Again, should check call succeeded
                        CMSampleBufferCreateCopyWithNewTiming(allocator: nil, sampleBuffer: buffer, sampleTimingEntryCount: 1, sampleTimingArray: timingInfo, sampleBufferOut: newSample)
                        videoInput.append(newSample.pointee!)
                        // deinit
                        newSample.deinitialize(count: 1)
                        newSample.deallocate()
                        timingInfo.deinitialize(count: 1)
                        timingInfo.deallocate()
                    }
                    counter += 1
                } else {
//                    print("counter: \(counter)")
                    videoInput.markAsFinished()
                    completion()
                    break
                }
            }
        }
    }

    func outputMediaData(_ videoInput: AVAssetWriterInput,
                         videoOutput: AVAssetReaderTrackOutput,
                         completion: @escaping(() -> Void)) {
        videoInput.requestMediaDataWhenReady(on: videoCompressQueue) {
            while videoInput.isReadyForMoreMediaData {
                if let buffer = videoOutput.copyNextSampleBuffer() {
                    videoInput.append(buffer)
                } else {
                    videoInput.markAsFinished()
                    completion()
                    break
                }
            }
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
