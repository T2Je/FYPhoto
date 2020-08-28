//
//  FGPullToRefreshView.swift
//  FGBase
//
//  Created by kun wang on 2020/08/18.
//
import UIKit

@objc public class FGPullToRefreshView: UIView {

    var handler: (()->Void)

    //为了有些界面的特殊需求，有些不是全部屏幕宽度的tableview的pulltorefreshview的中心在屏幕中央，可以设置该值
    public var xOffset: CGFloat = 0.0

    @objc public internal(set) var state: PullToRefreshState = .stopped {
        didSet {
            if state == oldValue { return }
            setNeedsLayout()
            switch state {
            case .stopped:
                isForceTriggered = false
                resetScrollViewContentInset()
//                UIView.animate(withDuration: 0.3, delay: 0.3, options: [], animations: {
//                    self.alpha = 0
//                })
            case .pulling:
                UIView.animate(withDuration: 0.1) {
                    self.alpha = 1
                }
            case .triggered:
                self.alpha = 1
                if isForceTriggered {
                    startAnimating()
                }
            case .loading:
                startAnimating()
                setScrollViewContentInsetForLoading()
                if oldValue == .triggered {
                    handler()
                }
            }
            titleLabel.text = titles[state]
            subtitleLabel.text = subTitles[state]
        }
    }

    var titles = [PullToRefreshState.loading: "Loading...".baseTablelocalized,
                  PullToRefreshState.triggered: "Release to load...".baseTablelocalized]
    var subTitles = [PullToRefreshState: String]()

    weak var scrollView: UIScrollView?

    var originalTopInset: CGFloat = 0

    var showsPullToRefresh: Bool = false
    var isObserving: Bool = false
    var subTitleIsDate: Bool = true
    var isForceTriggered: Bool = false
    var lastUpdatedDate: Date? {
        didSet {
            subTitleIsDate = true
            let tips: String
            if let date = lastUpdatedDate {
                tips = "Last update:".baseTablelocalized + dateFormatter.string(from: date)
            } else {
                tips = "Never".baseTablelocalized
            }
            subtitleLabel.text = tips
        }
    }

    init(frame: CGRect, handler: @escaping ()->Void) {
        self.handler = handler
        super.init(frame: frame)
        autoresizingMask = .flexibleWidth
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func removeObserver() {
        scrollView?.removeObserver(self, forKeyPath: "contentOffset")
        scrollView?.removeObserver(self, forKeyPath: "frame")
        isObserving = false
    }

    func addObserver() {
        if !isObserving {
            scrollView?.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
            scrollView?.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
            isObserving = true
        }
    }

    override public func willMove(toSuperview newSuperview: UIView?) {
        if superview is UIScrollView && newSuperview == nil && isObserving {
            removeObserver()
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        frame = CGRect(x: 0,
                       y: -height-originalTopInset,
                       width: bounds.size.width,
                       height: bounds.size.height)

        let screenWidth = bounds.size.width
        titleLabel.sizeToFit()
        var titleFrame = titleLabel.frame
        titleFrame.origin.x = ceil(screenWidth / 2 - titleFrame.size.width / 2) + xOffset
        titleFrame.origin.y = bounds.size.height - (subtitleLabel.text != nil ? 48 : 40)
        titleFrame.size.height = 20
        titleLabel.frame = titleFrame

        var subtitleFrame = subtitleLabel.frame
        subtitleFrame.origin.x = ceil(screenWidth / 2 - subtitleFrame.size.width / 2) + xOffset
        subtitleFrame.origin.y = titleFrame.size.height + titleFrame.origin.y
        subtitleLabel.frame = subtitleFrame

        var arrowFrame = imageView.frame
        arrowFrame.origin.x = ceil(titleFrame.origin.x - arrowFrame.size.width - 10)
        arrowFrame.origin.y = titleFrame.origin.y
        imageView.frame = arrowFrame
    }

    // MARK: - Actions
    @objc public func startAnimating() {
        state = .loading
        startSpin()
    }

    @objc public func stopAnimating() {
        state = .stopped
        if subTitleIsDate {
            lastUpdatedDate = Date()
        }
        stopSpin()
    }

    @objc public func endDataAnimating() {
        state = .stopped
        if subTitleIsDate {
            subtitleLabel.text = "没有更多的数据了"
        }
        stopSpin()
    }

    // MARK: - Scroll View
    func resetScrollViewContentInset() {
        guard let scrollView = scrollView else { return }
        var currentInsets = scrollView.contentInset
        currentInsets.top = originalTopInset
        setScrollViewContentInset(currentInsets)
    }

    func setScrollViewContentInsetForLoading() {
        guard let scrollView = scrollView else { return }
        let offset = max(scrollView.contentOffset.y * -1, 0)
        var currentInsets = scrollView.contentInset
        currentInsets.top = min(offset, originalTopInset + bounds.size.height)
        setScrollViewContentInset(currentInsets)
    }

    func setScrollViewContentInset(_ contentInset: UIEdgeInsets) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            self.scrollView?.contentInset = contentInset
        })

    }

    // MARK: - Observing
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "contentOffset") {
            if let point = change?[.newKey] as? NSValue {
                scrollViewDidScroll(point.cgPointValue)
            }
        } else if (keyPath == "frame") {
            layoutSubviews()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    func scrollViewDidScroll(_ contentOffset: CGPoint) {
        guard let scrollView = scrollView else { return }
        if state != .loading {
            let scrollOffsetThreshold = -bounds.size.height
            let realContentOffsetY = scrollView.normalizedContentOffset.y

            if !scrollView.isDragging && state == .triggered {
                state = .loading
            } else if realContentOffsetY >= scrollOffsetThreshold && scrollView.isDragging && state == .stopped {
                state = .pulling
            } else if realContentOffsetY < scrollOffsetThreshold && scrollView.isDragging && state == .pulling {
                state = .triggered
            } else if realContentOffsetY >= scrollOffsetThreshold && !scrollView.isDragging && state != .stopped {
                state = .stopped
            }
//            print(String(format: "realContentOffsetY %.2f, target %.2f, state %@", realContentOffsetY,  scrollOffsetThreshold, state.debugDescription))
        }
    }

    deinit {
        removeObserver()
    }

    // MARK: - Setter
    @objc public func setTitle(_ title: String?, for state: PullToRefreshState) {
        guard let title = title else { return }
        titles[state] = title
        setNeedsLayout()
    }

    @objc public func setSubtitle(_ subtitle: String?, for state: PullToRefreshState) {
        guard let subtitle = subtitle else { return }
        subTitles[state] = subtitle
        setNeedsLayout()
    }

    @objc override public var tintColor: UIColor! {
        didSet {
            titleLabel.textColor = tintColor
            subtitleLabel.textColor = tintColor
            imageView.tintColor = tintColor
            imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
        }
    }

    // MARK: - Animations
    func startSpin() {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.toValue = NSNumber(value: -Double.pi)
        animation.duration = 0.8
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        imageView.layer.add(animation, forKey: "AnimatedKey")

        let monkeyAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        monkeyAnimation.toValue = NSNumber(value: 2.0 * .pi)
        monkeyAnimation.duration = 0.8
        monkeyAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        monkeyAnimation.isCumulative = false
        monkeyAnimation.isRemovedOnCompletion = false //No Remove
        monkeyAnimation.repeatCount = Float.greatestFiniteMagnitude
        imageView.layer.add(monkeyAnimation, forKey: "AnimatedKey")

        let group = CAAnimationGroup()
        group.duration = 100
        group.animations = [animation, monkeyAnimation]
        imageView.layer.add(group, forKey: nil)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.4, execute: {
            self.imageView.image = "fg_ic_pull_load".baseImage?.withRenderingMode(.alwaysTemplate)
        })
    }

    func stopSpin() {
        imageView.image = "fg_ic_pull_arrow".baseImage?.withRenderingMode(.alwaysTemplate)
        imageView.transform = CGAffineTransform(rotationAngle: .pi)
        imageView.layer.removeAllAnimations()
    }

    // MARK: - Views
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        imageView.contentMode = .center
        imageView.image = "fg_ic_pull_arrow".baseImage
        imageView.transform = CGAffineTransform(rotationAngle: .pi)
        imageView.tintColor = UIColor(hex: 0x8E95A1)
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 210, height: 20))
        label.text = "Pull to refresh...".baseTablelocalized
        label.font = .systemFont(ofSize: 11)
        label.backgroundColor = .clear
        label.textColor = UIColor(displayP3Red: 0.471, green: 0.510, blue: 0.569, alpha: 1.00)
        return label
    }()

    lazy var subtitleLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 20))
        label.font = .systemFont(ofSize: 12)
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.textColor = UIColor(displayP3Red: 0.184, green: 0.239, blue: 0.325, alpha: 1.00)
        return label
    }()

    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter
    }()
}
