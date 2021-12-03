//
//  CameraViewController+Watermark.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/3/8.
//

import Foundation
import AVFoundation
import UIKit

extension CameraViewController {
    func addWaterMarkImage(_ waterMark: WatermarkImage, on image: UIImage) -> UIImage {
        let imageSize = view.frame.size
        let render = UIGraphicsImageRenderer(size: imageSize)
        let renderedImage = render.image { (_) in
            image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
            waterMark.image.draw(in: waterMark.frame)
        }
        return renderedImage
    }

    func applyWatermarkToVideoComposition(watermark: WatermarkImage, videoSize: CGSize) -> AVMutableVideoComposition {
        let videoSizeScale = min(videoSize.width / view.frame.size.width, videoSize.height / view.frame.size.height)
        let imageLayer = CALayer()
        imageLayer.contents = watermark.image.cgImage
        let fixedWatermarkOriginY = watermark.frame.origin.y + watermark.frame.height
        let imageLayerOrigin = CGPoint(x: watermark.frame.origin.x * videoSizeScale,
                                       y: videoSize.height - fixedWatermarkOriginY  * videoSizeScale)
        let imageLayerSize = CGSize(width: watermark.frame.size.width * videoSizeScale, height: watermark.frame.size.height * videoSizeScale)
        imageLayer.frame = CGRect(origin: imageLayerOrigin, size: imageLayerSize)
        imageLayer.opacity = 1.0
        imageLayer.contentsGravity = .resizeAspectFill

        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: videoSize)
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(imageLayer)
//            parentLayer.addSublayer(textLayer)

        let videoComp = AVMutableVideoComposition()
        videoComp.renderSize = videoSize
        videoComp.frameDuration = CMTime(value: 1, timescale: 30)
        videoComp.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        return videoComp
    }

    func createWaterMark(waterMarkImage: WatermarkImage, onVideo url: URL, completion: @escaping ((URL) -> Void)) {
        #if DEBUG
        let startDate = Date()
        #endif

        let videoAsset = AVURLAsset(url: url)
        let mixComposition = AVMutableComposition()
        guard let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(url)
            return
        }
        guard let clipVideoTrack = videoAsset.tracks(withMediaType: .video).last else {
            completion(url)
            return
        }
        do {
            let timeRange = CMTimeRange(start: CMTime.zero, duration: videoAsset.duration)
            try compositionVideoTrack.insertTimeRange(timeRange, of: clipVideoTrack, at: CMTime.zero)
            compositionVideoTrack.preferredTransform = clipVideoTrack.preferredTransform
//            let textLayer = textWaterMark()
        } catch {
            print("video water mark error:\(error)")
            completion(url)
        }

        let videoSize = getVideoSize(with: clipVideoTrack)
        let videoComp = applyWatermarkToVideoComposition(watermark: waterMarkImage, videoSize: videoSize)

        let instrutction = AVMutableVideoCompositionInstruction()
        instrutction.timeRange = CMTimeRange(start: .zero, duration: mixComposition.duration)

        guard let videoCompositionTrack = mixComposition.tracks(withMediaType: .video).last else {
            completion(url)
            return
        }
//            videoCompositionTrack.preferredTransform = clipVideoTrack.preferredTransform
//            let t1 = CGAffineTransform(translationX: videoSize.width, y: 0)
//            let t2 = t1.rotated(by: CGFloat(deg2rad(90)))
//
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
        layerInstruction.setTransform(clipVideoTrack.preferredTransform, at: .zero)
        instrutction.layerInstructions = [layerInstruction]

        videoComp.instructions = [instrutction]

        guard
            let assetExport = AVAssetExportSession(asset: mixComposition,
                                                   presetName: AVAssetExportPresetHighestQuality) else {
            completion(url)
            return
        }
        assetExport.videoComposition = videoComp
        let videoName = "watermark-" + url.lastPathComponent
        let exportPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(videoName)

        if FileManager.default.fileExists(atPath: exportPath.absoluteString) {
            try? FileManager.default.removeItem(at: exportPath)
        }
        assetExport.outputFileType = .mp4
        assetExport.outputURL = exportPath
        assetExport.shouldOptimizeForNetworkUse = true
//            assetExport.progress
        assetExport.exportAsynchronously(completionHandler: {
            switch assetExport.status {
            case .completed:
                completion(exportPath)
                #if DEBUG
                if #available(iOS 13.0, *) {
                    let endDate = Date()
                    let distance = startDate.distance(to: endDate)
                    print("It took \(distance) to create water mark for \(videoAsset.duration.seconds) seconds video")
                }
                #endif
            case .failed:
                print("assetExport.error: \(String(describing: assetExport.error))")
                completion(url)
            default:
                completion(url)
            }
        })
    }

//    func deg2rad(_ number: Double) -> Double {
//        return number * .pi / 180
//    }

    func watermark(video: AVAsset, with image: UIImage, outputURL: URL, completion: @escaping ((URL) -> Void)) {
        #if DEBUG
        let startDate = Date()
        #endif
        guard let watermarkImage = CIImage(image: image) else {
            completion(outputURL)
            return
        }
        let context = CIContext(options: nil)
        let watermarkFilter = CIFilter(name: "CISourceOverCompositing")
        let videoComposition = AVVideoComposition(asset: video) { (request) in
            let source = request.sourceImage.clampedToExtent()
            watermarkFilter?.setValue(source, forKey: kCIInputBackgroundImageKey)
            let transform = CGAffineTransform(translationX: request.sourceImage.extent.width - watermarkImage.extent.width - 10, y: 10)
            watermarkFilter?.setValue(watermarkImage.transformed(by: transform), forKey: kCIInputImageKey)
            guard let outputImage = watermarkFilter?.outputImage else { return }
            request.finish(with: outputImage, context: context)
        }
        guard let assetExport = AVAssetExportSession(asset: video, presetName: AVAssetExportPresetLowQuality) else {
            completion(outputURL)
            return
        }
        assetExport.videoComposition = videoComposition
        assetExport.outputFileType = .mp4
        assetExport.shouldOptimizeForNetworkUse = true
        assetExport.outputURL = outputURL
        assetExport.exportAsynchronously {
            switch assetExport.status {
            case .completed:
                completion(outputURL)
                #if DEBUG
                if #available(iOS 13.0, *) {
                    let endDate = Date()
                    let distance = startDate.distance(to: endDate)
                    print("It took \(distance) to create water mark for \(video.duration.seconds) seconds video")
                } else {

                }
                #endif
            case .failed:
                print("assetExport.error: \(String(describing: assetExport.error))")
                completion(outputURL)
            default:
                completion(outputURL)
            }
        }
    }
}
