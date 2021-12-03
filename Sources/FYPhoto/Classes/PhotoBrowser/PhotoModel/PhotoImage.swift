//
//  PhotoImage.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/12/10.
//

import Foundation
import Photos
import UIKit

class PhotoImage: PhotoProtocol {
    var image: UIImage?

    var metaData: Data?

    var url: URL?

    var asset: PHAsset?
    var targetSize: CGSize?

    var restoreData: CroppedRestoreData?

    private init() { }

    convenience init(image: UIImage) {
        self.init()
        self.image = image
    }

    convenience init(cgImage: CGImage) {
        self.init()
        let image = UIImage(cgImage: cgImage)
        self.image = image
    }

    convenience init(contentsOfFile path: String) {
        self.init()
        let image = UIImage(contentsOfFile: path)
        self.image = image
    }

    convenience init(imageNamed named: String) {
        self.init()
        let image = UIImage(named: named)
        self.image = image
    }

    func isEqualTo(_ photo: PhotoProtocol) -> Bool {
        guard let photoImage = photo.image else { return false }
        return photoImage == image!
    }

}
