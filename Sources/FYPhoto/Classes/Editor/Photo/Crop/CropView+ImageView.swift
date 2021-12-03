//
//  CropView+ImageView.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/4/21.
//

import Foundation
import UIKit

extension CropView {

    /// Partially constrained view size, adapting to image aspect ratio
    class ImageView: UIImageView {
        override init(image: UIImage?) {
            super.init(image: image)
            setup()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        /// constraint to maintain same aspect ratio as the image
        private var aspectRatioConstraint: NSLayoutConstraint?

        private func setup() {
            self.contentMode = .scaleAspectFit
//            self.updateAspectRatioConstraint()
        }

        /// Removes any pre-existing aspect ratio constraint, and adds a new one based on the current image
//        private func updateAspectRatioConstraint() {
//            // remove any existing aspect ratio constraint
//            if let cons = self.aspectRatioConstraint {
//                self.removeConstraint(cons)
//            }
//            self.aspectRatioConstraint = nil
//            
//            if let imageSize = image?.size, imageSize.height != 0
//            {
//                let aspectRatio = imageSize.width / imageSize.height
//                let cons = NSLayoutConstraint(item: self, attribute: .width,
//                                              relatedBy: .equal,
//                                              toItem: self, attribute: .height,
//                                              multiplier: aspectRatio, constant: 0)
//                self.addConstraint(cons)
//                self.aspectRatioConstraint = cons
//            }
//        }
    }
}
