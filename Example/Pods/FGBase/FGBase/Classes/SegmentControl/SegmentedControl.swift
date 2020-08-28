//
//  SegmentedControl.swift
//  FGBase
//
//  Created by kun wang on 2020/07/21.
//

import UIKit

public typealias IndexChangeBlock = (_ index: Int) -> Void
public typealias TitleFormatterBlock = (_ segmentedControl: SegmentedControl, _ title: String, _ index: Int, _ selected: Bool) -> NSAttributedString

open class SegmentedControl: UIControl {

    public enum SelectionStyle {
        // Indicator width will only be as big as the text width
        case textWidthStripe
        // Indicator width will fill the whole segment
        case fullWidthStripe
        // A rectangle that covers the whole segment
        case box
        // // An arrow in the middle of the segment pointing top or bottom depending on `SelectionIndicatorLocation`
        case arrow
    }

    public enum SelectionIndicatorLocation {
        case top
        case bottom
        case none
    }

    public enum WidthStyle {
        case fixed
        case dynamic
    }

    public struct BorderType: OptionSet {
        public let rawValue: Int
        public static let top = BorderType(rawValue: 1 << 0)
        public static let left = BorderType(rawValue: 1 << 1)
        public static let bottom = BorderType(rawValue: 1 << 2)
        public static let right = BorderType(rawValue: 1 << 3)
        public static let all: [BorderType] = [.top, .left, .bottom, .right]
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        fileprivate func layerRect(on rect: CGRect, borderWidth: CGFloat) -> CGRect {
            if self == .top {
                return CGRect(x: 0, y: 0, width: rect.size.width, height: borderWidth)
            } else if self == .left {
                return CGRect(x: 0, y: 0, width: borderWidth, height: rect.size.height)
            } else if self == .right {
                return CGRect(x: rect.size.width - borderWidth, y: 0, width: borderWidth, height: rect.size.height)
            } else if self == .bottom {
                return CGRect(x: 0, y: rect.size.height - borderWidth, width: rect.size.width, height: borderWidth)
            } else {
                return .zero
            }
        }
    }

    public static let noSegment = -1

    enum ContentType {
        case text
        case images
        case textImages
    }

    public enum ImagePosition {
        case behindText
        case leftOfText
        case rightOfText
        case aboveTex
        case belowText
    }

    public var sectionTitles: [String] = [] {
        didSet {
            setNeedsLayout()
            setNeedsDisplay()
        }
    }

    public var sectionImages: [UIImage] = [] {
        didSet {
            setNeedsLayout()
            setNeedsDisplay()
        }
    }

    public var sectionSelectedImages: [UIImage] = [] {
        didSet {
            setNeedsLayout()
            setNeedsDisplay()
        }
    }

    public var indexChangeBlock: IndexChangeBlock?

    public var titleFormatter: TitleFormatterBlock?

    public dynamic var titleTextAttributes: [NSAttributedString.Key : Any] = [:]

    public dynamic var selectedTitleTextAttributes: [NSAttributedString.Key : Any] = [:]

    public dynamic var selectionIndicatorColor = UIColor(displayP3Red: 52.0/255.0, green: 181.0/255.0, blue: 229.0/255.0, alpha: 1.0)

    public dynamic var selectionIndicatorBoxColor = UIColor(displayP3Red: 52.0/255.0, green: 181.0/255.0, blue: 229.0/255.0, alpha: 1.0)

    public dynamic var verticalDividerColor = UIColor.black

    public var selectionIndicatorBoxOpacity: CGFloat = 0.2 {
        didSet {
            selectionIndicatorBoxLayer.opacity = Float(selectionIndicatorBoxOpacity)
        }
    }

    public var verticalDividerWidth: CGFloat = 1.0

    var type: ContentType = .text

    public var selectionStyle: SelectionStyle = .textWidthStripe

    private var _widthStyle: WidthStyle = .fixed

    public var segmentWidthStyle: WidthStyle {
        get {
            _widthStyle
        }
        set {
            if type == .images {
                _widthStyle = .fixed
            } else {
                _widthStyle = newValue
            }
        }
    }

    public var selectionIndicatorLocation: SelectionIndicatorLocation = .top {
        didSet {
            if selectionIndicatorLocation == .none {
                selectionIndicatorHeight = 0.0
            }
        }
    }

    public var borderType: BorderType = [] {
        didSet {
            setNeedsDisplay()
        }
    }

    public var imagePosition: ImagePosition = .behindText

    public var textImageSpacing: CGFloat = 0.0

    public var borderColor = UIColor.black

    public var borderWidth: CGFloat = 1.0

    var isUserDraggable = true

    var isTouchEnabled = true

    public var isVerticalDividerEnabled = false

    public var shouldStretchSegmentsToScreenSize = false

    public var selectedSegmentIndex: Int = 0

    public var selectionIndicatorHeight: CGFloat = 5.0

    var selectionIndicatorEdgeInsets = UIEdgeInsets.zero

    public var segmentEdgeInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)

    var enlargeEdgeInset = UIEdgeInsets.zero

    public var shouldAnimateUserSelection = true

    private var selectionIndicatorStripLayer = CALayer()
    private lazy var selectionIndicatorBoxLayer: CALayer = {
        let layer = CALayer()
        layer.opacity = Float(self.selectionIndicatorBoxOpacity)
        layer.borderWidth = 1.0
        return layer
    }()
    private var selectionIndicatorArrowLayer = CALayer()
    private var segmentWidth: CGFloat = 0.0
    private var segmentWidths: [CGFloat] = []
    private var scrollView: SCScrollView = {
        let view = SCScrollView()
        view.scrollsToTop = false
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()

    private var titleBackgroundLayers: [CALayer] = []

    fileprivate func commonInit() {
        backgroundColor = .white
        isOpaque = false
        contentMode = .redraw
        addSubview(scrollView)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public init(sectionTitles: [String]) {
        super.init(frame: .zero)
        commonInit()
        self.sectionTitles = sectionTitles
        type = .text
    }

    public init(sectionImages: [UIImage], sectionSelectedImages: [UIImage]) {
        super.init(frame: .zero)
        commonInit()
        self.sectionImages = sectionImages
        self.sectionSelectedImages = sectionSelectedImages
        type = .images
    }

    public init(sectionImages: [UIImage], sectionSelectedImages: [UIImage], titlesForSections: [String]) {
        super.init(frame: .zero)
        commonInit()
        self.sectionImages = sectionImages
        self.sectionSelectedImages = sectionSelectedImages
        self.sectionTitles = titlesForSections
        type = .textImages
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateSegmentsRects()
    }

    // MARK: - Drawing
    func measureTitle(at index: Int) -> CGSize {
        if index >= sectionTitles.count {
            return .zero
        }
        let title = sectionTitles[index]
        var size = CGSize.zero
        let selected = index == selectedSegmentIndex
        if let titleFormatter = titleFormatter {
            size = titleFormatter(self, title, index, selected).size()
        } else {
            let titleAttrs = selected ? resultingSelectedTitleTextAttributes() : resultingTitleTextAttributes()
            size = (title as NSString).size(withAttributes: titleAttrs)
            if let font = titleAttrs[NSAttributedString.Key.font] as? UIFont {
                size = CGSize(width: ceil(size.width), height: ceil(size.height - font.descender))
            }
        }
        return CGRect(origin: CGPoint.zero, size: size).integral.size
    }

    func attributedTitle(at index: Int) -> NSAttributedString {
        let title = sectionTitles[index]
        let selected = index == selectedSegmentIndex
        if let titleFormatter = titleFormatter {
            return titleFormatter(self, title, index, selected)
        } else {
            let titleAttrs = selected ? resultingSelectedTitleTextAttributes() : resultingTitleTextAttributes()
            return NSAttributedString(string: title, attributes: titleAttrs)
        }
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        backgroundColor?.setFill()
        UIRectFill(bounds)
        selectionIndicatorArrowLayer.backgroundColor = selectionIndicatorColor.cgColor
        selectionIndicatorStripLayer.backgroundColor = selectionIndicatorColor.cgColor
        selectionIndicatorBoxLayer.backgroundColor = selectionIndicatorBoxColor.cgColor
        selectionIndicatorBoxLayer.borderColor = selectionIndicatorBoxColor.cgColor

        // Remove all sublayers to avoid drawing images over existing ones
        scrollView.layer.sublayers = nil

        let oldRect = rect

        switch type {
        case .text:
            removeTitleBackgroundLayers()
            for (idx, _) in sectionTitles.enumerated() {
                let size = measureTitle(at: idx)
                let stringWidth = size.width
                let stringHeight = size.height
                var rectDiv = CGRect.zero
                var fullRect = CGRect.zero
                let y = round(frame.size.height/2.0 - stringHeight/2.0) + 1
                var rect: CGRect
                switch segmentWidthStyle {
                case .fixed:
                    rect = CGRect(x: segmentWidth * CGFloat(idx) + (segmentWidth - stringWidth)/2.0,
                                  y: y,
                                  width: stringWidth,
                                  height: stringHeight)
                    rectDiv = CGRect(x: segmentWidth * CGFloat(idx) - verticalDividerWidth/2.0,
                                     y: selectionIndicatorHeight*2,
                                     width: verticalDividerWidth,
                                     height: frame.size.height - selectionIndicatorHeight * 4)
                    fullRect = CGRect(x: segmentWidth * CGFloat(idx),
                                      y: 0,
                                      width: segmentWidth,
                                      height: oldRect.size.height)

                case .dynamic:
                    var xOffset: CGFloat = 0
                    for (i, width) in segmentWidths.enumerated() {
                        if idx == i {
                            break
                        }
                        xOffset += width
                    }
                    let widthForIndex = segmentWidths[idx]
                    rect = CGRect(x: xOffset, y: y,
                                  width: widthForIndex,
                                  height: stringHeight)
                    fullRect = CGRect(x: xOffset, y: 0,
                                      width: widthForIndex,
                                      height: oldRect.size.height)
                    rectDiv = CGRect(x: xOffset - verticalDividerWidth/2,
                                     y: selectionIndicatorHeight * 2,
                                     width: verticalDividerWidth,
                                     height: frame.size.height - selectionIndicatorHeight * 4)

                }
                // Fix rect position/size to avoid blurry labels
                rect = CGRect(x: ceil(rect.origin.x),
                              y: ceil(rect.origin.y),
                              width: ceil(rect.size.width),
                              height: ceil(rect.size.height))
 
                let titleLayer = CATextLayer()
                titleLayer.frame = rect
                titleLayer.alignmentMode = .center
                titleLayer.string = attributedTitle(at: idx)
                titleLayer.contentsScale = UIScreen.main.scale
                scrollView.layer.addSublayer(titleLayer)

                if isVerticalDividerEnabled && idx > 0 {
                    let verticalDividerLayer = CALayer()
                    verticalDividerLayer.frame = rectDiv
                    verticalDividerLayer.backgroundColor = verticalDividerColor.cgColor
                    scrollView.layer.addSublayer(verticalDividerLayer)
                }

                addBackgroundAndBorderLayer(rect: fullRect)
            }
        case .images:
            removeTitleBackgroundLayers()
            for (idx, icon) in sectionImages.enumerated() {
                let imageWidth = icon.size.width
                let imageHeight = icon.size.height
                let y = (frame.size.height - selectionIndicatorHeight)/2.0 - imageHeight/2.0 + (selectionIndicatorLocation == .top ? selectionIndicatorHeight : 0)
                let x = segmentWidth * CGFloat(idx) + (segmentWidth - imageWidth)/2.0
                let rect = CGRect(x: x, y: y, width: imageWidth, height: imageHeight)
                let imageLayer = CALayer()
                imageLayer.frame = rect
                if selectedSegmentIndex == idx {
                    let highlightIcon = sectionSelectedImages[idx]
                    imageLayer.contents = highlightIcon.cgImage
                } else {
                    imageLayer.contents = icon.cgImage
                }
                scrollView.layer.addSublayer(imageLayer)
                if isVerticalDividerEnabled && idx > 0 {
                    let verticalDividerLayer = CALayer()
                    verticalDividerLayer.frame = CGRect(x: segmentWidth * CGFloat(idx) - verticalDividerWidth/2,
                                                        y: selectionIndicatorHeight * 2,
                                                        width: verticalDividerWidth,
                                                        height: frame.size.height - selectionIndicatorHeight * 4)
                    verticalDividerLayer.backgroundColor = verticalDividerColor.cgColor
                    scrollView.layer.addSublayer(verticalDividerLayer)
                }
                addBackgroundAndBorderLayer(rect: rect)
            }
        case .textImages:
            removeTitleBackgroundLayers()
            for (idx, icon) in sectionImages.enumerated() {
                let imageWidth = icon.size.width
                let imageHeight = icon.size.height
                let stringSize = measureTitle(at: idx)
                let stringHeight = stringSize.height
                let stringWidth = stringSize.width
                var imageXOffset = segmentWidth * CGFloat(idx)
                var textXOffset = segmentWidth * CGFloat(idx)
                var imageYOffset = ceil((frame.size.height - imageHeight)/2.0)
                var textYOffset = ceil((frame.size.height - stringHeight)/2.0)
                switch segmentWidthStyle {
                case .fixed:
                    switch imagePosition {
                    case .leftOfText, .rightOfText:
                        let whitespace = segmentWidth - stringSize.width - imageWidth - textImageSpacing
                        if imagePosition == .leftOfText {
                            imageXOffset += whitespace/2.0
                            textXOffset = imageXOffset + imageWidth + textImageSpacing
                        } else {
                            textXOffset += whitespace/2.0
                            imageXOffset = textXOffset + stringWidth + textImageSpacing
                        }
                    default:
                        imageXOffset = segmentWidth * CGFloat(idx) + (segmentWidth - imageWidth)/2.0
                        textXOffset = segmentWidth * CGFloat(idx) + (segmentWidth - stringWidth)/2.0
                        let whitespace = frame.size.height - imageHeight - stringHeight - textImageSpacing
                        if imagePosition == .aboveTex {
                            imageYOffset = ceil(whitespace/2.0)
                            textYOffset = imageYOffset + imageHeight + textImageSpacing
                        } else if imagePosition == .belowText {
                            textYOffset = ceil(whitespace/2.0)
                            imageYOffset = textYOffset + stringHeight + textImageSpacing
                        }
                    }
                case .dynamic:
                    var xOffset: CGFloat = 0
                    var i = 0
                    for width in segmentWidths {
                        if idx == i {
                            break
                        }
                        xOffset += width
                        i += 1
                    }
                    switch imagePosition {
                    case .leftOfText:
                        imageXOffset = xOffset
                        textXOffset = imageXOffset + imageWidth + textImageSpacing
                    case .rightOfText:
                        textXOffset = xOffset
                        imageXOffset = textXOffset + stringWidth + textImageSpacing
                    default:
                        imageXOffset = xOffset + (segmentWidths[i] - imageWidth)/2.0
                        textXOffset = xOffset + (segmentWidths[i] - stringWidth)/2.0
                        let whitespace = frame.size.height - imageHeight - stringHeight - textImageSpacing
                        if imagePosition == .aboveTex {
                            imageYOffset = ceil(whitespace/2.0)
                            textYOffset = imageYOffset + imageHeight + textImageSpacing
                        } else if imagePosition == .belowText {
                            textYOffset = ceil(whitespace/2.0)
                            imageYOffset = textYOffset + stringHeight + textImageSpacing
                        }
                    }
                }

                let imageRect = CGRect(x: imageXOffset, y: imageYOffset, width: imageWidth, height: imageHeight)
                let textRect = CGRect(x: ceil(textXOffset), y: ceil(textYOffset), width: ceil(stringWidth), height: ceil(stringHeight))
                let titleLayer = CATextLayer()
                titleLayer.frame = textRect
                titleLayer.alignmentMode = .center
                titleLayer.string = attributedTitle(at: idx)

                let imageLayer = CALayer()
                imageLayer.frame = imageRect
                if selectedSegmentIndex == idx {
                    let highlightIcon = sectionSelectedImages[idx]
                    imageLayer.contents = highlightIcon.cgImage
                } else {
                    imageLayer.contents = icon.cgImage
                }
                scrollView.layer.addSublayer(imageLayer)
                titleLayer.contentsScale = UIScreen.main.scale
                scrollView.layer.addSublayer(titleLayer)
                addBackgroundAndBorderLayer(rect: imageRect)
            }
        }

        if selectedSegmentIndex != SegmentedControl.noSegment {
            switch selectionStyle {
            case .arrow:
                if selectionIndicatorArrowLayer.superlayer == nil {
                    setArrowFrame()
                    scrollView.layer.addSublayer(selectionIndicatorArrowLayer)
                }
            default:
                if selectionIndicatorStripLayer.superlayer == nil {
                    selectionIndicatorStripLayer.frame = frameForSelectionIndicator()
                    scrollView.layer.addSublayer(selectionIndicatorStripLayer)
                    if selectionStyle == .box && selectionIndicatorBoxLayer.superlayer == nil {
                        selectionIndicatorBoxLayer.frame = frameForFillerSelectionIndicator()
                        scrollView.layer.insertSublayer(selectionIndicatorBoxLayer, at: 0)
                    }
                }
            }
        }
    }

    func removeTitleBackgroundLayers() {
        for item in titleBackgroundLayers {
            item.removeFromSuperlayer()
        }
        titleBackgroundLayers.removeAll()
    }

    fileprivate func addBorderlayerIfNeed(type: BorderType, rect: CGRect, backgroundLayer: CALayer) {
        if borderType.contains(type) {
            let borderLayer = CALayer()
            borderLayer.frame = type.layerRect(on: rect, borderWidth: borderWidth)
            borderLayer.backgroundColor = borderColor.cgColor
            backgroundLayer.addSublayer(borderLayer)
        }
    }

    func addBackgroundAndBorderLayer(rect: CGRect) {
        let backgroundLayer = CALayer()
        backgroundLayer.frame = rect
        layer.insertSublayer(backgroundLayer, at: 0)
        titleBackgroundLayers.append(backgroundLayer)
        addBorderlayerIfNeed(type: .top, rect: rect, backgroundLayer: backgroundLayer)
        addBorderlayerIfNeed(type: .left, rect: rect, backgroundLayer: backgroundLayer)
        addBorderlayerIfNeed(type: .right, rect: rect, backgroundLayer: backgroundLayer)
        addBorderlayerIfNeed(type: .bottom, rect: rect, backgroundLayer: backgroundLayer)
    }

    func setArrowFrame() {
        selectionIndicatorArrowLayer.frame = frameForSelectionIndicator()
        selectionIndicatorBoxLayer.mask = nil
        let arrowPath = UIBezierPath()
        var p1 = CGPoint.zero
        var p2 = CGPoint.zero
        var p3 = CGPoint.zero

        switch selectionIndicatorLocation {
        case .bottom:
            p1 = CGPoint(x: selectionIndicatorArrowLayer.bounds.size.width/2.0,
                         y: 0.0)
            p2 = CGPoint(x: 0,
                         y: selectionIndicatorArrowLayer.bounds.size.height)
            p3 = CGPoint(x: selectionIndicatorArrowLayer.bounds.size.width,
                         y: selectionIndicatorArrowLayer.bounds.size.height)
        case .top:
            p1 = CGPoint(x: selectionIndicatorArrowLayer.bounds.size.width/2.0,
                         y: selectionIndicatorArrowLayer.bounds.size.height);
            p2 = CGPoint(x: selectionIndicatorArrowLayer.bounds.size.width,
                         y: 0);
            p3 = CGPoint(x: 0,
                         y: 0);
        case .none: break
        }
        arrowPath.move(to: p1)
        arrowPath.addLine(to: p2)
        arrowPath.addLine(to: p3)
        arrowPath.close()
        let maskLayer = CAShapeLayer()
        maskLayer.frame = selectionIndicatorArrowLayer.bounds
        maskLayer.path = arrowPath.cgPath
        selectionIndicatorArrowLayer.mask = maskLayer
    }

    func frameForSelectionIndicator() -> CGRect {
        var indicatorYOffset: CGFloat = 0.0
        if selectionIndicatorLocation == .bottom {
            indicatorYOffset = bounds.size.height - selectionIndicatorHeight + selectionIndicatorEdgeInsets.bottom
        }

        if selectionIndicatorLocation == .top {
            indicatorYOffset = selectionIndicatorEdgeInsets.top
        }

        var sectionWidth: CGFloat = 0.0

        switch type {
        case .text:
            sectionWidth = measureTitle(at: selectedSegmentIndex).width
        case .images:
            sectionWidth = sectionImages[selectedSegmentIndex].size.width
        case .textImages:
            let stringWidth = measureTitle(at: selectedSegmentIndex).width
            let imageWidth = sectionImages[selectedSegmentIndex].size.width
            sectionWidth = max(stringWidth, imageWidth)
        }

        if selectionStyle == .arrow {
            let widthToEndOfSelectedSegment = segmentWidth * CGFloat(selectedSegmentIndex) + segmentWidth
            let widthToStartOfSelectedIndex = segmentWidth * CGFloat(selectedSegmentIndex)
            let x = widthToStartOfSelectedIndex + ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) - (selectionIndicatorHeight/2)
            return CGRect(x: x - (selectionIndicatorHeight / 2),
                          y: indicatorYOffset,
                          width: selectionIndicatorHeight * 2,
                          height: selectionIndicatorHeight)
        } else {
            if selectionStyle == .textWidthStripe && sectionWidth < segmentWidth && segmentWidthStyle != .dynamic {
                let widthToEndOfSelectedSegment = (segmentWidth * CGFloat(selectedSegmentIndex)) + segmentWidth
                let widthToStartOfSelectedIndex = segmentWidth * CGFloat(selectedSegmentIndex)
                let x = ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) + (widthToStartOfSelectedIndex - sectionWidth / 2)
                return CGRect(x: x + selectionIndicatorEdgeInsets.left,
                              y: indicatorYOffset,
                              width: sectionWidth - selectionIndicatorEdgeInsets.right,
                              height: selectionIndicatorHeight)
            } else {
                if segmentWidthStyle == .dynamic {
                    var selectedSegmentOffset: CGFloat = 0.0
                    for (i, width) in segmentWidths.enumerated() {
                        if selectedSegmentIndex == i {
                            break
                        }
                        selectedSegmentOffset += width
                    }
                    return CGRect(x: selectedSegmentOffset + selectionIndicatorEdgeInsets.left,
                                  y: indicatorYOffset,
                                  width: segmentWidths[selectedSegmentIndex] - selectionIndicatorEdgeInsets.right,
                                  height: selectionIndicatorHeight + selectionIndicatorEdgeInsets.bottom)
                }
                return CGRect(x: (segmentWidth + selectionIndicatorEdgeInsets.left) * CGFloat(selectedSegmentIndex),
                              y: indicatorYOffset,
                              width: segmentWidth - selectionIndicatorEdgeInsets.right,
                              height: selectionIndicatorHeight)
            }
        }
    }

    func frameForFillerSelectionIndicator() -> CGRect {
        switch segmentWidthStyle {
        case .dynamic:
            var selectedSegmentOffset: CGFloat = 0.0
            for (i, width) in segmentWidths.enumerated() {
                if selectedSegmentIndex == i {
                    break
                }
                selectedSegmentOffset += width
            }
            return CGRect(x: selectedSegmentOffset,
                          y: 0,
                          width: segmentWidths[selectedSegmentIndex],
                          height: frame.size.height)
        case .fixed:
            return CGRect(x: segmentWidth * CGFloat(selectedSegmentIndex),
                          y: 0,
                          width: segmentWidth,
                          height: frame.size.height)
        }
    }

    fileprivate func calculateFixedWidth() {
        for (idx, _) in sectionTitles.enumerated() {
            let stringWidth = measureTitle(at: idx).width + segmentEdgeInset.left + segmentEdgeInset.right
            segmentWidth = max(segmentWidth, stringWidth)
        }
    }

    func updateSegmentsRects() {
        scrollView.contentInset = .zero
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        if sectionCount > 0 {
            segmentWidth = frame.size.width / CGFloat(sectionCount)
        }
        switch type {
        case .text:
            switch segmentWidthStyle {
            case .fixed:
                calculateFixedWidth()
            case .dynamic:
                var mutableSegmentWidths: [CGFloat] = []
                var totalWidth: CGFloat = 0.0
                for (idx, _) in sectionTitles.enumerated() {
                    let stringWidth = measureTitle(at: idx).width + segmentEdgeInset.left + segmentEdgeInset.right
                    totalWidth += stringWidth
                    mutableSegmentWidths.append(stringWidth)
                }

                if shouldStretchSegmentsToScreenSize && totalWidth < bounds.size.width {
                    let whitespace = bounds.size.width - totalWidth
                    let whitespaceForSegment = whitespace/CGFloat(mutableSegmentWidths.count)
                    for (idx, width) in mutableSegmentWidths.enumerated() {
                        let extendedWidth = whitespaceForSegment + width
                        mutableSegmentWidths[idx] = extendedWidth
                    }
                }
                segmentWidths = mutableSegmentWidths
            }
        case .images:
            for sectionImage in sectionImages {
                let imageWidth = sectionImage.size.width + segmentEdgeInset.left + segmentEdgeInset.right
                segmentWidth = max(imageWidth, segmentWidth)
            }
        case .textImages:
            switch segmentWidthStyle {
            case .fixed:
                calculateFixedWidth()
            case .dynamic:
                var mutableSegmentWidths: [CGFloat] = []
                var totalWidth: CGFloat = 0.0
                for (idx, _) in sectionTitles.enumerated() {
                    let stringWidth = measureTitle(at: idx).width + segmentEdgeInset.right
                    let imageWidth = sectionImages[idx].size.width + segmentEdgeInset.left
                    var combineWidth: CGFloat = 0.0
                    if imagePosition == .leftOfText || imagePosition == .rightOfText {
                        combineWidth = imageWidth + stringWidth + textImageSpacing
                    } else {
                        combineWidth = max(imageWidth, stringWidth)
                    }
                    totalWidth += combineWidth
                    mutableSegmentWidths.append(combineWidth)
                }
                if shouldStretchSegmentsToScreenSize && totalWidth < bounds.size.width {
                    let whitespace = bounds.size.width - totalWidth
                    let whitespaceForSegment = whitespace/CGFloat(mutableSegmentWidths.count)
                    for (idx, width) in mutableSegmentWidths.enumerated() {
                        let extendedWidth = whitespaceForSegment + width
                        mutableSegmentWidths[idx] = extendedWidth
                    }
                }
                segmentWidths = mutableSegmentWidths
            }
        }
        scrollView.isScrollEnabled = isUserDraggable
        scrollView.contentSize = CGSize(width: totalSegmentedControlWidth, height: frame.size.height)
    }

    var sectionCount: Int {
        switch type {
        case .text: return sectionTitles.count
        case .images, .textImages: return sectionImages.count
        }
    }

    public override func willMove(toSuperview newSuperview: UIView?) {
        guard newSuperview != nil else { return }
        if !sectionTitles.isEmpty || !sectionImages.isEmpty {
            updateSegmentsRects()
        }
    }

    // MARK: - Touch
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        guard let touchLocation = touch?.location(in: self) else { return }
        let enlargeRect = CGRect(x: bounds.origin.x - enlargeEdgeInset.left,
                                 y: bounds.origin.y - enlargeEdgeInset.top,
                                 width: bounds.size.width + enlargeEdgeInset.left + enlargeEdgeInset.right,
                                 height: bounds.size.height + enlargeEdgeInset.top + enlargeEdgeInset.bottom)
        guard enlargeRect.contains(touchLocation) else { return }
        var segment = 0
        switch segmentWidthStyle {
        case .fixed:
            segment = Int((touchLocation.x + scrollView.contentOffset.x)/segmentWidth)
        case .dynamic:
            var widthLeft = (touchLocation.x + scrollView.contentOffset.x)
            for width in segmentWidths {
                widthLeft -= width
                if widthLeft <= 0 {
                    break
                }
                segment += 1
            }
        }
        if segment != selectedSegmentIndex && segment < sectionCount && isTouchEnabled {
            setSelectedSegmentIndex(segment, animated: shouldAnimateUserSelection, notify: true)
        }
    }

    // MARK: - Scrolling
    var totalSegmentedControlWidth: CGFloat {
        if type == .text && segmentWidthStyle == .fixed {
            return CGFloat(sectionTitles.count) * segmentWidth
        } else if segmentWidthStyle == .dynamic {
            return segmentWidths.reduce(.zero, +)
        } else {
            return CGFloat(sectionImages.count) * segmentWidth
        }
    }

    func scrollToSelectedSegmentIndex(animated: Bool) {
        scrollTo(index: selectedSegmentIndex, animated: animated)
    }

    func scrollTo(index: Int, animated: Bool) {
        var rectForSelectedIndex = CGRect.zero
        var selectedSegmentOffset: CGFloat = 0.0
        switch segmentWidthStyle {
        case .fixed:
            rectForSelectedIndex = CGRect(x: segmentWidth * CGFloat(index),
                                          y: 0,
                                          width: segmentWidth,
                                          height: frame.size.height)
            selectedSegmentOffset = frame.size.width/2.0 - segmentWidth/2.0
        case .dynamic:
            var offsetter: CGFloat = 0.0
            for (idx, width) in segmentWidths.enumerated() {
                if index == idx { break }
                offsetter += width
            }
            rectForSelectedIndex = CGRect(x: offsetter,
                                          y: 0,
                                          width: segmentWidths[index],
                                          height: frame.size.height)
            selectedSegmentOffset = frame.size.width/2.0 - segmentWidths[index]/2.0
        }
        var rectToScrollTo = rectForSelectedIndex
        rectToScrollTo.origin.x -= selectedSegmentOffset
        rectToScrollTo.size.width += selectedSegmentOffset * 2
        scrollView.scrollRectToVisible(rectToScrollTo, animated: animated)
    }

    // MARK: - Index Change
    func setSelectedSegmentIndex(_ index: Int) {
        setSelectedSegmentIndex(index, animated: false, notify: false)
    }

    public func setSelectedSegmentIndex(_ index: Int, animated: Bool) {
        setSelectedSegmentIndex(index, animated: animated, notify: false)
    }

    func setSelectedSegmentIndex(_ index: Int, animated: Bool, notify: Bool) {
        selectedSegmentIndex = index
        setNeedsDisplay()
        if index == SegmentedControl.noSegment {
            selectionIndicatorArrowLayer.removeFromSuperlayer()
            selectionIndicatorStripLayer.removeFromSuperlayer()
            selectionIndicatorBoxLayer.removeFromSuperlayer()
        } else {
            scrollToSelectedSegmentIndex(animated: animated)
            if animated {
                if selectionStyle == .arrow {
                    if selectionIndicatorArrowLayer.superlayer == nil {
                        scrollView.layer.addSublayer(selectionIndicatorArrowLayer)
                        setSelectedSegmentIndex(index, animated: false, notify: true)
                        return
                    }
                } else {
                    if selectionIndicatorStripLayer.superlayer == nil {
                        scrollView.layer.addSublayer(selectionIndicatorStripLayer)
                        if selectionStyle == .box && selectionIndicatorBoxLayer.sublayers == nil {
                            scrollView.layer.insertSublayer(selectionIndicatorBoxLayer, at: 0)
                        }
                        setSelectedSegmentIndex(index, animated: false, notify: true)
                        return
                    }
                }
                selectionIndicatorArrowLayer.actions = nil
                selectionIndicatorStripLayer.actions = nil
                selectionIndicatorBoxLayer.actions = nil
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.15)
                CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
                setArrowFrame()
                selectionIndicatorBoxLayer.frame = frameForSelectionIndicator()
                selectionIndicatorStripLayer.frame = frameForSelectionIndicator()
                selectionIndicatorBoxLayer.frame = frameForFillerSelectionIndicator()
                CATransaction.commit()
            } else {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                setArrowFrame()
                selectionIndicatorStripLayer.frame = frameForSelectionIndicator()
                selectionIndicatorBoxLayer.frame = frameForFillerSelectionIndicator()
                CATransaction.commit()
            }
            if notify {
                notifyForSegmentChangeTo(index: index)
            }
        }
    }

    func notifyForSegmentChangeTo(index: Int) {
        if superview != nil {
            sendActions(for: .valueChanged)
        }
        indexChangeBlock?(index)
    }
    
    // MARK: - Styling Support
    func resultingTitleTextAttributes() -> [NSAttributedString.Key : Any] {
        let defaults: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 19.0),
            NSAttributedString.Key.foregroundColor: UIColor.black
        ]
        var resultingAttrs = defaults

        for (k, v) in titleTextAttributes { resultingAttrs[k] = v
        }
        return resultingAttrs
    }

    func resultingSelectedTitleTextAttributes() -> [NSAttributedString.Key : Any] {
        var resultingAttrs = resultingTitleTextAttributes()
        for (k, v) in selectedTitleTextAttributes { resultingAttrs[k] = v
        }
        return resultingAttrs
    }

}


fileprivate class SCScrollView: UIScrollView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isDragging {
            next?.touchesBegan(touches, with: event)
        } else {
            super.touchesBegan(touches, with: event)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isDragging {
            next?.touchesMoved(touches, with: event)
        } else {
            super.touchesMoved(touches, with: event)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isDragging {
            next?.touchesEnded(touches, with: event)
        } else {
            super.touchesEnded(touches, with: event)
        }
    }
}
