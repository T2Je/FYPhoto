//
//  PhotoTransitionDriver.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/1.
//

import Foundation

class PhotoTransitionDriver: TransitionDriver {    
    
    var transitionAnimator: UIViewPropertyAnimator!
    var isInteractive: Bool {
        return transitionContext.isInteractive
    }
    let transitionContext: UIViewControllerContextTransitioning
    let isPresenting: Bool
    let isNavigationAnimation: Bool
    let transitionViewBlock: (() -> UIImageView?)?
    
    private let duration: TimeInterval

    var toView: UIView!
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
    
    var transitionType: TransitionType = .missingInfo        

    // MARK: Initialization

    init(isPresenting: Bool,
         isNavigationAnimation: Bool,
         context: UIViewControllerContextTransitioning,
         duration: TimeInterval,
         transitionViewBlock: (() -> UIImageView?)?) {
        self.transitionContext = context
        self.isPresenting = isPresenting
        self.duration = duration
        self.isNavigationAnimation = isNavigationAnimation
        self.transitionViewBlock = transitionViewBlock
        setup(context)
    }

    func setup(_ context: UIViewControllerContextTransitioning) {
        // Setup the transition
        guard
            let fromViewController = context.viewController(forKey: .from),
            let toViewController = context.viewController(forKey: .to),
            let toView = context.view(forKey: .to)
        else {
            return
        }
        self.toView = toView
        
        if isNavigationAnimation {
            self.fromView = context.view(forKey: .from)
        }
        
        let containerView = context.containerView
        
        if let fromTransition = fromViewController as? PhotoTransitioning,
           let toTransition = toViewController as? PhotoTransitioning {
            transitionType = .photoTransitionProtocol(from: fromTransition, to: toTransition)
            addEffectView(on: containerView)
            containerView.addSubview(transitionImageView)
            transitionImageView.image = fromTransition.referenceImage()
            transitionImageView.frame = fromTransition.imageFrame() ?? .zero
            // Inform the view controller's the transition is about to start
            fromTransition.transitionWillStart()
            toTransition.transitionWillStart()
        } else if let transitionViewBlock = transitionViewBlock {
            transitionType = .transitionBlock(block: transitionViewBlock)
            addEffectView(on: containerView)
            containerView.addSubview(transitionImageView)
            if let transitionView = transitionViewBlock() {
                let frame = transitionView.convert(transitionView.bounds, to: self.toView)
                transitionImageView.image = transitionView.image
                transitionImageView.frame = frame
            }
        } else {
            transitionType = .missingInfo
        }
        
        // Insert the toViewController's view into the transition container view
        var topView: UIView?
        var topViewTargetAlpha: CGFloat = 0.0
        if isPresenting {
            topView = toView
            topViewTargetAlpha = 1.0
            toView.alpha = 0.0
            containerView.addSubview(toView)
            // Ensure the toView has the correct size and position
            toView.frame = context.finalFrame(for: toViewController)
        } else {
            topView = fromView
            topViewTargetAlpha = 0.0
            containerView.insertSubview(toView, at: 0)
            // Ensure the toView has the correct size and position
            toView.frame = context.finalFrame(for: toViewController)
        }

        // Create a UIViewPropertyAnimator that lives the lifetime of the transition
        let spring = CGFloat(0.85)
        transitionAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: spring) {
            if !self.isPresenting {
                switch self.transitionType {
                case .missingInfo:
                    break
                default:
                    self.visualEffectView.effect = nil
                }
                topView?.alpha = topViewTargetAlpha
            } else {
                switch self.transitionType {
                case .missingInfo:
                    break
                default:
                    self.visualEffectView.backgroundColor = .black
                }
            }
        }
        
        transitionAnimator.startAnimation()
        
        if isPresenting {
            transitionAnimator.addAnimations {
                self.animateTransitionImageViewForPresenting(true)
            }
        } else {
            // HACK: By delaying 0.005s, I get a layout-refresh on the toViewController,
            // which means its collectionview has updated its layout,
            // and our toAssetTransitioning?.imageFrame() is accurate, even if
            // the device has rotated.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
                self.transitionAnimator.addAnimations {
                    self.animateTransitionImageViewForPresenting(false)
                }
            }
        }

        transitionAnimator.addCompletion { _ in
            if self.isPresenting {
                topView?.alpha = topViewTargetAlpha
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
        let effect: UIVisualEffect? = !isPresenting ? UIBlurEffect(style: .extraLight) : nil
        visualEffectView.effect = effect
        visualEffectView.frame = containerView.bounds
        visualEffectView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        containerView.addSubview(visualEffectView)
    }
    
    func animateTransitionImageViewForPresenting(_ isPresenting: Bool) {
        switch transitionType {
        case .photoTransitionProtocol(from: let fromTransition, to: let toTransition):
            if isPresenting {
                if let fromImage = fromTransition.referenceImage() {
                    let toReferenceFrame = Self.calculateZoomInImageFrame(image: fromImage, forView: self.toView)
                    self.transitionImageView.frame = toReferenceFrame
                }
            } else {
                if let toImageFrame = toTransition.imageFrame() {
                    self.transitionImageView.frame = toImageFrame
                }
            }
        case .transitionBlock(block: let block):
            if isPresenting {
                if let imageView = block(), let image = imageView.image {
                    let toReferenceFrame = Self.calculateZoomInImageFrame(image: image, forView: self.toView)
                    self.transitionImageView.frame = toReferenceFrame
                }
            } else {
                if let imageView = block() {
                    let frame = imageView.convert(imageView.bounds, to: self.fromView)
                    self.transitionImageView.frame = frame
                } else {
                    self.transitionImageView.frame = .zero
                }
            }
        case .missingInfo:
            if isPresenting {
                
            } else {
                self.transitionImageView.frame = .zero
            }
            break
        }
    }
    
}
