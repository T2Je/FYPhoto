//
//  AlertView+extention.swift
//  FlightList
//
//  Created by 月云 on 2018/9/29.
//

import Foundation

extension UIAlertController {
	static let alertCancelButtonIndex = 2017829

	//MARK: Alert
	// mutiple menu
	public class func alert(title: String?,
							message: String?,
							buttonTitles: [String],
							actionBlock: @escaping (_ index: Int)-> Void) {
		
		self.alertWith(title: title,message: message,buttonTitles: buttonTitles,alertStyles: [],actionBlock: actionBlock)
	}

	// one menu
	public class func singleMenuAlert(title: String?,
									  message: String?,
									  buttonTitle: String,
									  actionBlock: @escaping (_ index: Int)-> Void) {

		self.alertWith(title: title,message: message,buttonTitles: [buttonTitle],alertStyles: [UIAlertAction.Style.cancel.rawValue],actionBlock: actionBlock)
	}

	// double menu
	public class func doubleMenuAlert(title: String?,
									  message: String?,
									  cancelButtonTitle: String,
									  otherButtonTitle: String,
									  actionBlock: @escaping (_ index: Int)-> Void) {

		self.alertWith(title: title,message: message,buttonTitles: [cancelButtonTitle,otherButtonTitle],alertStyles: [UIAlertAction.Style.cancel.rawValue,UIAlertAction.Style.default.rawValue],actionBlock: actionBlock)
	}


	private class func alertWith(title: String?,
								 message: String?,
								 buttonTitles: [String],
								 alertStyles: [Int],
								 actionBlock: @escaping (_ index: Int)-> Void) {
		let alertController = self.alertController(title: title,
												   message: message,
												   buttonTitles: buttonTitles,
												   alertStyles: alertStyles,
												   alertControllerStyle: .alert,
												   actionBlock: actionBlock)
        //  必须是keyWindow 才能在AlerController 展示时成为first responder
        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
        // Odd problem on iOS 12(maybe lower system also has the problem， except iOS 9). UIAlertController can't resign first responder which causes the UITextEffectsWindow can't be the first responder

        //        let window = UIWindow.init(frame: UIScreen.main.bounds)
        //        let rootViewController = UIViewController()
        //        window.rootViewController = rootViewController
        //        let topWindow = UIApplication.shared.windows.last
        //        window.windowLevel = UIWindow.Level.alert + 1
        //        print("window level = \(window.windowLevel)")
        //        window.makeKeyAndVisible()
        //        rootViewController.present(alertController, animated: true, completion: nil)
	}

	private class func alertController(title: String?,
									   message: String?,
									   buttonTitles: [String],
									   alertStyles: [Int],
									   alertControllerStyle: UIAlertController.Style,
									   actionBlock: @escaping (_ index: Int)-> Void) -> UIAlertController {
		let alertController = UIAlertController.init(title: title, message: message, preferredStyle: alertControllerStyle)
		for i  in  0..<buttonTitles.count {
			var alertStyle = UIAlertAction.Style.default.rawValue
			if i < alertStyles.count {
				alertStyle = alertStyles[i]
			}

			let buttonTitle = buttonTitles[i]

			let action = UIAlertAction.init(title: buttonTitle, style: UIAlertAction.Style(rawValue: alertStyle) ?? .default) { (action) in
				if action.style == UIAlertAction.Style.cancel {
					actionBlock(UIAlertController.alertCancelButtonIndex)
				} else {
					actionBlock(i)
				}
			}
			alertController.addAction(action)
		}
		return alertController
	}


	//MARK: actionSheet
	public class func actionSheet(title: String?,
								  message: String?,
								  cancelTitle: String?,
								  otherButtonTitles: [String],
								  actionBlock: @escaping (_ index: Int)-> Void)  {
		self.actionSheet(title: title, message: message, cancelTitle: cancelTitle, destructiveTitle: "", otherButtonTitles: otherButtonTitles, actionBlock: actionBlock)
	}

	public class func actionSheet(title: String?,
								  message: String?,
								  cancelTitle: String?,
								  destructiveTitle:String,
								  otherButtonTitles: [String],
								  actionBlock: @escaping (_ index: Int)-> Void)  {

		var buttonTitleArray = [String]()

		if otherButtonTitles.isEmpty {
			buttonTitleArray = Array()
		} else {
			buttonTitleArray = otherButtonTitles
		}

		var alertStyles = [Int]()

		otherButtonTitles.forEach { (_) in
			alertStyles.append(UIAlertAction.Style.default.rawValue)
		}
		alertStyles.append(UIAlertAction.Style.cancel.rawValue)

		if destructiveTitle.isEmpty == false {
			buttonTitleArray.append(destructiveTitle)
			alertStyles.append(UIAlertAction.Style.destructive.rawValue)
		}
		self.actionSheet(title: title, message: message, buttonTitles: buttonTitleArray, alertStyles: alertStyles, actionBlock: actionBlock)
	}

	private class func actionSheet(title: String?,
								   message: String?,
								   buttonTitles: [String],
								   alertStyles: [Int],
								   actionBlock: @escaping (_ index: Int)-> Void) {
		let actionSheetController = self.alertController(title: title, message: message, buttonTitles: buttonTitles, alertStyles: alertStyles, alertControllerStyle: .actionSheet, actionBlock: actionBlock)

        //  必须是keyWindow 才能在AlerController 展示时成为first responder
        UIApplication.shared.keyWindow?.rootViewController?.present(actionSheetController, animated: true, completion: nil)
        // Odd problem on iOS 12(maybe lower system also has the problem， except iOS 9). UIAlertController can't resign first responder which causes the UITextEffectsWindow can't be the first responder

        //        let window = UIWindow.init(frame: UIScreen.main.bounds)
        //        let rootViewController = UIViewController()
        //        window.rootViewController = rootViewController
        //        let topWindow = UIApplication.shared.windows.last
        //        window.windowLevel = UIWindow.Level.alert + 1
        //        print("window level = \(window.windowLevel)")
        //        window.makeKeyAndVisible()
        //        rootViewController.present(alertController, animated: true, completion: nil)
	}


    @objc public func fg_show() {
        fg_show(true)
    }

    @objc public func fg_show(_ animated: Bool) {
        UIApplication.shared.keyWindow?.rootViewController?.present(self, animated: animated, completion: nil)
    }
}

