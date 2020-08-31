//
//  AssetTransitionDriver.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/8/27.
//

import Foundation

class AssetTransitionDriver {
    var transitionAnimator: UIViewPropertyAnimator!
    var isInteractive: Bool { return transitionContext.isInteractive }
    let transitionContext: UIViewControllerContextTransitioning

    private let operation: UINavigationController.Operation
    private let panGestureRecognizer: UIPanGestureRecognizer
    private let duration: TimeInterval
    private var itemFrameAnimator: UIViewPropertyAnimator?
    private var item: Photo?
    private var interactiveItem: Photo?

//    private var initialFrame: CGRect?
//    private var targetFrame: CGRect?

    var fromAssetTransitioning: AssetTransitioning?
    var toAssetTransitioning: AssetTransitioning?

    var toView: UIView?
    var fromView: UIView?

    var visualEffectView = UIVisualEffectView()
    /// The snapshotView that is animating between the two view controllers.
    fileprivate let transitionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        if #available(iOS 11.0, *) {
            imageView.accessibilityIgnoresInvertColors = true
        } else {
            // Fallback on earlier versions
        }
        return imageView
    }()

    // MARK: Initialization

    init(operation: UINavigationController.Operation, context: UIViewControllerContextTransitioning, panGestureRecognizer panGesture: UIPanGestureRecognizer, duration: TimeInterval) {
        self.transitionContext = context
        self.operation = operation
        self.panGestureRecognizer = panGesture
        self.duration = duration

        setup(context)
    }

    func setup(_ context: UIViewControllerContextTransitioning) {
        // Setup the transition "chrome"
        guard
            let fromViewController = context.viewController(forKey: .from),
            let toViewController = context.viewController(forKey: .to),
            let fromAssetTransitioning = (fromViewController as? AssetTransitioning),
            let toAssetTransitioning = (toViewController as? AssetTransitioning),
            let fromView = fromViewController.view,
            let toView = toViewController.view
            else {
                assertionFailure("None of them should be nil")
                return
        }

        self.fromAssetTransitioning = fromAssetTransitioning
        self.toAssetTransitioning = toAssetTransitioning
        self.toView = toView
        self.fromView = fromView

        let containerView = context.containerView

        // Add ourselves as a target of the pan gesture
        self.panGestureRecognizer.addTarget(self, action: #selector(updateInteraction(_:)))

        // Create a visual effect view and animate the effect in the transition animator
        let effect: UIVisualEffect? = (operation == .pop) ? UIBlurEffect(style: .extraLight) : nil
        let targetEffect: UIVisualEffect? = (operation == .pop) ? nil : UIBlurEffect(style: .light)
//        let visualEffectView = UIVisualEffectView(effect: effect)
        visualEffectView.effect = effect
        visualEffectView.frame = containerView.bounds
        visualEffectView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        containerView.addSubview(visualEffectView)

        // Insert the toViewController's view into the transition container view
        let topView: UIView
        var topViewTargetAlpha: CGFloat = 0.0
        if operation == .push {
            topView = toView
            topViewTargetAlpha = 1.0
            toView.alpha = 0.0
            containerView.addSubview(toView)
        } else {
            topView = fromView
            topViewTargetAlpha = 0.0
            containerView.insertSubview(toView, at: 0)
        }

        // Ensure the toView has the correct size and position
        toView.frame = context.finalFrame(for: toViewController)
        
        if let fromImage = fromAssetTransitioning.referenceImage() {
            transitionImageView.image = fromImage
        }

        if let frame = fromAssetTransitioning.imageFrame() {
            transitionImageView.frame = frame
        }

        containerView.addSubview(transitionImageView)

        // Inform the view controller's the transition is about to start
        fromAssetTransitioning.transitionWillStart()
        toAssetTransitioning.transitionWillStart()

        // Create a UIViewPropertyAnimator that lives the lifetime of the transition
        let spring = CGFloat(0.95)
        transitionAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: spring) {
            topView.alpha = topViewTargetAlpha
            self.visualEffectView.effect = targetEffect
        }

        if context.isInteractive {
            // If the transition is initially interactive, ensure we know what item is being manipulated
//            self.updateInteractiveItemFor(panGestureRecognizer.location(in: containerView))
            self.interactiveItem = self.item
        } else {
            // Begin the animation phase immediately if the transition is not initially interactive
            animate(.end)
        }
    }

    // MARK: Gesture Callbacks

    // MARK: Interesting UIViewPropertyAnimator Setup

    /// UIKit calls startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning)
    /// on our interaction controller (AssetTransitionController). The AssetTransitionDriver (self) is
    /// then created with the transitionContext to manage the transition. It calls this func from Init().
    func setupTransitionAnimator(_ transitionAnimations: @escaping ()->(), transitionCompletion: @escaping (UIViewAnimatingPosition)->()) {



//        transitionAnimator.addCompletion { [unowned self] (position) in
//            print("transitionAnimator completed!")
//            print("current thread: \(Thread.current)")
//            // Call the supplied completion
//            transitionCompletion(position)
//
//            // Inform the transition context that the transition has completed
//            let completed = (position == .end)
//            self.transitionContext.completeTransition(completed)
//        }
    }



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
//        if completionPosition == .end {
//            transitionContext.finishInteractiveTransition()
//        } else {
//            transitionContext.cancelInteractiveTransition()
//        }

        // Begin the animation phase of the transition to either the start or finsh position
        animate(completionPosition)
    }

    func animate(_ toPosition: UIViewAnimatingPosition) {
        // Create a property animator to animate each image's frame change
//        let itemFrameAnimator = AssetTransitionDriver.propertyAnimator(initialVelocity: timingCurveVelocity())
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
                if self.operation == .push {
                    if let referencedImage = self.fromAssetTransitioning?.referenceImage(),
                        let toView = self.toView {
                        let toReferenceFrame = AssetTransitionDriver.calculateZoomInImageFrame(image: referencedImage, forView: toView)
                        self.transitionImageView.frame = toReferenceFrame
                    }
                } else {
                    if let imageFrame = self.toAssetTransitioning?.imageFrame() {
                        self.transitionImageView.frame = imageFrame
                    }
                }
            } else { // cancel
                if let imageFrame = self.fromAssetTransitioning?.imageFrame() {
                    self.transitionImageView.frame = imageFrame
                }
            }
        }

        itemFrameAnimator.addCompletion { [weak self] _ in
            guard let self = self else { return }
            // Finish the protocol handshake
            self.fromAssetTransitioning?.transitionDidEnd()
            self.toAssetTransitioning?.transitionDidEnd()
            // Remove transition views
            self.transitionImageView.image = nil
            self.transitionImageView.removeFromSuperview()
            self.visualEffectView.removeFromSuperview()

            if toPosition == .end {
                self.transitionContext.finishInteractiveTransition()
                self.transitionContext.completeTransition(true)
            } else {
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

    // MARK: Interesting Property Animator Stuff

    class func animationDuration() -> TimeInterval {
        return AssetTransitionDriver.propertyAnimator().duration
    }


    // MARK: Private Helpers

        func competionFor(translation: CGPoint) -> CGFloat {
            return (operation == .push ? -1.0 : 1.0) * translation.y / transitionContext.containerView.bounds.midY
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
            let completionThreshold: CGFloat = 0.33
            let flickMagnitude: CGFloat = 1200 //pts/sec
            let velocity = panGestureRecognizer.velocity(in: transitionContext.containerView).vector
            let isFlick = (velocity.magnitude > flickMagnitude)
            let isFlickDown = isFlick && (velocity.dy > 0.0)
            let isFlickUp = isFlick && (velocity.dy < 0.0)

            if (operation == .push && isFlickUp) || (operation == .pop && isFlickDown) {
                return .end
            } else if (operation == .push && isFlickDown) || (operation == .pop && isFlickUp) {
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

    class func propertyAnimator(initialVelocity: CGVector = .zero) -> UIViewPropertyAnimator {
        let timingParameters = UISpringTimingParameters(mass: 4.5, stiffness: 1300, damping: 95, initialVelocity: initialVelocity)
        return UIViewPropertyAnimator(duration: assetTransitionDuration, timingParameters:timingParameters)
    }

    /// If no location is provided by the fromDelegate, we'll use an offscreen-bottom position for the image.
    private static func defaultOffscreenFrameForPresentation(image: UIImage, forView view: UIView) -> CGRect {
        var result = AssetTransitionDriver.calculateZoomInImageFrame(image: image, forView: view)
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
