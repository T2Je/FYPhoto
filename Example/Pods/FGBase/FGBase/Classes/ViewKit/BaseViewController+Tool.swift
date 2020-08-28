//
//  BaseViewController+Tool.swift
//  FGBase
//
//  Created by kun wang on 2018/7/19.
//

import UIKit
import MBProgressHUD

extension UIViewController {

    @objc public func showTips(_ tips: String) {
        showTips(tips, container: nil)
    }

    @objc public func showTips(_ tips: String, container: UIView? = nil) {
        let attributeString = NSAttributedString(string: tips,
                                                 attributes:
            [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor(hex: 0x9f9f9f)])
        showAttributeTips(attributeString, container: container)
    }

    @objc public func showAttributeTips(_ tips: NSAttributedString, container: UIView? = nil) {
        guard let containerView = container ?? self.view else { return }
        FGTipsView.hideTipsView(at: containerView)
        guard let image = emptyImage() else { return }
        let tipsView = FGTipsView.init(container: containerView, tips: tips, image: image)
        containerView.addSubview(tipsView)
    }

    @objc public func showTips(error: Error) {
        showTips(error: error, container: nil)
    }

    @objc public func showTips(error: Error, container: UIView? = nil) {
        let timeoutString = "Request time out, try later".baseTablelocalized
        let tips = (error as NSError).code == NSURLErrorTimedOut ? timeoutString : error.localizedDescription
        self.showTips(tips, container: container)
    }

    @objc public func hideTips() {
        hideTips(nil)
    }

    @objc public func hideTips(_ container: UIView? = nil){
        guard let containerView = container ?? self.view else { return }
        FGTipsView.hideTipsView(at: containerView)
    }
}


extension UIViewController {
    @objc public func showHUD() {
        showHUD(nil)
    }

    @objc public func showHUD(_ container: UIView? = nil) {
        guard let containerView = container ?? self.view else { return }
        MBProgressHUD.hide(for: containerView, animated: true)

        let newHud = MBProgressHUD(view: containerView)
        newHud.bezelView.layer.cornerRadius = 4.0
        newHud.bezelView.blurEffectStyle = .light
        newHud.margin = 10.0
        newHud.bezelView.color = UIColor.black.withAlphaComponent(0.5)

        let imageView = UIImageView(image: requestLoadingImage())
        let fullRotation = CABasicAnimation(keyPath: "transform.rotation")
        fullRotation.fromValue = Double.pi/2
        fullRotation.toValue = 2 * .pi + Double.pi/2
        fullRotation.duration = 1.5
        fullRotation.repeatCount = MAXFLOAT
        fullRotation.isRemovedOnCompletion = false
        imageView.layer.add(fullRotation, forKey: "360fullRotation")
        newHud.customView = imageView
        newHud.mode = .customView
        containerView.addSubview(newHud)

        newHud.label.text = "Loading...".baseTablelocalized
        newHud.label.textColor = .white
        newHud.label.font = .systemFont(ofSize: 12)
        newHud.removeFromSuperViewOnHide = true
        newHud.show(animated: true)
    }

    @objc public func hideHUD() {
        hideHUD(nil)
    }

    @objc public func hideHUD(_ container: UIView? = nil) {
        guard let containerView = container ?? self.view else { return }
        MBProgressHUD.hide(for: containerView, animated: true)
    }
}

extension UIViewController {
    func emptyImage() -> UIImage? {
        let image = "fg_ic_view_empty".baseImage
        return image
    }

    func requestLoadingImage() -> UIImage? {
        let image = "fg_ic_load".baseImage
        return image
    }
}

extension UIViewController {
    @objc public func fg_isModal() -> Bool {
        if presentingViewController != nil {
            return true
        }
        if navigationController?.presentingViewController?.presentedViewController == navigationController {
            return true
        }
        if (tabBarController?.presentingViewController is UITabBarController) {
            return true
        }

        return false
    }
}
