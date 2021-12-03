//
//  CropView+UIScrollViewDelegate.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/23.
//

import Foundation
import UIKit

extension CropView: UIScrollViewDelegate {
    // pinches imageView
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollViewWillBeginDragging()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidEndDragging()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating()
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewDidZoom()
    }
}
