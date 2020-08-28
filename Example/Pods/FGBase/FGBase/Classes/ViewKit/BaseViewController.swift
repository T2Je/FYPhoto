//
//  BaseViewController.swift
//  FGBase
//
//  Created by kun wang on 2020/07/21.
//

import UIKit

@objc open class BaseViewController: UIViewController {

    open override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = .bottom
        view.backgroundColor = FGUIConfiguration.shared.bgColor
        setupNavigationBar()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(String(format: "\(#function)✅ %@", getCurrentName))
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(String(format: "\(#function)🟢 %@", getCurrentName))
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print(String(format: "\(#function)❎ %@", getCurrentName))
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print(String(format: "\(#function)🔴 %@", getCurrentName))
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    deinit {
        print(String(format: "\(#function)❌ %@", getCurrentName))
    }

    open func setupNavigationBar() {

    }
}


extension BaseViewController {
    public var getCurrentName: String {
        let thisType = type(of: self)
        return String(describing: thisType)
    }
}
