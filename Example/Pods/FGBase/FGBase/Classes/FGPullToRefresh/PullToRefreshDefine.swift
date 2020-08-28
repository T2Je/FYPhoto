//
//  FGPullToRefresh.swift
//  FGBase
//
//  Created by kun wang on 2019/09/05.
//

import Foundation

@objc public enum TableOperation: Int {
    case refresh = 0
    case moreData = 1
}

@objc public enum PullToRefreshState: Int, CustomDebugStringConvertible {


    case stopped    //初始化状态 结束状态
    case pulling    //拉动的状态，包括开始拉动
    case triggered  //触发了拉动结束，即将触发loading
    case loading    //触发loading，并等待结束

    public var debugDescription: String {
        switch self {
        case .stopped: return "stoped"
        case .pulling: return "pulling"
        case .triggered: return "triggered"
        case .loading: return "loading"
        }
    }
}

extension UIScrollView {
    var normalizedContentOffset: CGPoint {
        let contentOffset = self.contentOffset
        let contentInset = self.effectiveContentInset

        let output = CGPoint(x: contentOffset.x + contentInset.left, y: contentOffset.y + contentInset.top)
        return output
    }

    var effectiveContentInset: UIEdgeInsets {
        if #available(iOS 11, *) {
            return adjustedContentInset
        } else {
            return contentInset
        }
    }
}
