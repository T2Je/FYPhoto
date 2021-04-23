//
//  CropView+UIScrollViewDelegate.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/23.
//

import Foundation

extension CropView: UIScrollViewDelegate {
    // pinches imageView
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewModel.status = .touchImage
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            viewModel.status = .endTouch
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        viewModel.status = .endTouch
    }
}
