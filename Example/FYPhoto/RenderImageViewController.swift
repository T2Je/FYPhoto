//
//  RenderImageViewController.swift
//  FYPhoto_Example
//
//  Created by xiaoyang on 2020/11/24.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

class RenderImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = image
        // Do any additional setup after loading the view.
    }
    
    var image: UIImage?
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
