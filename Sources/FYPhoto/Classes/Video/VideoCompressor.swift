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
    
    /// Compressed video target quality with fps and bitrate.
    /// Bitrate has a minimum value: 1000_000
    public enum VideoQuality {
        /// Reduce size proportionally with video size, reduce FPS, reduce bit rate.
        /// The video will be compressed using H.264
        case lowQuality
        
        /// Reduce size proportionally with video size, reduce bit rate.
        /// The video will be compressed using H.264
        case mediumQuality // sssss
        
        /// Reduce FPS to 24 if FPS large than 24 and
        /// reduce bit rate by dividing by the factor if bit rate large than .
        /// The video will be compressed using H.264
        case custom(fps: Float = 24, bitRateFactor: Int = 6)
        
        // fps and bit rate divided by factor.
        var value: (fps: Float, factor: Int) {
            switch self {
            case .lowQuality:
                return (24, 10)
            case .mediumQuality:
                return (30, 6)
            case .custom(fps: let fps, bitRateFactor: let factor):
                return (fps, factor)
            }
        }
    }
    
    // Compression Encode Parameters
    public struct CompressionConfig {
        let size: CGSize?
        // video
        let videoBitrate: Int
        let videomaxKeyFrameInterval: Int
        
        let audioSampleRate: Int
        let audioBitrate: Int
        
        let fileType: AVFileType
        
        public static let `default` = CompressionConfig(
            size: nil,
            videoBitrate: 5000_000,
            videomaxKeyFrameInterval: 2,
            audioSampleRate: 44100,
            audioBitrate: 320_000,
            fileType: .mp4
        )
    }
    
    let group = DispatchGroup()
    let videoCompressQueue = DispatchQueue.init(label: "video_compress_queue")
    lazy var audioCompressQueue = DispatchQueue.init(label: "audio_compress_queue")
    var reader: AVAssetReader?
    var writer: AVAssetWriter?
        
    static public let shared: VideoCompressor = VideoCompressor()
    
    static public var minimumVideoBitrate = 199100// 1000_000 // youtube suggests 1Mbps for 24 frame rate 360p video
    
    public func compressVideo(_ url: URL, quality: VideoQuality, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVAsset(url: url)
        // setup
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(.failure(VideoCompressorError.noVideo))
            return
        }
        // --- Video ---
        let targetBitRateFactor = quality.value.factor
        // video bit rate
        let originVideoBitrate = Int(videoTrack.estimatedDataRate)
        let tempVideoBitrate = originVideoBitrate / targetBitRateFactor
        let targetVideoBitRate = tempVideoBitrate > VideoCompressor.minimumVideoBitrate ? tempVideoBitrate : VideoCompressor.minimumVideoBitrate
        
        // aspect ratio
        var compressedWidth: CGFloat = videoTrack.naturalSize.width
        var compressedHeight: CGFloat = videoTrack.naturalSize.height
        if compressedWidth > 640 { // 360p
            let aspectRatio: CGFloat = videoTrack.naturalSize.width / videoTrack.naturalSize.height
            compressedWidth = 640
            compressedHeight = compressedWidth / aspectRatio
        }
        
        let videoSettings = createVideoSettingsWithBitrate(targetVideoBitRate,
                                                           maxKeyFrameInterval: 10,
                                                           size: CGSize(width: compressedWidth,
                                                                        height: compressedHeight))
        var audioTrack: AVAssetTrack?
        var audioSettings: [String: Any]?
        if let adTrack = asset.tracks(withMediaType: .audio).first {
            // --- Audio ---
            audioTrack = adTrack
            let audioBitrate: Int
            let audioSampleRate: Int
            
            audioBitrate = 96_000
            audioSampleRate = 44100
            audioSettings = createAudioSettingsWithAudioTrack(adTrack, bitrate: audioBitrate, sampleRate: audioSampleRate)
        }
#if DEBUG
        print("Original video size: \(url.sizePerMB())")
        print("########## Video ##########")
        print("Original:")
        print("bitrate: \(originVideoBitrate) b/s")
        
        print("size: \(videoTrack.naturalSize)")

        print("Target:")
        print("video bitrate: \(targetVideoBitRate) b/s")
        print("size: (\(compressedWidth), \(compressedHeight))")
#endif
        
        _compress(asset: asset, fileType: .mp4, videoTrack, videoSettings, audioTrack, audioSettings, completion: completion)
    }
    
    func compressVideo(_ url: URL, config: CompressionConfig = .default, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVAsset(url: url)
        // setup
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(.failure(VideoCompressorError.noVideo))
            return
        }
        
        let targetSize = config.size ?? videoTrack.naturalSize
        let videoSettings = createVideoSettingsWithBitrate(config.videoBitrate,
                                                           maxKeyFrameInterval: config.videomaxKeyFrameInterval,
                                                           size: targetSize)
        
        var audioTrack: AVAssetTrack?
        var audioSettings: [String: Any]?
        
        if let adTrack = asset.tracks(withMediaType: .audio).first {
            audioTrack = adTrack
            audioSettings = createAudioSettingsWithAudioTrack(adTrack, bitrate: config.audioBitrate, sampleRate: config.audioSampleRate)
        }
        
        _compress(asset: asset, fileType: config.fileType, videoTrack, videoSettings, audioTrack, audioSettings, completion: completion)
        
        
    }
    
    func _compress(asset: AVAsset, fileType: AVFileType, _ videoTrack: AVAssetTrack, _ videoSettings: [String: Any], _ audioTrack: AVAssetTrack?, _ audioSettings: [String: Any]?, completion: @escaping (Result<URL, Error>) -> Void) {
        // video
        let videoOutput = AVAssetReaderTrackOutput.init(track: videoTrack,
                                                        outputSettings: [kCVPixelBufferPixelFormatTypeKey as String:
                                                                                                kCVPixelFormatType_32BGRA])
        let videoInput = AVAssetWriterInput.init(mediaType: .video, outputSettings: videoSettings)
        videoInput.transform = videoTrack.preferredTransform // fix output video orientation
        do {
            var outputURL = try FileManager.tempDirectory(with: "CompressedVideo")
            let videoName = UUID().uuidString + ".\(fileType.fileExtension)"
            outputURL.appendPathComponent("\(videoName)")
            
            let reader = try AVAssetReader(asset: asset)
            let writer = try AVAssetWriter.init(url: outputURL, fileType: fileType)
            self.reader = reader
            self.writer = writer
            
            // video output
            if reader.canAdd(videoOutput) {
                reader.add(videoOutput)
                videoOutput.alwaysCopiesSampleData = false
            }
            if writer.canAdd(videoInput) {
                writer.add(videoInput)
            }
            
            // audio output
            var audioInput: AVAssetWriterInput?
            var audioOutput: AVAssetReaderTrackOutput?
            if let audioTrack = audioTrack, let audioSettings = audioSettings {
                audioOutput = AVAssetReaderTrackOutput.init(track: audioTrack, outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM])
                let adInput = AVAssetWriterInput.init(mediaType: .audio, outputSettings: audioSettings)
                audioInput = adInput
                if reader.canAdd(audioOutput!) {
                    reader.add(audioOutput!)
                }
                if writer.canAdd(adInput) {
                    writer.add(adInput)
                }
            }
            
            #if DEBUG
            let startTime = Date()
            #endif
            // start compressing
            reader.startReading()
            writer.startWriting()
            writer.startSession(atSourceTime: CMTime.zero)
            
            // output video
            group.enter()
//            let reduceFPS = quality.value.0 < videoTrack.nominalFrameRate
//            if reduceFPS {
//                outputVideoDataByReducingFPS(originFPS: videoTrack.nominalFrameRate,
//                                             targetFPS: quality.value.0,
//                                             videoInput: videoInput,
//                                             videoOutput: videoOutput) {
//                    self.group.leave()
//                }
//            } else {
                outputVideoData(videoInput, videoOutput: videoOutput) {
                    self.group.leave()
                }
//            }
            
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
            
            // completion
            group.notify(queue: .main) {
                switch writer.status {
                case .writing, .completed:
                    writer.finishWriting {
#if DEBUG
                        let endTime = Date()
                        let elapse = endTime.timeIntervalSince(startTime)
                        print("compression time: \(elapse)")
                        print("compressed video size: \(outputURL.sizePerMB())")
#endif
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
    
    /// Compress video method.
    ///
    /// - Parameters:
    ///   - url: video file path
    ///   - quality: target quality
    ///   - completion: completion callBack with a compressed video or a failed error.
    ///   - Caution: compress video method uses many AVFoundation APIs, it's better to test it via real device otherwise odd errors will occurr.
//    public func compressVideo(_ url: URL, quality: VideoQuality, config: CompressionConfig = .default, completion: @escaping (Result<URL, Error>) -> Void) {
//        do {
//            let asset = AVAsset.init(url: url)
//            let reader = try AVAssetReader(asset: asset)
//
//            let writer =  try AVAssetWriter.init(url: outputURL, fileType: config.fileType)
//            self.reader = reader
//            self.writer = writer
//
//            // setup
//            guard let videoTrack = asset.tracks(withMediaType: .video).first else {
//                completion(.failure(VideoCompressorError.noVideo))
//                return
//            }
//
//            // video
//            let videoOutput = AVAssetReaderTrackOutput.init(track: videoTrack,
//                                                            outputSettings: [kCVPixelBufferPixelFormatTypeKey as String:
//                                                                                                    kCVPixelFormatType_32BGRA])
//
//            let outputSettings = videoCompressSettings(videoTrack, quality: quality)
//
//            let videoInput = AVAssetWriterInput.init(mediaType: .video, outputSettings: outputSettings)
//            videoInput.transform = videoTrack.preferredTransform // fix output video transform
//
//            if reader.canAdd(videoOutput) {
//                reader.add(videoOutput)
//                videoOutput.alwaysCopiesSampleData = false
//            }
//            if writer.canAdd(videoInput) {
//                writer.add(videoInput)
//            }
//
//            // audio
//            var audioInput: AVAssetWriterInput?
//            var audioOutput: AVAssetReaderTrackOutput?
//            if let audioTrack = asset.tracks(withMediaType: .audio).first {
//                let adOutput = AVAssetReaderTrackOutput.init(track: audioTrack, outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM])
//                audioOutput = adOutput
//
//                let audioSettings = audioCompressSettings(audioTrack)
//                let adInput = AVAssetWriterInput.init(mediaType: .audio, outputSettings: audioSettings)
//                audioInput = adInput
//                if reader.canAdd(adOutput) {
//                    reader.add(adOutput)
//                }
//                if writer.canAdd(adInput) {
//                    writer.add(adInput)
//                }
//            }
//
//            #if DEBUG
//            let startTime = Date()
//            #endif
//            // start compressing
//            reader.startReading()
//            writer.startWriting()
//            writer.startSession(atSourceTime: CMTime.zero)
//
//            // output video
//            group.enter()
//            let reduceFPS = quality.value.0 < videoTrack.nominalFrameRate
//            if reduceFPS {
//                outputVideoDataByReducingFPS(originFPS: videoTrack.nominalFrameRate,
//                                             targetFPS: quality.value.0,
//                                             videoInput: videoInput,
//                                             videoOutput: videoOutput) {
//                    self.group.leave()
//                }
//            } else {
//                outputVideoData(videoInput, videoOutput: videoOutput) {
//                    self.group.leave()
//                }
//            }
//
//            // output audio
//            if let realAudioInput = audioInput, let realAudioOutput = audioOutput {
//                group.enter()
//                realAudioInput.requestMediaDataWhenReady(on: audioCompressQueue) {
//                    while realAudioInput.isReadyForMoreMediaData {
//                        if let buffer = realAudioOutput.copyNextSampleBuffer() {
//                            realAudioInput.append(buffer)
//                        } else {
////                            print("finish audio appending")
//                            realAudioInput.markAsFinished()
//                            self.group.leave()
//                            break
//                        }
//                    }
//                }
//            }
//
//            // completion
//            group.notify(queue: .main) {
//                switch writer.status {
//                case .writing, .completed:
//                    writer.finishWriting {
//                        #if DEBUG
//                        let endTime = Date()
//                        let elapse = endTime.timeIntervalSince(startTime)
//                        print("compression time: \(elapse)")
//                        #endif
//                        DispatchQueue.main.sync {
//                            completion(.success(outputURL))
//                        }
//                    }
//                default:
//                    completion(.failure(writer.error!))
//                }
//            }
//        } catch {
//            completion(.failure(error))
//        }
//    }
        
    func createVideoSettingsWithBitrate(_ bitrate: Int, maxKeyFrameInterval: Int, size: CGSize) -> [String : Any] {
        return [AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: size.width,
               AVVideoHeightKey: size.height,
          AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: bitrate,
                                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                                 AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC,
                             AVVideoMaxKeyFrameIntervalKey: maxKeyFrameInterval
                                 ]
        ]
    }
    
    func createAudioSettingsWithAudioTrack(_ audioTrack: AVAssetTrack, bitrate: Int, sampleRate: Int) -> [String : Any] {
        var formatDescription: CMFormatDescription?
        if let audioFormatDescs = audioTrack.formatDescriptions as? [CMFormatDescription] {
            formatDescription = audioFormatDescs.first
        }
#if DEBUG
        print("########## Audio ##########")
        print("Original:")
        print("bitrate: \(audioTrack.estimatedDataRate)")
#endif
        var channelLayout = AudioChannelLayout()
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo
        channelLayout.mChannelBitmap = AudioChannelBitmap(rawValue: 0)
        channelLayout.mNumberChannelDescriptions = 0
        
        var layoutData = Data(bytes: &channelLayout, count: MemoryLayout<AudioChannelLayout>.size)
        guard let formatDesc = formatDescription else {
//            var channelLayout = AudioChannelLayout()
//            channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo
//            channelLayout.mChannelBitmap = AudioChannelBitmap(rawValue: 0)
//            channelLayout.mNumberChannelDescriptions = 0
                    
            let compressSetting: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: bitrate,
                AVSampleRateKey: sampleRate,
                AVChannelLayoutKey: layoutData,
            ]
            return compressSetting
        }
        
//        var sampleRate: Float64 = 44100
        var channels: UInt32 = 2
        var formatID: AudioFormatID = kAudioFormatMPEG4AAC
        
        if let streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc) {
//            if sampleRate > streamBasicDescription.pointee.mSampleRate {
//                sampleRate = streamBasicDescription.pointee.mSampleRate
            //            }
#if DEBUG
            print("sampleRate: \(streamBasicDescription.pointee.mSampleRate)")
            print("channels: \(streamBasicDescription.pointee.mChannelsPerFrame)")
            print("formatID: \(streamBasicDescription.pointee.mFormatID)")
#endif
//            channels = streamBasicDescription.pointee.mChannelsPerFrame
//            formatID = streamBasicDescription.pointee.mFormatID
        }
        
        var layoutSize: Int = 0
//        var layoutData: Data = Data()
        if let currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(formatDesc, sizeOut: &layoutSize) {
            // handle a special case 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
            // use AAC_HE instead of AAC
//            if currentChannelLayout.pointee.mChannelLayoutTag == kAudioChannelLayoutTag_MPEG_5_1_D && formatID != kAudioFormatMPEG4AAC_HE {
//                formatID = kAudioFormatMPEG4AAC_HE
//            }
//            layoutData = layoutSize > 0 ? Data(bytes: currentChannelLayout, count: layoutSize) : Data()
        }
        
        
#if DEBUG
        print("Target:")
        print("bitrate: \(bitrate)")
        print("sampleRate: \(sampleRate)")
        print("channels: \(channels)")
        print("formatID: \(formatID)")
#endif
        
        let compressSetting: [String: Any] = [
            AVFormatIDKey: formatID,
            AVNumberOfChannelsKey: channels,
            AVEncoderBitRateKey: bitrate,
            AVSampleRateKey: sampleRate,
            AVChannelLayoutKey: layoutData,
        ]
        return compressSetting
    }
    
    func videoCompressSettings(_ videoTrack: AVAssetTrack, quality: VideoQuality) -> [String : Any] {
        let targetBitRateTimes = quality.value.1
        // bit rate
        let originBitRate = Int(videoTrack.estimatedDataRate)
        let tempBitRate = originBitRate / targetBitRateTimes
        let compressedBitRate = tempBitRate > VideoCompressor.minimumVideoBitrate ? tempBitRate : VideoCompressor.minimumVideoBitrate
        
        // aspect ratio
        var compressedWidth: CGFloat = videoTrack.naturalSize.width
        var compressedHeight: CGFloat = videoTrack.naturalSize.height
        if compressedWidth > 640 {
            let aspectRatio: CGFloat = videoTrack.naturalSize.width / videoTrack.naturalSize.height
            compressedWidth = 640
            compressedHeight = compressedWidth / aspectRatio
        }
        #if DEBUG
        print("original bit rate: \(originBitRate) b/s")
        print("target bit rate: \(compressedBitRate) b/s")
        print("original size: \(videoTrack.naturalSize)")
        print("target size: (\(compressedWidth), \(compressedHeight))")
        #endif
        
        
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
            var channelLayout = AudioChannelLayout.init()
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
    
    private func outputVideoDataByReducingFPS(originFPS: Float,
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

    func outputVideoData(_ videoInput: AVAssetWriterInput,
                         videoOutput: AVAssetReaderTrackOutput,
                         completion: @escaping(() -> Void)) {
        // Loop Video Frames
        videoInput.requestMediaDataWhenReady(on: videoCompressQueue) {
            while videoInput.isReadyForMoreMediaData {
                if let vBuffer = videoOutput.copyNextSampleBuffer(), CMSampleBufferDataIsReady(vBuffer) {
                    videoInput.append(vBuffer)
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
