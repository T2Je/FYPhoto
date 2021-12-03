//
//  PhotoTransitionDriver.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/1.
//

import Foundation
import UIKit

class PhotoTransitionDriver: TransitionDriver {

    var transitionAnimator: UIViewPropertyAnimator!
    var isInteractive: Bool {
        return transitionContext.isInteractive
    }
    let transitionContext: UIViewControllerContextTransitioning
    let isPresenting: Bool
    let isNavigationAnimation: Bool
    let transitionEssential: TransitionEssentialClosure?

    var fromAssetTransitioning: PhotoTransitioning?

    private let duration: TimeInterval

    var toView: UIView? // toView is nil when dismissing
    var fromView: UIView?

    var visualEffectView = UIVisualEffectView()

    /// The snapshotView that is animating between the two view controllers.
    fileprivate let transitionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.accessibilityIgnoresInvertColors = true
//        imageView.backgroundColor = .black
        return imageView
    }()

    var transitionType: TransitionType = .noTransitionAnimation

    // MARK: Initialization

    init(isPresenting: Bool,
         isNavigationAnimation: Bool,
         context: UIViewControllerContextTransitioning,
         duration: TimeInterval,
         transitionEssential: TransitionEssentialClosure?) {
        self.transitionContext = context
        self.isPresenting = isPresenting
        self.duration = duration
        self.isNavigationAnimation = isNavigationAnimation
        self.transitionEssential = transitionEssential
        setup(context)
    }

    func setup(_ context: UIViewControllerContextTransitioning) {
        // Setup the transition
        guard
            var fromViewController = context.viewController(forKey: .from),
            var toViewController = context.viewController(forKey: .to)
        else {
            return
        }
        self.toView = context.view(forKey: .to)
        if !isPresenting {
            self.fromView = context.view(forKey: .from)
        }

        let containerView = context.containerView

        if fromViewController is UINavigationController {
            if let naviTopViewController = (fromViewController as? UINavigationController)?.topViewController {
                fromViewController = naviTopViewController
            }
        }
        fromAssetTransitioning = fromViewController as? PhotoTransitioning

        if toViewController is UINavigationController {
            if let naviTopViewController = (toViewController as? UINavigationController)?.topViewController {
                toViewController = naviTopViewController
            }
        }

        var currentPage: Int = 0
        if isPresenting {
            if let photoBrowser = toViewController as? PhotoBrowserCurrentPage {
                currentPage = photoBrowser.currentPage
            }
        } else {
            if let photoBrowser = fromViewController as? PhotoBrowserCurrentPage {
                currentPage = photoBrowser.currentPage
            }
        }

        if let toView = self.toView {
            toView.alpha = 0.0
            containerView.addSubview(toView)
            // Ensure the toView has the correct size and position
            // toView.frame = context.finalFrame(for: toViewController)
        }

        // transitionImageView should be the top view of containerView
        if let fromTransition = fromAssetTransitioning, let toTransition = toViewController as? PhotoTransitioning {
            transitionType = .photoTransitionProtocol(from: fromTransition, to: toTransition)
            if isPresenting {
                addEffectView(on: containerView)
            }
//            addEffectView(on: containerView)
            containerView.addSubview(transitionImageView)

            transitionImageView.image = fromTransition.referenceImage()
            transitionImageView.frame = fromTransition.imageFrame() ?? containerView.frame

            // Inform the view controller's the transition is about to start
            fromTransition.transitionWillStart()
            toTransition.transitionWillStart()
        } else if let transitionEssential = transitionEssential, let essential = transitionEssential(currentPage) {
            transitionType = .transitionBlock(essential: essential)
            containerView.addSubview(transitionImageView)
            if isPresenting {
                transitionImageView.image = essential.transitionImage
                transitionImageView.frame = essential.convertedFrame
                addEffectView(on: containerView)
            } else {
                if let fromTransition = fromAssetTransitioning {
                    transitionImageView.image = fromTransition.referenceImage()
                    transitionImageView.frame = fromTransition.imageFrame() ?? containerView.frame
                } else {
                    let render = UIGraphicsImageRenderer(size: fromViewController.view.bounds.size)
                    let fromImage = render.image { _ in
                        fromViewController.view.drawHierarchy(in: fromViewController.view.bounds, afterScreenUpdates: false)
                    }
                    transitionImageView.image = fromImage
                    transitionImageView.frame = fromViewController.view.frame
                }
            }
            containerView.addSubview(transitionImageView)
        } else {
            transitionType = .noTransitionAnimation

            if let fromTransition = fromAssetTransitioning {
                containerView.addSubview(transitionImageView)
                transitionImageView.image = fromTransition.referenceImage()
                transitionImageView.frame = fromTransition.imageFrame() ?? containerView.frame
            }
        }

        // Insert the toViewController's view into the transition container view
        var topView: UIView?
        var topViewTargetAlpha: CGFloat = 0.0
        if isPresenting {
            topView = toView
            topViewTargetAlpha = 1.0
        } else {
            topView = fromView
            if isNavigationAnimation {
                topViewTargetAlpha = 0.0
            }
        }

        // Create a UIViewPropertyAnimator that lives the lifetime of the transition
        let spring = CGFloat(0.85)
        transitionAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: spring) {
            if self.isPresenting {
                switch self.transitionType {
                case .noTransitionAnimation:
                    break
                default:
                    self.visualEffectView.backgroundColor = .black
                    self.animateTransitionImageViewForPresenting(true)
                }
            } else {
                switch self.transitionType {
                case .noTransitionAnimation:
                    self.animateTransitionImageViewForPresenting(false)
                default:
//                    self.visualEffectView.effect = nil
                    self.animateTransitionImageViewForPresenting(false)
                }
                topView?.alpha = topViewTargetAlpha // topView is fromView
                if self.isNavigationAnimation {
                    self.toView?.alpha = 1
                }
            }
        }

        transitionAnimator.startAnimation()

        transitionAnimator.addCompletion { _ in
            if self.isPresenting {
                topView?.alpha = topViewTargetAlpha
            }
            if self.isNavigationAnimation {
                self.toView?.alpha = 1
            }

            // Finish the protocol handshake
            switch self.transitionType {
            case .photoTransitionProtocol(from: let fromTransition, to: let toTransition):
                fromTransition.transitionDidEnd()
                toTransition.transitionDidEnd()
            default: break
            }
            // Remove transition views
            self.transitionImageView.image = nil
            self.transitionImageView.removeFromSuperview()
            self.visualEffectView.removeFromSuperview()

            self.transitionContext.finishInteractiveTransition()
            self.transitionContext.completeTransition(true)
        }
    }

    fileprivate func addEffectView(on containerView: UIView) {
        // Create a visual effect view and animate the effect in the transition animator
        let effect: UIVisualEffect? = isPresenting ? nil : UIBlurEffect(style: .extraLight)
        visualEffectView.effect = effect
        visualEffectView.frame = containerView.bounds
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        containerView.addSubview(visualEffectView)
    }

    func animateTransitionImageViewForPresenting(_ isPresenting: Bool) {
        switch transitionType {
        case .photoTransitionProtocol(from: let fromTransition, to: let toTransition):
            if isPresenting {
                if let fromImage = fromTransition.referenceImage(), let toView = toView {
                    let toReferenceFrame = Self.calculateZoomInImageFrame(image: fromImage, forView: toView)
                    self.transitionImageView.frame = toReferenceFrame
                }
            } else {
                if let toImageFrame = toTransition.imageFrame() {
                    self.transitionImageView.frame = toImageFrame
                }
            }
        case .transitionBlock(essential: let essential):
            if isPresenting {
                if let toView = toView, let image = essential.transitionImage {
                    let toReferenceFrame = Self.calculateZoomInImageFrame(image: image, forView: toView)
                    self.transitionImageView.frame = toReferenceFrame
                }
            } else {
                self.transitionImageView.frame = essential.convertedFrame
            }
        case .noTransitionAnimation:
            if !isPresenting {
                if let fromView = self.fromView {
                    // transitionImageView disappears at bottom view
                    let rect = CGRect(x: fromView.frame.size.width / 2, y: fromView.frame.size.height + 100, width: 0, height: 0)
                    self.transitionImageView.frame = rect
                } else {
                    self.transitionImageView.frame = .zero
                }
            }
        }
    }

}
