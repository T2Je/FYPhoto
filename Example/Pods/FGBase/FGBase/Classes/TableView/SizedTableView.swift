//
//  SizedTableView.swift
//  FGBase
//
//  Created by kun wang on 2020/04/07.
//

import Foundation

/// 这个view 的作用是，使自己的view的大小随着contensize的改变而改变，这不是Tableview或者CollectionView 预期的作用，这个只能用于特殊的情况，你要知道自己在做什么，才会用到这个view
public class SelfSizedTableView: UITableView {
    public override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != self.intrinsicContentSize {
            self.invalidateIntrinsicContentSize()
        }
    }

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: contentSize.width, height: contentSize.height)
    }

    public override var contentSize:CGSize {
        didSet {
            if oldValue != self.contentSize {
                superview?.invalidateIntrinsicContentSize()
            }
        }
    }
}

public class SelfSizedCollectionView: UICollectionView {
    public override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != self.intrinsicContentSize {
            self.invalidateIntrinsicContentSize()
        }
    }

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: contentSize.width, height: contentSize.height)
    }

    public override var contentSize:CGSize {
        didSet {
            if oldValue != self.contentSize {
                superview?.invalidateIntrinsicContentSize()
            }
        }
    }
}
