//
//  PresentPhotoTransitionController.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/1/7.
//

import Foundation

class PhotoPresentTransitionController: NSObject, UIViewControllerTransitioningDelegate {
    let viewController: UIViewController
    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
    }
    
    var interactiveAnimator: PhotoInteractiveForPushAnimator?
    var currentAnimator: UIViewControllerAnimatedTransitioning?
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = PhotoHideShowAnimator(isPresenting: true)
        currentAnimator = animator
        return animator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        let animator = PhotoHideShowAnimator(isPresenting: false)
        let animator = PhotoInteractiveForPresentAnimator()
        currentAnimator = animator
        return animator
    }
    
    
}
