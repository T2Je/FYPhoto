//
//  PhotoEditorDemoViewController.swift
//  FYPhoto_Example
//
//  Created by xiaoyang on 2021/4/16.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

public class PhotoEditorDemoViewController: UIViewController {
    let cropView: CropView
    
    public init(image: UIImage = UIImage(named: "sunflower")!) {
        let viewModel = CropViewModel(image: image)
        cropView = CropView(viewModel: viewModel)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(cropView)

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
    
    var initialLayout = false
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !initialLayout {
            initialLayout = true
            cropView.updateViews()
        }
        
    }
}
