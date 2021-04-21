//
//  PhotoEditorDemoViewController.swift
//  FYPhoto_Example
//
//  Created by xiaoyang on 2021/4/16.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

public class PhotoEditorDemoViewController: UIViewController {

    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let image = UIImage(named: "sunflower") else { return }
        let viewModel = CropViewModel(image: image)
        let cropView =  CropView(viewModel: viewModel)
        view.addSubview(cropView)
//        cropView.frame = view.frame
        cropView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cropView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            cropView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cropView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            cropView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
//        let guideView = InteractiveCropGuideView()
//        view.addSubview(guideView)
//
//        guideView.frame = CGRect(x: 20, y: 200, width: 200, height: 150)

        // Do any additional setup after loading the view.
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
