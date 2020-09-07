//
//  CustomNavigationController.swift
//  FYPhoto_Example
//
//  Created by xiaoyang on 2020/9/3.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

class CustomNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
//        navigationBar.tintColor = .white
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
