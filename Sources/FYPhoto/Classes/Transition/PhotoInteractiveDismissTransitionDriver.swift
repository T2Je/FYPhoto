//
//  AssetTransitionDriver.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/8/27.
//

import Foundation
import UIKit

class PhotoInteractiveDismissTransitionDriver: TransitionDriver {
    var transitionAnimator: UIViewPropertyAnimator!
    var isInteractive: Bool { return transitionContext.isInteractive }

    private let transitionContext: UIViewControllerContextTransitioning
    private let panGestureRecognizer: UIPanGestureRecognizer
    private let isNavigationDismiss: Bool

    /// Alternate transition if viewController doesn't implement PhotoTransition
    private let transitionEssential: TransitionEssentialClosure?

    private let completion: ((_ isCancelled: Bool, _ isNavigation: Bool) -> Void)?

    private var itemFrameAnimator: UIViewPropertyAnimator?

    var fromAssetTransitioning: PhotoTransitioning?
    var toAssetTransitioning: PhotoTransitioning?

    var toView: UIView?
    var fromView: UIView?

    var visualEffectView = UIVisualEffectView()
    /// The snapshotView that is animating between the two view controllers.
    fileprivate let transitionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.accessibilityIgnoresInvertColors = true
        return imageView
    }()

    var transitionType: TransitionType = .noTransitionAnimation

    // MARK: Initialization

    init(context: UIViewControllerContextTransitioning,
         panGestureRecognizer panGesture: UIPanGestureRecognizer,
         isNavigationDismiss: Bool,
         transitionEssential: TransitionEssentialClosure?,
         completion: ((_ isCancelled: Bool, _ isNavigation: Bool) -> Void)?) {
        self.transitionContext = context
        self.panGestureRecognizer = panGesture
        self.isNavigationDismiss = isNavigationDismiss
        self.transitionEssential = transitionEssential
        self.completion = completion
        setup(context, isNavigationDismiss: isNavigationDismiss)
    }

    func setup(_ context: UIViewControllerContextTransitioning, isNavigationDismiss: Bool) {
        // Setup the transition
        guard
            var fromViewController = context.viewController(forKey: .from)
        else {
            assertionFailure("None of them should be nil")
            return
        }
        let toViewController = context.viewController(forKey: .to)

        self.fromView = context.view(forKey: .from)
        if isNavigationDismiss {
            self.toView = context.view(forKey: .to)
        }

        // Add ourselves as a target of the pan gesture
        self.panGestureRecognizer.addTarget(self, action: #selector(updateInteraction(_:)))

        let containerView = context.containerView
        if let navi = fromViewController as? UINavigationController, let topViewController = navi.topViewController {
            fromViewController = topViewController
        }
        fromAssetTransitioning = fromViewController as? PhotoTransitioning

        var currentPage: Int = 0
        if let photoBrowser = fromViewController as? PhotoBrowserCurrentPage {
            currentPage = photoBrowser.currentPage
        }

        if isNavigationDismiss, let toView = toView {
            containerView.addSubview(toView)
            // Ensure the toView has the correct size and position
            if let toVC = toViewController {
                toView.frame = context.finalFrame(for: toVC)
            }
        }

        // transitionImageView should be the top view of containerView
        // setup transition type, transition image view
        transitionImageView.image = fromAssetTransitioning?.referenceImage()
        transitionImageView.frame = fromAssetTransitioning?.imageFrame() ?? containerView.frame
        // Inform the view controller's the transition is about to start
        fromAssetTransitioning?.transitionWillStart()

        if let fromTransition = fromAssetTransitioning, let toTransition = toViewController as? PhotoTransitioning {
            self.toAssetTransitioning = toTransition
            transitionType = .photoTransitionProtocol(from: fromTransition, to: toTransition)

            setupEffectView(with: containerView)
            containerView.addSubview(visualEffectView)

            toTransition.transitionWillStart()
        } else if let transitionEssential = transitionEssential, let essential = transitionEssential(currentPage) {
            transitionType = .transitionBlock(essential: essential)
            setupEffectView(with: containerView)
            containerView.addSubview(visualEffectView)
        } else {
            transitionType = .noTransitionAnimation
        }
        containerView.addSubview(transitionImageView)

        let topView = fromView
        let topViewTargetAlpha: CGFloat = 0.0

        // Create a UIViewPropertyAnimator that lives the lifetime of the transition
        let spring = CGFloat(0.95)
        transitionAnimator = UIViewPropertyAnimator(duration: 0.38, dampingRatio: spring) {
            topView?.alpha = topViewTargetAlpha
            self.visualEffectView.effect = nil
        }
    }

    // MARK: Gesture Callbacks

    // MARK: Interesting UIViewPropertyAnimator Setup

    // MARK: Interesting Interruptible Transitioning Stuff

    @objc func updateInteraction(_ fromGesture: UIPanGestureRecognizer) {
        switch fromGesture.state {
        case .began, .changed:
            // Ask the gesture recognizer for it's translation
            let translation = fromGesture.translation(in: transitionContext.containerView)

            // Calculate the percent complete
            let percentComplete = competionFor(translation: translation)

            let transitionImageScale = transitionImageScaleFor(percentageComplete: percentComplete)

            // Update the transition animator's fractionCompete to scrub it's animations
            transitionAnimator.fractionComplete = percentComplete

            // Inform the transition context of the updated percent complete
            transitionContext.updateInteractiveTransition(percentComplete)

            // Update each transition item for the
            updateItemForInteractive(translation: translation, scale: transitionImageScale)
        case .ended, .cancelled:
            // End the interactive phase of the transition
            endInteraction()
        default: break
        }
    }

    func endInteraction() {
        // Ensure the context is currently interactive
        guard transitionContext.isInteractive else { return }

        // Inform the transition context of whether we are finishing or cancelling the transition
        let completionPosition = self.completionPosition()

        // Begin the animation phase of the transition to either the start or finsh position
        animate(completionPosition)
    }

    func setupEffectView(with container: UIView) {
        // Create a visual effect view and animate the effect in the transition animator
        let effect: UIVisualEffect? = UIBlurEffect(style: .dark)

        visualEffectView.effect = effect
        visualEffectView.frame = container.bounds
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    func animate(_ toPosition: UIViewAnimatingPosition) {
        // Create a property animator to animate each image's frame change

        // The cancel and complete animations have different timing values.
        // I dialed these in on-device using SwiftTweaks.
        let completionDuration: Double
        let completionDamping: CGFloat
        //        let finalFrame: CGRect
        if toPosition != .end { // cancel
            completionDuration = 0.45
            completionDamping = 0.75
        } else {
            completionDuration = 0.37
            completionDamping = 0.90
        }

        let itemFrameAnimator = UIViewPropertyAnimator(duration: completionDuration, dampingRatio: completionDamping) {
            self.transitionImageView.transform = CGAffineTransform.identity
            if toPosition == .end {
                switch self.transitionType {
                case .photoTransitionProtocol(from: _, to: let to):
                    self.transitionImageView.frame = to.imageFrame() ?? .zero
                case .transitionBlock(essential: let essential):
                    self.transitionImageView.frame = essential.convertedFrame
                case .noTransitionAnimation:
                    if let fromView = self.fromView {
                        // transitionImageView disappears at bottom view
                        let rect = CGRect(x: fromView.frame.size.width / 2, y: fromView.frame.size.height + 100, width: 0, height: 0)
                        self.transitionImageView.frame = rect
                    } else {
                        self.transitionImageView.frame = .zero
                    }
                }
            } else { // cancel
                if let imageFrame = self.fromAssetTransitioning?.imageFrame() {
                    self.transitionImageView.frame = imageFrame
                }
            }
        }

        itemFrameAnimator.addCompletion { _ in
            // Remove transition views
            self.transitionImageView.image = nil
            self.transitionImageView.removeFromSuperview()
            self.visualEffectView.removeFromSuperview()
            // Finish the protocol handshake
            self.fromAssetTransitioning?.transitionDidEnd()
            self.toAssetTransitioning?.transitionDidEnd()

            if toPosition == .end {
                self.completion?(false, self.isNavigationDismiss)
                self.transitionContext.finishInteractiveTransition()
                self.transitionContext.completeTransition(true)
            } else {
                self.completion?(true, self.isNavigationDismiss)
                self.transitionContext.cancelInteractiveTransition()
                self.transitionContext.completeTransition(false)
            }
        }
        // Start the property animator and keep track of it
        itemFrameAnimator.startAnimation()
        self.itemFrameAnimator = itemFrameAnimator

        // Reverse the transition animator if we are returning to the start position
        transitionAnimator.isReversed = (toPosition == .start)

        // Start or continue the transition animator (if it was previously paused)
        if transitionAnimator.state == .inactive {
            transitionAnimator.startAnimation()
        } else {
            // Calculate the duration factor for which to continue the animation.
            // This has been chosen to match the duration of the property animator created above
            let durationFactor = CGFloat(itemFrameAnimator.duration / transitionAnimator.duration)
            transitionAnimator.continueAnimation(withTimingParameters: nil, durationFactor: durationFactor)
        }
    }

    // MARK: Private Helpers

    func competionFor(translation: CGPoint) -> CGFloat {
        return translation.y / transitionContext.containerView.bounds.midY
    }

    private func transitionImageScaleFor(percentageComplete: CGFloat) -> CGFloat {
        let minScale = CGFloat(0.68)
        let result = 1 - (1 - minScale) * percentageComplete
        return result
    }

    func updateItemForInteractive(translation: CGPoint, scale: CGFloat) {
        transitionImageView.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
            .translatedBy(x: translation.x, y: translation.y)
    }

    private func completionPosition() -> UIViewAnimatingPosition {
        let completionThreshold: CGFloat = 0.0 // Dismiss when interaction starting
        let flickMagnitude: CGFloat = 1200 // pts/sec
        let velocity = panGestureRecognizer.velocity(in: transitionContext.containerView).vector
        let isFlick = (velocity.magnitude > flickMagnitude)
        let isFlickDown = isFlick && (velocity.dy > 0.0)
        let isFlickUp = isFlick && (velocity.dy < 0.0)

        if isFlickDown {
            return .end
        } else if isFlickUp {
            return .start
        } else if transitionAnimator.fractionComplete > completionThreshold {
            return .end
        } else {
            return .start
        }
    }
    /// For a given vertical offset, what's the percentage complete for the transition?
    /// e.g. -100pts -> 0%, 0pts -> 0%, 20pts -> 10%, 200pts -> 100%, 400pts -> 100%
    private func percentageComplete(forVerticalDrag verticalDrag: CGFloat) -> CGFloat {
        let maximumDelta = CGFloat(200)
        return CGFloat.scaleAndShift(value: verticalDrag, inRange: (min: CGFloat(0), max: maximumDelta))
    }

    /// If no location is provided by the fromDelegate, we'll use an offscreen-bottom position for the image.
    private static func defaultOffscreenFrameForPresentation(image: UIImage, forView view: UIView) -> CGRect {
        var result = PhotoInteractiveDismissTransitionDriver.calculateZoomInImageFrame(image: image, forView: view)
        result.origin.y = view.bounds.height
        return result
    }

    /// Because the photoDetailVC isn't laid out yet, we calculate a default rect here.
    // TODO: Move this into PhotoDetailViewController, probably!
    private static func calculateZoomInImageFrame(image: UIImage, forView view: UIView) -> CGRect {
        let rect = CGRect.makeRect(aspectRatio: image.size, insideRect: view.bounds)
        return rect
    }

}
