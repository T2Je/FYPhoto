//
//  AnimationTabBarController.swift
//  FYPhotoPicker
//
//  Created by xiaoyang on 2020/7/24.
//

import UIKit

/** A custom tab-bar-controller that:
- requires that its viewControllers be AnimationTabBarControllers,
- keeps its tab bar hidden appropriately
- animates its tab bar in/out nicely
  **/
class AnimationTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    func setTabBar(hidden: Bool,
                   animated: Bool = true,
                   alongside animator: UIViewPropertyAnimator? = nil) {
        // TODO implement tab-bar animation.
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
