//
//  FYMenu.swift
//  FYGOMS
//
//  Created by XiaoYang on 2018/1/24.
//  Copyright © 2018年 feeyo. All rights reserved.
//

import UIKit
import SnapKit

public struct MenuVariables {
    public static let kMarginX: CGFloat = 10
    public static let kMarginY: CGFloat = 5
    public static let kMinMenuItemHeight: CGFloat = 44
    public static let kMinMenuItemWidth: CGFloat = 32

    public static let kFYArrowSize: CGFloat = 6

    public static let kImageTitleSpace: CGFloat = 10

    public typealias SelectedIndexBlock = (_ index: Int) -> Void
    public typealias DissmissedBlock = () -> Void
}

@objc public class FYMenuItem: NSObject {
    @objc public var title = ""
    @objc public var image: UIImage?
    @objc public var textColor: UIColor = .white
    @objc public var textAlighment: NSTextAlignment = .center
    @objc public var isSelected: Bool = false
    @objc public var showGradientLine: Bool = true
    @objc public var showSelectImage: Bool = true

    @objc public var value = ""
    @objc public var selectImage: UIImage? {
        if showSelectImage {
            return "fg_menu_selected".baseImage
        } else {
            return nil
        }
    }

    @objc public var index: Int = 0

    override public init() {
        super.init()
    }
}

class FYMenuOverlay: UIView, UIGestureRecognizerDelegate {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.isOpaque = false

        let tap = UITapGestureRecognizer(target: self, action: #selector(singleTap(_:)))
        tap.delegate = self
        self.addGestureRecognizer(tap)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var subView: UIView?
        let touchPoint = touch.location(in: self)
        for view in self.subviews where view is FYMenuView {
            subView = view
        }
        if let view = subView {
            return !view.frame.contains(touchPoint)
        } else {
            return true
        }
    }

    @objc func singleTap(_ gesture: UITapGestureRecognizer) {
        for view in self.subviews {
            if let menuView = view as? FYMenuView {
                if menuView.responds(to: #selector(FYMenuView.dissmissMenu(_:))) {
                    menuView.dissmissMenu(true)
                }
            }
        }
    }
}

public enum FYMenuViewArrowDirection {
    case none
    case up
    case down
    case left
    case right
}

class FYMenuView: UIView, UITableViewDelegate, UITableViewDataSource {

    var arrowDirection: FYMenuViewArrowDirection = .none
    var arrowPosition: CGFloat = 0
    var contentTableView: UITableView!

    var items = [FYMenuItem]()
    var selectBlock: MenuVariables.SelectedIndexBlock?
    var dissmissBlock: MenuVariables.DissmissedBlock?

    var backColor: UIColor = UIColor(hexString: "#191E1E")

    let cellID = "fyMenuCell"

    var cellHeight: CGFloat!

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = false
        self.alpha = 1
        self.backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showMenuView(inView view: UIView, from rect: CGRect, items: [FYMenuItem], selected: @escaping MenuVariables.SelectedIndexBlock, dissmissed: @escaping MenuVariables.DissmissedBlock) {
        self.items = items

        self.selectBlock = selected
        self.dissmissBlock = dissmissed

        contentTableView = makeContent()
        contentTableView.register(FYMenuCell.self, forCellReuseIdentifier: cellID)

        self.addSubview(contentTableView)

        self.setupFrame(inView: view, from: rect)

        let overlay = FYMenuOverlay(frame: view.bounds)
        overlay.addSubview(self)
        view.addSubview(overlay)

        contentTableView.isHidden = true
        let toFrame = self.frame
        self.frame = CGRect(origin: arrowPoint, size: CGSize(width: 1, height: 1))

        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 1
            self.frame = toFrame
        }, completion: { (_) in
            self.contentTableView.isHidden = false
        })

    }

    func makeContent() -> UITableView {
        var maxImageWidth: CGFloat = 0
        var maxItemHeight: CGFloat = 0
        var maxItemWidth: CGFloat = 0

        var maxImageHeight: CGFloat = 0
        //最大图片大小
        var tempMaxImageWidth: CGFloat = 0
        for menuItem in items {
            if let imageSize = menuItem.image?.size {
                if imageSize.width > tempMaxImageWidth {
                    tempMaxImageWidth = imageSize.width
                }

                if imageSize.height > maxImageHeight {
                    maxImageHeight = imageSize.height
                }

            }
        }

        var showSelectImage: Bool = false
        var selectedImageSize: CGSize?

        for menuItem in items where menuItem.showSelectImage {
            showSelectImage = true
            selectedImageSize = menuItem.selectImage?.size
            break
        }

        if showSelectImage && tempMaxImageWidth != 0 {
            maxImageWidth = tempMaxImageWidth + (selectedImageSize!.width + CGFloat(2) * MenuVariables.kImageTitleSpace)
        } else if !showSelectImage && tempMaxImageWidth != 0 {
            maxImageWidth = tempMaxImageWidth + (CGFloat(2) * MenuVariables.kImageTitleSpace)
        } else if showSelectImage && tempMaxImageWidth == 0 {
            maxImageWidth = selectedImageSize!.width + (CGFloat(2) * MenuVariables.kImageTitleSpace)
        }

        if showSelectImage {
            maxImageHeight = max(maxImageHeight, selectedImageSize!.height)
        }

        for menuItem in items {

            let titleSize = (menuItem.title as NSString).sizeOfFont(font: UIFont.systemFont(ofSize: 15), constrainedToWidth: Double(UIScreen.main.bounds.size.width / CGFloat(2)))

            let itemHeight = max(titleSize.height, maxImageHeight) + MenuVariables.kMarginY * CGFloat(2)
            let itemWidth = maxImageWidth + titleSize.width + MenuVariables.kMarginX * CGFloat(2)

            maxItemWidth = itemWidth > maxItemWidth ? itemWidth : maxItemWidth
            maxItemHeight = itemHeight > maxItemHeight ? itemHeight : maxItemHeight
        }
        maxItemWidth = ceil(max(maxItemWidth, MenuVariables.kMinMenuItemWidth))
        maxItemHeight = ceil(max(maxItemHeight, MenuVariables.kMinMenuItemHeight))

        cellHeight = maxItemHeight

        let totalHeight: CGFloat = min(maxItemHeight * CGFloat(6), maxItemHeight * CGFloat(items.count))

        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: maxItemWidth, height: totalHeight), style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.layer.masksToBounds = true
        tableView.layer.cornerRadius = 4
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.rowHeight = maxItemHeight
        return tableView
    }

    func setupFrame(inView view: UIView, from rect: CGRect) {
        let contentSize = contentTableView.frame.size

        let outerWidth = view.frame.width
        let outerHeight = view.frame.height

        let rectX0: CGFloat = rect.origin.x
        let rectX1: CGFloat = rect.origin.x + rect.size.width
        let rectXM: CGFloat = rect.origin.x + rect.size.width * 0.5
        let rectY0: CGFloat = rect.origin.y
        let rectY1: CGFloat = rect.origin.y + rect.size.height
        let rectYM: CGFloat = rect.origin.y + rect.size.height * 0.5

        let widthPlusArrow: CGFloat = contentSize.width + MenuVariables.kFYArrowSize
        let heightPlusArrow: CGFloat = contentSize.height + MenuVariables.kFYArrowSize
        let widthHalf: CGFloat = contentSize.width * 0.5
        let heightHalf: CGFloat = contentSize.height * 0.5

        let kMargin: CGFloat = 5

        if heightPlusArrow < (outerHeight - rectY1) {

            arrowDirection = .up
            var point = CGPoint(x: rectXM - widthHalf, y: rectY1)

            if point.x < kMargin {
                point.x = kMargin
            }

            if (point.x + contentSize.width + kMargin) > outerWidth {
                point.x = outerWidth - contentSize.width - kMargin
            }

            arrowPosition = rectXM - point.x
            contentTableView.frame = CGRect(x: 0, y: MenuVariables.kFYArrowSize, width: contentSize.width, height: contentSize.height)
            //_arrowPosition = MAX(16, MIN(_arrowPosition, contentSize.width - 16));
            self.frame = CGRect(x: point.x, y: point.y, width: contentSize.width, height: contentSize.height + MenuVariables.kFYArrowSize)

        } else if heightPlusArrow < rectY0 {

            arrowDirection = .down

            var point = CGPoint(x: rectXM - widthHalf, y: rectY0 - heightPlusArrow)

            if point.x < kMargin {
                point.x = kMargin
            }

            if (point.x + contentSize.width + kMargin) > outerWidth {
                point.x = outerWidth - contentSize.width - kMargin
            }

            arrowPosition = rectXM - point.x

            contentTableView.frame = CGRect(origin: CGPoint.zero, size: contentSize)

            self.frame = CGRect(origin: point, size: CGSize(width: contentSize.width, height: contentSize.height + MenuVariables.kFYArrowSize))
        } else if widthPlusArrow < (outerWidth - rectX1) {

            arrowDirection = .left
            var point = CGPoint(x: rectX1, y: rectYM - heightHalf)

            if point.y < kMargin {
                point.y = kMargin
            }

            if (point.y + contentSize.height + kMargin) > outerHeight {
                point.y = outerHeight - contentSize.height - kMargin
            }

            arrowPosition = rectYM - point.y
            contentTableView.frame = CGRect(x: MenuVariables.kFYArrowSize, y: 0, width: contentSize.width, height: contentSize.height)

            self.frame = CGRect(origin: point, size: CGSize(width: contentSize.width + MenuVariables.kFYArrowSize, height: contentSize.height))

        } else if widthPlusArrow < rectX0 {

            arrowDirection = .right
            var point = CGPoint(x: rectX0 - widthPlusArrow, y: rectYM - heightHalf)

            if point.y < kMargin {
                point.y = kMargin
            }

            if (point.y + contentSize.height + 5) > outerHeight {
                point.y = outerHeight - contentSize.height - kMargin
            }

            arrowPosition = rectYM - point.y
            contentTableView.frame = CGRect(origin: CGPoint.zero, size: contentSize)

            self.frame = CGRect(origin: point, size: CGSize(width: contentSize.width + MenuVariables.kFYArrowSize, height: contentSize.height))

        } else {

            arrowDirection = .none

            self.frame = CGRect(origin: CGPoint(x: (outerWidth - contentSize.width)   * 0.5, y: (outerHeight - contentSize.height) * 0.5), size: contentSize)
        }
    }

    @objc func dissmissMenu(_ animated: Bool) {
        guard self.superview != nil else {
            return
        }

        if animated {
            contentTableView.isHidden = true
            let toFrame = CGRect(origin: arrowPoint, size: CGSize(width: 1, height: 1))

            UIView.animate(withDuration: 0.2, animations: {
                self.alpha = 0
                self.frame = toFrame
            }, completion: { (_) in
                if self.superview is FYMenuOverlay {
                    self.superview?.removeFromSuperview()
                }
                self.removeFromSuperview()
            })
        } else {
            if self.superview is FYMenuOverlay {
                self.superview?.removeFromSuperview()
            }
            self.removeFromSuperview()
        }
        if let diss = dissmissBlock {
            diss()
        }
    }

    var arrowPoint: CGPoint {
        switch arrowDirection {
        case .up:
            return CGPoint(x: self.frame.minX + arrowPosition, y: self.frame.minY)
        case .down:
            return CGPoint(x: self.frame.minX + arrowPosition, y: self.frame.maxY)
        case .left:
            return CGPoint(x: self.frame.minX, y: self.frame.minY + arrowPosition)
        case .right:
            return CGPoint(x: self.frame.maxX, y: self.frame.minY + arrowPosition)
        default:
            return self.center
        }
    }

    // MARK: -
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? FYMenuCell else { return UITableViewCell() }
        cell.configure(with: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectBl = selectBlock {
            items.forEach { (item) in
                item.isSelected = false
            }
            let item = items[indexPath.row]
            item.isSelected = true
            selectBl(indexPath.row)
        }

        dissmissMenu(true)

        if let diss = dissmissBlock {
            diss()
        }
    }

    override func draw(_ rect: CGRect) {
        self.drawBackground(rect, in: UIGraphicsGetCurrentContext())
    }

    func drawBackground(_ frame: CGRect, in context: CGContext?) {
        guard context != nil else { return }

        var red0: CGFloat!, green0: CGFloat!, blue0: CGFloat!
        var red1: CGFloat!, green1: CGFloat!, blue1: CGFloat!

        if let components = UIColor(hexString: "#191E1E").cgColor.components {
            red0 = components[0]
            green0 = components[1]
            blue0 = components[2]

            red1 = components[0]
            green1 = components[1]
            blue1 = components[2]
        } else {
            red0 = CGFloat(15.0/255.0)
            green0 = CGFloat(15.0/255.0)
            blue0 = CGFloat(15.0/255.0)

            red1 = CGFloat(15.0/255.0)
            green1 = CGFloat(15.0/255.0)
            blue1 = CGFloat(15.0/255.0)
        }

        var x0 = frame.origin.x
        var x1 = frame.origin.x + frame.size.width
        var y0 = frame.origin.y
        var y1 = frame.origin.y + frame.size.height

        // render arrow
        let arrowPath = UIBezierPath()

        // fix the issue with gap of arrow's base if on the edge
        let kEmbedFix: CGFloat = 0.0

        switch arrowDirection {
        case .up:
            let arrowXM = arrowPosition
            let arrowX0 = arrowXM - MenuVariables.kFYArrowSize
            let arrowX1 = arrowXM + MenuVariables.kFYArrowSize
            let arrowY0 = y0
            let arrowY1 = y0 + MenuVariables.kFYArrowSize + kEmbedFix

            arrowPath.move(to: CGPoint(x: arrowXM, y: arrowY0))
            arrowPath.addLine(to: CGPoint(x: arrowX1, y: arrowY1))
            arrowPath.addLine(to: CGPoint(x: arrowX0, y: arrowY1))
            arrowPath.addLine(to: CGPoint(x: arrowXM, y: arrowY0))

            UIColor(red: red0, green: green0, blue: blue0, alpha: 1).set()

            y0 += MenuVariables.kFYArrowSize
        case .down:
            let arrowXM = arrowPosition
            let arrowX0 = arrowXM - MenuVariables.kFYArrowSize
            let arrowX1 = arrowXM + MenuVariables.kFYArrowSize
            let arrowY0 = y1 - MenuVariables.kFYArrowSize - kEmbedFix
            let arrowY1 = y1

            arrowPath.move(to: CGPoint(x: arrowXM, y: arrowY1))
            arrowPath.addLine(to: CGPoint(x: arrowX1, y: arrowY0))
            arrowPath.addLine(to: CGPoint(x: arrowX0, y: arrowY0))
            arrowPath.addLine(to: CGPoint(x: arrowXM, y: arrowY1))

            UIColor(red: red1, green: green1, blue: blue1, alpha: 1).set()

            y1 -= MenuVariables.kFYArrowSize

        case .left:
            let arrowYM = arrowPosition
            let arrowX0 = x0
            let arrowX1 = x0 + MenuVariables.kFYArrowSize + kEmbedFix
            let arrowY0 = arrowYM - MenuVariables.kFYArrowSize
            let arrowY1 = arrowYM + MenuVariables.kFYArrowSize

            arrowPath.move(to: CGPoint(x: arrowX0, y: arrowYM))
            arrowPath.addLine(to: CGPoint(x: arrowX1, y: arrowY0))
            arrowPath.addLine(to: CGPoint(x: arrowX1, y: arrowY1))
            arrowPath.addLine(to: CGPoint(x: arrowX0, y: arrowYM))

            UIColor(red: red0, green: green0, blue: blue0, alpha: 1).set()

            x0 += MenuVariables.kFYArrowSize
        case .right:
            let arrowYM = arrowPosition
            let arrowX0 = x1
            let arrowX1 = x1 - MenuVariables.kFYArrowSize - kEmbedFix
            let arrowY0 = arrowYM - MenuVariables.kFYArrowSize
            let arrowY1 = arrowYM + MenuVariables.kFYArrowSize

            arrowPath.move(to: CGPoint(x: arrowX0, y: arrowYM))
            arrowPath.addLine(to: CGPoint(x: arrowX1, y: arrowY0))
            arrowPath.addLine(to: CGPoint(x: arrowX1, y: arrowY1))
            arrowPath.addLine(to: CGPoint(x: arrowX0, y: arrowYM))

            UIColor(red: red1, green: green1, blue: blue1, alpha: 1).set()

            x1 -= MenuVariables.kFYArrowSize
        default: ()

        }
        arrowPath.fill()

        // render body

        let bodyFrame = CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)

        let borderPath = UIBezierPath(roundedRect: bodyFrame, cornerRadius: 4)

        let locations: [CGFloat] = [0, 1]
        let components: [CGFloat] = [red0, green0, blue0, 0.8,
                                     red1, green1, blue1, 0.8 ]

        let locationsSize = MemoryLayout<CGFloat>.size * locations.count

        let locationsFirstSize = MemoryLayout<CGFloat>.size

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let gradient = CGGradient(colorSpace: colorSpace, colorComponents: components, locations: locations, count: locationsSize / locationsFirstSize)
        borderPath.addClip()

        var start: CGPoint!, end: CGPoint!

        switch arrowDirection {
        case .left, .right:
            start = CGPoint(x: x0, y: y0)
            end = CGPoint(x: x1, y: y0)
        case .up, .down:
            start = CGPoint(x: x0, y: y0)
            end = CGPoint(x: x0, y: y1)
        default:()

        }

        context?.drawLinearGradient(gradient!, start: start, end: end, options: CGGradientDrawingOptions.init(rawValue: 0))
    }

}

@objc public class FYMenu: NSObject {
    var menuView: FYMenuView?

    public var backgroundColor: UIColor = UIColor(red: 15.0, green: 15.0, blue: 15.0, alpha: 1)
    // swiftlint:disable identifier_name
    var _tintColor: UIColor?
    // swiftlint:enable identifier_name
    public var tintColor: UIColor? {
        get {
            return _tintColor
        }
        set {
            _tintColor = newValue
        }
    }

    // singleton
    @objc public static let standard = FYMenu()
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationWillChange(_:)), name: UIApplication.willChangeStatusBarOrientationNotification, object: nil)
    }

    /// present menu view
    ///
    /// - Parameters:
    ///   - view: container view
    ///   - rect: this parameter decides the location of the little triangle ▲
    ///   - menuItems: items will be showed
    ///   - selected: selected index call back
    ///   - dismissed: dissmissed call back
    @objc public static func showMenu(in view: UIView,
                                      from rect: CGRect,
                                      menuItems: [FYMenuItem],
                                      selected: @escaping MenuVariables.SelectedIndexBlock,
                                      dismissed: @escaping MenuVariables.DissmissedBlock) {
        self.standard.showMenu(in: view, from: rect, menuItems: menuItems, selected: selected, dissmissed: dismissed)
    }

    private func showMenu(in view: UIView, from rect: CGRect, menuItems: [FYMenuItem], selected: @escaping MenuVariables.SelectedIndexBlock, dissmissed: @escaping MenuVariables.DissmissedBlock) {
        if menuView != nil {
            menuView?.dissmissMenu(false)
            menuView = nil
        }
        menuView = FYMenuView()
        menuView?.backColor = self.backgroundColor
        menuView?.showMenuView(inView: view, from: rect, items: menuItems, selected: selected, dissmissed: dissmissed)
    }

    func dissmissMenu() {
        if menuView != nil {
            menuView?.dissmissMenu(false)
            menuView = nil
        }
    }

    public static func dissmissMenu() {
        self.standard.dissmissMenu()
    }

    @objc func orientationWillChange(_ noti: NSNotification) {
        self.dissmissMenu()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension NSString {
    func sizeOfFont(font: UIFont, constrainedToWidth width: Double) -> CGSize {
        return self.boundingRect(with: CGSize(width: width, height: Double.greatestFiniteMagnitude),
                                 options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                 attributes: [NSAttributedString.Key.font: font],
                                 context: nil).size
    }
}

class FYMenuCell: UITableViewCell {
    var titleLabel = UILabel()
    var selectedImageView: UIImageView?
    var itemImageView: UIImageView?
    var gradientView: UIImageView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .clear

        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = .white
        contentView.addSubview(titleLabel)

        if let gradientImage = FYMenuCell.gradientLine(with: CGSize(width: self.bounds.width - (MenuVariables.kMarginX * CGFloat(4)), height: CGFloat(1))) {
            gradientView = UIImageView(image: gradientImage)
            if let view = gradientView {
                contentView.addSubview(view)
                view.snp.makeConstraints({ (make) in
                    make.leading.equalToSuperview().offset(MenuVariables.kMarginX)
                    make.bottom.equalToSuperview()
                    make.trailing.equalToSuperview().offset(-MenuVariables.kMarginX)
                    make.height.equalTo(1)
                })
            }
        }

        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(MenuVariables.kMarginX)
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview().offset(-MenuVariables.kMarginX)
        }

    }

    func configure(with menuItem: FYMenuItem) {
        titleLabel.text = menuItem.title
        titleLabel.textColor = menuItem.textColor

        if menuItem.image != nil && menuItem.showSelectImage {
            if itemImageView != nil {
                itemImageView?.image = menuItem.image!
            } else {
                itemImageView = UIImageView(image: menuItem.image!)
                contentView.addSubview(itemImageView!)
                itemImageView!.snp.remakeConstraints({ (make) in
                    make.leading.equalToSuperview().offset(MenuVariables.kMarginX)
                    make.centerY.equalToSuperview()
                    make.size.equalTo(menuItem.image!.size)
                })
            }

            if selectedImageView == nil {
//                selectedImageView = UIImageView(image: #imageLiteral(resourceName: "da_modular_added"))
                selectedImageView = UIImageView(image: "fg_menu_selected".baseImage)
                contentView.addSubview(selectedImageView!)
                selectedImageView!.snp.makeConstraints { (make) in
                    make.centerY.equalToSuperview()
                    make.trailing.equalToSuperview().offset(-MenuVariables.kMarginX)
                    make.size.equalTo(selectedImageView!.frame.size)
                }
            }
            titleLabel.snp.remakeConstraints({ (make) in
                make.leading.equalTo(itemImageView!.snp.trailing).offset(MenuVariables.kImageTitleSpace)
                make.top.bottom.equalToSuperview()
                make.trailing.greaterThanOrEqualTo(selectedImageView!.snp.leading).offset(-MenuVariables.kImageTitleSpace)
            })

        } else if menuItem.image != nil && !menuItem.showSelectImage {
            selectedImageView?.removeFromSuperview()
            selectedImageView = nil

            if itemImageView != nil {
                itemImageView?.image = menuItem.image!
            } else {
                itemImageView = UIImageView(image: menuItem.image!)
                contentView.addSubview(itemImageView!)
                itemImageView!.snp.remakeConstraints({ (make) in
                    make.leading.equalToSuperview().offset(MenuVariables.kMarginX)
                    make.centerY.equalToSuperview()
                    make.size.equalTo(menuItem.image!.size)
                })
            }
            titleLabel.snp.remakeConstraints({ (make) in
                make.leading.equalTo(itemImageView!.snp.trailing).offset(MenuVariables.kImageTitleSpace)
                make.top.bottom.equalToSuperview()
                make.trailing.equalToSuperview().offset(-MenuVariables.kMarginX)
            })
        } else if menuItem.image == nil && menuItem.showSelectImage {
            itemImageView?.removeFromSuperview()
            itemImageView = nil

            if selectedImageView == nil {
                selectedImageView = UIImageView(image: menuItem.selectImage)
                contentView.addSubview(selectedImageView!)
                selectedImageView!.snp.makeConstraints { (make) in
                    make.centerY.equalToSuperview()
                    make.trailing.equalToSuperview().offset(-MenuVariables.kMarginX)
                    make.size.equalTo(selectedImageView!.frame.size)
                }
            }

            titleLabel.snp.remakeConstraints { (make) in
                make.leading.equalToSuperview().offset(MenuVariables.kMarginX)
                make.top.bottom.equalToSuperview()
                make.trailing.greaterThanOrEqualTo(selectedImageView!.snp.leading).offset(-MenuVariables.kImageTitleSpace)
            }
        } else if menuItem.image == nil && !menuItem.showSelectImage {
            titleLabel.snp.remakeConstraints { (make) in
                make.leading.equalTo(MenuVariables.kMarginX)
                make.top.bottom.equalToSuperview()
                make.trailing.equalToSuperview().offset(-MenuVariables.kMarginX)
            }
        }

        if menuItem.isSelected && menuItem.showSelectImage {
            selectedImageView?.isHidden = false
        } else {
            selectedImageView?.isHidden = true
        }

        if menuItem.showGradientLine {
            gradientView?.isHidden = false
        } else {
            gradientView?.isHidden = true
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func gradientLine(with size: CGSize) -> UIImage? {
        let locations: [CGFloat] = [0, 0.2, 0.5, 0.8, 1]
        let r: CGFloat = 0.44, g: CGFloat = 0.44, b: CGFloat = 0.44
        let components: [CGFloat] = [
            r, g, b, 1,
            r, g, b, 1,
            r, g, b, 1,
            r, g, b, 1,
            r, g, b, 1
        ]
        return self.gradientImage(with: size, locations: locations, components: components, count: 5)
    }

    static func gradientImage(with size: CGSize, locations: [CGFloat], components: [CGFloat], count: Int) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            let colorSpace = CGColorSpaceCreateDeviceRGB()

            if let colorGradient = CGGradient(colorSpace: colorSpace, colorComponents: components, locations: locations, count: count) {

                context.drawLinearGradient(colorGradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size.width, y: 0), options: CGGradientDrawingOptions.init(rawValue: 0))

                if let image = UIGraphicsGetImageFromCurrentImageContext() {
                    return image
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

}
