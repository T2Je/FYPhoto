//
//  PhotoDetailTransition.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/24.
//

import Foundation

class PhotoDetailPushTransition: NSObject, UIViewControllerAnimatedTransitioning {
    fileprivate let fromDelegate: PhotoDetailTransitionAnimatorDelegate
    fileprivate let photoDetailVC: PhotoDetailTransitionAnimatorDelegate

    /// The snapshotView that is animating between the two view controllers.
    fileprivate let transitionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        if #available(iOS 11.0, *) {
            imageView.accessibilityIgnoresInvertColors = true
        } else {
            // Fallback on earlier versions
        }
        return imageView
    }()

    /// If fromDelegate isn't PhotoDetailTransitionAnimatorDelegate, returns nil.
    init?(fromDelegate: Any,
          toPhotoDetailVC photoDetailVC: PhotoDetailTransitionAnimatorDelegate) {
        guard let fromDelegate = fromDelegate as? PhotoDetailTransitionAnimatorDelegate else {
            return nil
        }
        self.fromDelegate = fromDelegate
        self.photoDetailVC = photoDetailVC
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.38
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let to = transitionContext.view(forKey: .to)
        let from = transitionContext.view(forKey: .from)

        let containerView = transitionContext.containerView

        to?.alpha = 0

        [from, to]
            .compactMap { $0 }
            .forEach {
                containerView.addSubview($0)
        }

        guard let referencedImage = fromDelegate.referenceImage(), let toView = to else {
            to?.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }

        transitionImageView.image = referencedImage
        transitionImageView.frame = fromDelegate.imageFrame() ??
            PhotoDetailPushTransition.defaultOffscreenFrameForPresentation(image: referencedImage, forView: toView)
        let toReferenceFrame = PhotoDetailPushTransition.calculateZoomInImageFrame(image: referencedImage, forView: toView)

        containerView.addSubview(transitionImageView)

        fromDelegate.transitionWillStart()
        photoDetailVC.transitionWillStart()

        let duration = self.transitionDuration(using: transitionContext)
        let spring = CGFloat(0.95)
        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: spring) {
            self.transitionImageView.frame = toReferenceFrame
            to?.alpha = 1
        }
        animator.addCompletion { (position) in
            guard position == .end else { return }

            self.transitionImageView.removeFromSuperview()
            self.transitionImageView.image = nil

            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)

            self.photoDetailVC.transitionDidEnd()
            self.fromDelegate.transitionDidEnd()
        }

        animator.startAnimation()
    }

    /// If no location is provided by the fromDelegate, we'll use an offscreen-bottom position for the image.
    private static func defaultOffscreenFrameForPresentation(image: UIImage, forView view: UIView) -> CGRect {
        var result = PhotoDetailPushTransition.calculateZoomInImageFrame(image: image, forView: view)
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

public class PhotoDetailPopTransition: NSObject, UIViewControllerAnimatedTransitioning {
    fileprivate let toDelegate: PhotoDetailTransitionAnimatorDelegate
    fileprivate let photoDetailVC: PhotoDetailTransitionAnimatorDelegate

    /// If toDelegate isn't PhotoDetailTransitionAnimatorDelegate, returns nil.
    init?(toDelegate: Any,
          fromPhotoDetailVC photoDetailVC: PhotoDetailTransitionAnimatorDelegate) {
        guard let toDelegate = toDelegate as? PhotoDetailTransitionAnimatorDelegate else {
            return nil
        }
        self.toDelegate = toDelegate
        self.photoDetailVC = photoDetailVC
    }

    /// The snapshotView that is animating between the two view controllers.
    fileprivate let transitionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        if #available(iOS 11.0, *) {
            imageView.accessibilityIgnoresInvertColors = true
        } else {
            // Fallback on earlier versions
        }
        return imageView
    }()

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.38
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let to = transitionContext.view(forKey: .to)
        let from = transitionContext.view(forKey: .from)

        let containerView = transitionContext.containerView

        let fromReferenceSize = photoDetailVC.imageFrame()?.size ?? CGSize(width: 90, height: 90)

        let transitionImage = photoDetailVC.referenceImage()
        transitionImageView.image = transitionImage
        transitionImageView.frame = photoDetailVC.imageFrame() ?? CGRect(x: 0, y: 0, width: 90, height: 90)

        [from, to]
            .compactMap { $0 }
            .forEach { containerView.addSubview($0) }
        to?.addSubview(transitionImageView)

        if let toVC = transitionContext.viewController(forKey: .to) {
            to?.frame = transitionContext.finalFrame(for: toVC)
        }

        self.photoDetailVC.transitionWillStart()
        self.toDelegate.transitionWillStart()

        let duration = self.transitionDuration(using: transitionContext)
        let spring: CGFloat = 0.9
        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: spring) {
            from?.alpha = 0
        }
        animator.addCompletion { (position) in
            guard position == .end else { return }
            self.transitionImageView.image = nil
            self.transitionImageView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            self.photoDetailVC.transitionDidEnd()
            self.toDelegate.transitionDidEnd()
        }
        animator.startAnimation()

        // HACK: By delaying 0.005s, I get a layout-refresh on the toViewController,
        // which means its collectionview has updated its layout,
        // and our toDelegate?.imageFrame() is accurate, even if
        // the device has rotated. :scream_cat:
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
            animator.addAnimations {
                let toReferenceFrame = self.toDelegate.imageFrame() ??
                    PhotoDetailPopTransition.defaultOffscreenFrameForDismissal(transitionImageSize: fromReferenceSize,
                                                                               screenHeight: containerView.bounds.height
                )
                self.transitionImageView.frame = toReferenceFrame
            }
        }
    }

    /// If we need a "dummy reference frame", let's throw the image off the bottom of the screen.
    /// Photos.app transitions to CGRect.zero, though I think that's ugly.
    public static func defaultOffscreenFrameForDismissal(
        transitionImageSize: CGSize,
        screenHeight: CGFloat
    ) -> CGRect {
        return CGRect(
            x: 0,
            y: screenHeight,
            width: transitionImageSize.width,
            height: transitionImageSize.height
        )
    }

}
