//
//  UIScrollView+Ex.swift
//  FGBase
//
//  Created by kun wang on 2020/08/20.
//

import UIKit

private let kFGInfiniteScrollingViewHeight: CGFloat = 60
private let kFGPullToRefreshViewHeight: CGFloat = 60

// MARK: - Extension
extension UIScrollView {
    @objc public func addInfiniteScrolling(actionHandler: @escaping () -> Void) {
        let view = FGInfiniteScrollingView(frame: CGRect(x: 0,
                                                         y: contentSize.height,
                                                         width: bounds.size.width,
                                                         height: kFGInfiniteScrollingViewHeight))
        view.handler = actionHandler
        view.scrollView = self
        addSubview(view)
        infiniteScrollingView = view
        infiniteScrollingView.addObserver()
        infiniteScrollingView.originalBottomInset = contentInset.bottom
    }

    @objc public func addPullToRefresh(actionHandler: @escaping () -> Void) {
        addPulltoRefresh(height: kFGPullToRefreshViewHeight, actionHandler: actionHandler)
    }

    @objc public func addPulltoRefresh(height: CGFloat, actionHandler: @escaping () -> Void) {
        let view = FGPullToRefreshView(frame: CGRect(x: 0,
                                                     y: -height,
                                                     width: bounds.size.width,
                                                     height: height),
                                       handler: actionHandler)
        view.scrollView = self
        addSubview(view)
        view.originalTopInset = contentInset.top
        pullToRefreshView = view
        pullToRefreshView.addObserver()
        pullToRefreshView.originalTopInset = contentInset.top
    }

    @objc public func triggerPullToRefresh() {
        pullToRefreshView.isForceTriggered = true
        pullToRefreshView.state = .triggered
    }

    @objc public func stopRefreshing() {
        pullToRefreshView.state = .stopped
        pullToRefreshView.stopAnimating()
    }
}

private var kAssociatedInfiniteViewTag: UInt8 = 99
private var kAssociatedPullToRefreshViewTag: UInt8 = 98

extension UIScrollView {
    @objc public private(set) var infiniteScrollingView: FGInfiniteScrollingView {
        get {
            return objc_getAssociatedObject(self, &kAssociatedInfiniteViewTag) as! FGInfiniteScrollingView
        }
        set {
            objc_setAssociatedObject(self, &kAssociatedInfiniteViewTag, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    @objc public private(set) var pullToRefreshView: FGPullToRefreshView {
        get {
            return objc_getAssociatedObject(self, &kAssociatedPullToRefreshViewTag) as! FGPullToRefreshView
        }
        set {
            objc_setAssociatedObject(self, &kAssociatedPullToRefreshViewTag, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}
