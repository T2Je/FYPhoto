//
//  CameraExtensions.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/24.
//

import Foundation
import AVFoundation
import UIKit

extension AVCaptureDevice.DiscoverySession {
    var uniqueDevicePositionsCount: Int {

        var uniqueDevicePositions = [AVCaptureDevice.Position]()

        for device in devices where !uniqueDevicePositions.contains(device.position) {
            uniqueDevicePositions.append(device.position)
        }

        return uniqueDevicePositions.count
    }
}

extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }

    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}
