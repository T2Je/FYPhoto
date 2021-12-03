//
//  UIViewController+ShowMessage.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/3/10.
//

import Foundation
import UIKit

extension UIViewController {
    func showMessage(_ message: String, autoDismiss: Bool = true, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)

        if autoDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.dismiss(animated: true)
            }
        } else {
            let okAction = UIAlertAction(title: L10n.ok, style: .default) { _ in
                self.dismiss(animated: true, completion: completion)
            }
            let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel)
            alert.addAction(okAction)
            alert.addAction(cancelAction)
        }
    }

    func showError(_ error: Error, autoDismiss: Bool = true, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "✕", message: error.localizedDescription, preferredStyle: .alert)
        present(alert, animated: true)

        if autoDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.dismiss(animated: true)
            }
        } else {
            let okAction = UIAlertAction(title: L10n.ok, style: .default) { _ in
                self.dismiss(animated: true, completion: completion)
            }
            alert.addAction(okAction)
        }
    }
}
