//
//  CustomTransitionNavigationController.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/24.
//

import UIKit

public class CustomTransitionNavigationController: UINavigationController {

    fileprivate var currentAnimationTransition: UIViewControllerAnimatedTransitioning? = nil

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        navigationBar.tintColor = .white
        navigationItem.backBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
        // Do any additional setup after loading the view.
    }

    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if !viewControllers.isEmpty {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CustomTransitionNavigationController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let result: UIViewControllerAnimatedTransitioning?
        if let photoDetailVC = toVC as? PhotoDetailTransitionAnimatorDelegate, operation == .push {
            result = PhotoDetailPushTransition(fromDelegate: fromVC, toPhotoDetailVC: photoDetailVC)            
        } else if let photoDetailVC = fromVC as? PhotoDetailTransitionAnimatorDelegate, operation == .pop {
            if let interactivelyDismissing = photoDetailVC as? PhotoDetailInteractivelyProtocol,
                interactivelyDismissing.isInteractivelyDismissing {
                result = PhotoDetailInteractiveDismissTransition(fromDelegate: photoDetailVC, toDelegate: toVC)
            } else {
                result = PhotoDetailPopTransition(toDelegate: toVC, fromPhotoDetailVC: photoDetailVC)
            }
        } else {
            result = nil            
        }
        self.currentAnimationTransition = result
        return result
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return self.currentAnimationTransition as? UIViewControllerInteractiveTransitioning
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        self.currentAnimationTransition = nil
    }
}
