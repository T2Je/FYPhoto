/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
///
/// Edited by xiaoyang

import UIKit

@objc public enum PresentationDirection: Int {
    case left
    case top
    case right
    case bottom
    case middle
}

final public class SlideInPresentationManager: NSObject {
    // MARK: - Properties
    @objc public var direction: PresentationDirection = .left

    @objc public var disableCompactHeight = false
    /// presenting size
    @objc public var size: CGSize = .zero

    @objc public var offset: CGPoint = .zero

    @objc public var dismissed: (() -> Void)? {
        didSet {
            presentationController?.dismissed = self.dismissed
            if self.dismissed == nil {
                presentationController = nil
            }
        }
    }

    private var presentationController: SlideInPresentationController?

//    deinit {
//        print(#file, #function)
//    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension SlideInPresentationManager: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController,
                                       presenting: UIViewController?,
                                       source: UIViewController) -> UIPresentationController? {
        let presentationController = SlideInPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            direction: direction,
            size: size,
            offset: offset
        )
        presentationController.delegate = self
        self.presentationController = nil
        self.presentationController = presentationController
        return presentationController
    }

    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInPresentationAnimator(direction: direction, isPresentation: true, size: size, offset: offset)
    }


    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInPresentationAnimator(direction: direction, isPresentation: false, size: size, offset: offset)
    }

}

// MARK: - UIAdaptivePresentationControllerDelegate
extension SlideInPresentationManager: UIAdaptivePresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController,
                                          traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if traitCollection.verticalSizeClass == .compact && disableCompactHeight {
            return .overFullScreen
        } else {
            return .none
        }
    }

    //  func presentationController(
    //    _ controller: UIPresentationController,
    //    viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle
    //  ) -> UIViewController? {
    //    guard case(.overFullScreen) = style else { return nil }
    //    return UIStoryboard(name: "Main", bundle: nil)
    //      .instantiateViewController(withIdentifier: "RotateViewController")
    //  }
}
