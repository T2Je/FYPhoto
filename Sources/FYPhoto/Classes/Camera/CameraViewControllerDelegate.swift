//
//  File.swift
//  
//
//  Created by xiaoyang on 2023/2/9.
//

import Foundation

public protocol CameraViewControllerDelegate: AnyObject {
    func camera(_ cameraViewController: CameraViewController, didFinishCapturingMediaInfo info: [CameraViewController.InfoKey: Any])
    func cameraDidCancel(_ cameraViewController: CameraViewController)    
}
