//
//  GridViewCell.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/7/15.
//

import UIKit

import UIKit

protocol GridViewCellDelegate: AnyObject {
    func gridCell(_ cell: GridViewCell, buttonClickedAt indexPath: IndexPath, assetIdentifier: String)
}

class GridViewCell: UICollectionViewCell {
    static let reuseIdentifier = "GridViewCell"

    var imageView = UIImageView()
    var livePhotoBadgeImageView = UIImageView()
    var videoDurationLabel = UILabel()

    var selectionButton = SelectionButton()
    var overlayView = UIView()
    let editedAnnotation = UIImageView(image: Asset.Crop.icons8EditImage.image)

    var representedAssetIdentifier: String!

    weak var delegate: GridViewCellDelegate?

    var indexPath: IndexPath?

    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }

    var selectionButtonTitleColor = UIColor.white
    var selectionButtonBackgroundColor = UIColor.systemBlue

    var livePhotoBadgeImage: UIImage! {
        didSet {
            livePhotoBadgeImageView.image = livePhotoBadgeImage
            isVideoAsset = false
        }
    }

    var videoDuration: String! {
        didSet {
            videoDurationLabel.text = videoDuration
            isVideoAsset = true
        }
    }

    var isVideoAsset: Bool = false {
        didSet {
            selectionButton.isHidden = isVideoAsset
        }
    }

    var isEnable: Bool = false {
        willSet {
            overlayView.isHidden = newValue
            isUserInteractionEnabled = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.image = nil
        livePhotoBadgeImageView.image = nil
        selectionButton.setImage(Asset.imageSelectedSmallOff.image, for: .normal)
        indexPath = nil
        isVideoAsset = false
        editedAnnotation.isHidden = true
    }

    func setupUI() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        videoDurationLabel.font = UIFont.systemFont(ofSize: 11, weight: .light)
        videoDurationLabel.textColor =  .white

        selectionButton.setImage(Asset.imageSelectedSmallOff.image, for: .normal)
        selectionButton.addTarget(self, action: #selector(selectionButtonClicked(_:)), for: .touchUpInside)

        selectionButton.layer.masksToBounds = true
        selectionButton.layer.cornerRadius = 16

        overlayView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        overlayView.isHidden = true

        editedAnnotation.contentMode = .scaleAspectFit
        editedAnnotation.isHidden = true

        contentView.addSubview(imageView)
        contentView.addSubview(livePhotoBadgeImageView)
        contentView.addSubview(videoDurationLabel)
        contentView.addSubview(selectionButton)
        contentView.addSubview(overlayView)
        contentView.addSubview(editedAnnotation)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        livePhotoBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
        videoDurationLabel.translatesAutoresizingMaskIntoConstraints = false
        selectionButton.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            livePhotoBadgeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            livePhotoBadgeImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            livePhotoBadgeImageView.widthAnchor.constraint(equalToConstant: 28),
            livePhotoBadgeImageView.heightAnchor.constraint(equalToConstant: 28)
        ])

        NSLayoutConstraint.activate([
            videoDurationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            videoDurationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
        ])

        NSLayoutConstraint.activate([
            selectionButton.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            selectionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -7),
            selectionButton.widthAnchor.constraint(equalToConstant: 34),
            selectionButton.heightAnchor.constraint(equalToConstant: 34)
        ])

        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
            overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        editedAnnotation.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            editedAnnotation.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            editedAnnotation.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
            editedAnnotation.widthAnchor.constraint(equalToConstant: 16),
            editedAnnotation.heightAnchor.constraint(equalToConstant: 16)
        ])

    }

    @objc func selectionButtonClicked(_ sender: UIButton) {
        if let indexPath = indexPath {
            delegate?.gridCell(self, buttonClickedAt: indexPath, assetIdentifier: representedAssetIdentifier)
        } else {
            assertionFailure("indexpath couldn't be nil!")
        }
    }

    /// change button style: image or number
    /// - Parameter title: if title is empty, button display cirle image, otherwise, button display number string.
    fileprivate func displayButtonTitle(_ title: String) {
        if title.isEmpty {
            selectionButton.setImage(Asset.imageSelectedSmallOff.image, for: .normal)
            selectionButton.setTitle(title, for: .normal)
            selectionButton.backgroundColor = .clear
            selectionButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        } else {
            selectionButton.setImage(nil, for: .normal)
            selectionButton.setTitle(title, for: .normal)
            selectionButton.setTitleColor(selectionButtonTitleColor, for: .normal)
            selectionButton.backgroundColor = selectionButtonBackgroundColor
            selectionButton.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }
    }

    func updateSelectionButtonTitle(_ title: String, _ isAnimated: Bool) {
        let isSelected = !title.isEmpty
        displayButtonTitle(title)
        if isAnimated {
            selectionButtonAnimation(isSelected: isSelected)
        }
    }

    func selectionButtonAnimation(isSelected: Bool) {
        let animationValues: [CGFloat]
        if isSelected {
            animationValues = [1.0, 0.7, 0.9, 0.8, 0.7]
        } else {
            animationValues = [1.2, 0.8, 1.1, 0.9, 1.0]
        }
        selectionButton.layer.removeAnimation(forKey: "selectionButtonAnimation")
        let keyAnimation = CAKeyframeAnimation.init(keyPath: "transform.scale")
        keyAnimation.duration = 0.25
        keyAnimation.values = animationValues
        selectionButton.layer.add(keyAnimation, forKey: "selectionButtonAnimation")
    }

    func hideUselessViewsForSingleSelection(_ isSingleSelection: Bool) {
        if isSingleSelection {
            selectionButton.isHidden = true
            overlayView.isHidden = true
            livePhotoBadgeImageView.isHidden = true
        } else {
            selectionButton.isHidden = false
            overlayView.isHidden = false
            livePhotoBadgeImageView.isHidden = false
        }
    }

    func showEditAnnotation(_ show: Bool) {
        editedAnnotation.isHidden = !show
    }
}
