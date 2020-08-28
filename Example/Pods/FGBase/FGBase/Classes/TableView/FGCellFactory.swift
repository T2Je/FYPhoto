//
//  FGCellFactory.swift
//  FYGOMS
//
//  Created by 张敏超 on 2017/12/27.
//  Copyright © 2017年 feeyo. All rights reserved.
//

import UIKit

public extension UIResponder {
    func router(eventKey: String, userInfo: [String: AnyObject]) {
        next?.router(eventKey: eventKey, userInfo: userInfo)
    }
}

public protocol FGTableViewCellModelProtocol {
    var cellHeight: CGFloat? {get set}
    var reusableIdentifier: String? {get}
    var cellClass: FGTableViewCellProtocol.Type {get}
    var xibBunlde: Bundle? { get }
}

public extension FGTableViewCellModelProtocol {
    var xibBunlde: Bundle? {
        return nil
    }
}

public protocol FGTableViewCellProtocol {
    init(reuseIdentifier identifier: String)
    func config(cellModel: FGTableViewCellModelProtocol, atIndexPath indexPath: IndexPath)
    static func cellHeight(cellModel: FGTableViewCellModelProtocol) -> CGFloat
}

public final class FGCellFactory {

	public static func tableView(_ tableView: UITableView, cellForCellModel cellModel: FGTableViewCellModelProtocol, atIndexPath indexPath: IndexPath) -> FGTableViewCellProtocol {
		let identifier = cellModel.reusableIdentifier ?? "\(cellModel.cellClass)"

		var reusableCell = tableView.dequeueReusableCell(withIdentifier: identifier) as? FGTableViewCellProtocol
		if reusableCell == nil {
			if let xibBundle = cellModel.xibBunlde {
				reusableCell = xibBundle.loadNibNamed(identifier, owner: nil, options: nil)?.last as? FGTableViewCellProtocol
			} else {
				reusableCell = cellModel.cellClass.init(reuseIdentifier: identifier)
			}
		}
		reusableCell?.config(cellModel: cellModel, atIndexPath: indexPath)
        return reusableCell!
    }

    public static func tableView(_ tableView: UITableView, heightForCellModel cellModel: FGTableViewCellModelProtocol) -> CGFloat {
        var cellModel = cellModel
        if cellModel.cellHeight == nil {
            let height = cellModel.cellClass.cellHeight(cellModel: cellModel)
            cellModel.cellHeight = height
        }
        return cellModel.cellHeight!
    }

}
