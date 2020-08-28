//
//  FGInfiniteScrollingView.swift
//  FGBase
//
//  Created by kun wang on 2020/08/18.
//

import UIKit

@objc public class FGInfiniteScrollingView: UIView {
    public internal(set) var state: PullToRefreshState = .stopped {
        didSet {
            if state == oldValue { return } //相同的设置不应该重复执行下面的逻辑

            let viewBounds = activityIndicatorView.bounds
            let origin = CGPoint(x: round((bounds.size.width - viewBounds.size.width) / 2 - 40),
                                 y: round((bounds.size.height - viewBounds.size.height) / 2))
            activityIndicatorView.frame = CGRect(x: origin.x, y: origin.y, width: viewBounds.size.width, height: viewBounds.size.height)
            tipsLabel.center = CGPoint(x: activityIndicatorView.frame.origin.x + activityIndicatorView.frame.size.width + 10 + tipsLabel.frame.size.width / 2, y: bounds.size.height / 2)

            switch state {
            case .stopped:
                stopIndicatorAnimating()
                tipsLabel.isHidden = true
                activityIndicatorView.isHidden = true
            case .triggered:
                tipsLabel.isHidden = false
                activityIndicatorView.isHidden = false
                tipsLabel.text = "Loading...".baseTablelocalized
                startAnimating()
            case .loading:
                tipsLabel.isHidden = false
                tipsLabel.text = "Loading...".baseTablelocalized
            default:
                break
            }

            if oldValue == .triggered && state == .loading {
                handler?()
            }

        }
    }

    weak var scrollView: UIScrollView?

    var handler: (()->Void)?
    var isObserving: Bool = false
    var originalBottomInset: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        autoresizingMask = .flexibleWidth
        addSubview(activityIndicatorView)
        addSubview(tipsLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func removeObserver() {
        scrollView?.removeObserver(self, forKeyPath: "contentOffset")
        scrollView?.removeObserver(self, forKeyPath: "contentSize")
        isObserving = false
    }

    func addObserver() {
        if !isObserving {
            scrollView?.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
            scrollView?.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
            isObserving = true
        }
    }

    override public func willMove(toSuperview newSuperview: UIView?) {
        if superview is UIScrollView, newSuperview == nil, isObserving {
            removeObserver()
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        guard let scrollView = scrollView else { return }
        activityIndicatorView.center = CGPoint(x: bounds.size.width / 2 - 40, y: bounds.size.height / 2)
        tipsLabel.center = CGPoint(x: activityIndicatorView.frame.origin.x + activityIndicatorView.frame.size.width + 10 + tipsLabel.frame.size.width / 2, y: bounds.size.height / 2)
        frame = CGRect(x: 0, y: scrollView.contentSize.height + originalBottomInset,
                       width: bounds.size.width,
                       height: bounds.size.height)
    }

    // MARK: - Scroll View
    func resetScrollViewContentInset() {
        var currentInsets = scrollView?.contentInset
        currentInsets?.bottom = originalBottomInset
        setScrollViewContentInset(currentInsets)
    }

    func setScrollViewContentInsetForInfiniteScrolling() {
        var currentInsets = scrollView?.contentInset
        currentInsets?.bottom = CGFloat(originalBottomInset + bounds.size.height)
        setScrollViewContentInset(currentInsets)
    }

    func setScrollViewContentInset(_ contentInset: UIEdgeInsets?) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            self.scrollView?.contentInset = contentInset ?? .zero
        })
    }

    // MARK: - Observing
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentOffset" {
            if let point = change?[.newKey] as? NSValue {
                scrollViewDidScroll(point.cgPointValue)
            }
        } else if keyPath == "contentSize" {
            layoutSubviews()
        }
    }

    func scrollViewDidScroll(_ contentOffset: CGPoint) {
        guard let scrollView = scrollView else { return }
        if state != .loading {

            // To avoid triggering by the bounding motion from PullToRefresh
            if contentOffset.y <= 0 {
                if contentOffset.y < -60 {
                    state = .stopped
                }
                return
            }

            let scrollViewContentHeight = scrollView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - scrollView.bounds.size.height

            if !scrollView.isDragging && state == .triggered {
                state = .loading
            } else if contentOffset.y > scrollOffsetThreshold && state == .stopped && scrollView.isDragging {
                state = .triggered
            }
        }
    }

    lazy var activityIndicatorView: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 0, y: self.bounds.size.height - 45, width: 20, height: 20))
        view.image = "fg_ic_pull_load".baseImage
        view.contentMode = .center
        view.isHidden = true
        return view
    }()

    lazy var tipsLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 20))
        label.textColor = UIColor(red: 0.741, green: 0.741, blue: 0.741, alpha: 1)
        label.backgroundColor = .clear
        label.font = .systemFont(ofSize: 13)
        label.isHidden = true
        return label
    }()

    override public var tintColor: UIColor! {
        didSet {
            tipsLabel.textColor = tintColor
            activityIndicatorView.tintColor = tintColor
            activityIndicatorView.image = activityIndicatorView.image?.withRenderingMode(.alwaysTemplate)
        }
    }

    @objc public func startAnimating() {
        startIndicatorAnimating()
        state = .loading
    }

    @objc public func stopAnimating() {
        state = .stopped
        stopIndicatorAnimating()
    }

    @objc public func endDataAnimating() {
        state = .stopped
        tipsLabel.isHidden = false
        tipsLabel.text = "End page".baseTablelocalized
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.stopIndicatorAnimating()
            self.tipsLabel.isHidden = true
            self.activityIndicatorView.isHidden = true
            self.resetScrollViewContentInset()
        }
    }

    func startIndicatorAnimating() {
        let monkeyAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        monkeyAnimation.toValue = NSNumber(value: 2.0 * .pi)
        monkeyAnimation.duration = 0.8
        monkeyAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        monkeyAnimation.isCumulative = false
        monkeyAnimation.isRemovedOnCompletion = false //No Remove
        monkeyAnimation.repeatCount = Float.greatestFiniteMagnitude
        activityIndicatorView.layer.add(monkeyAnimation, forKey: "AnimatedKey")
    }

    func stopIndicatorAnimating() {
        activityIndicatorView.layer.removeAllAnimations()
    }
}
