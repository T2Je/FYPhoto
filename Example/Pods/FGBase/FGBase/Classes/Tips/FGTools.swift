//
//  File.swift
//  FGBase
//
//  Created by kun wang on 2018/5/21.
//

import Foundation
import Toast_Swift

@objc public class FGTools: NSObject {
    @objc static public func makeErrorToast(_ error: Error?) {
        guard let error = error else { return }
        let window = UIApplication.shared.keyWindow
        let nserror = error as NSError
        let title = nserror.code == NSURLErrorTimedOut ? "Request time out, try later".baseTablelocalized : nserror.localizedDescription
        window?.makeToast(title, duration: 1, position: .center)
    }
    
    @objc static public func makeToast(_ message: String?, duration: TimeInterval = 1.0) {
        let window = UIApplication.shared.keyWindow
        window?.makeToast(message, duration: duration, position: .center)
    }
}




