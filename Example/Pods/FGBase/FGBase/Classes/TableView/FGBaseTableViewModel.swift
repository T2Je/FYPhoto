//
//  FGBaseTableViewModel.swift
//  FYGOMS
//
//  Created by 张敏超 on 2017/12/28.
//  Copyright © 2017年 feeyo. All rights reserved.
//

import UIKit

public protocol FGBaseTableViewModelDelegate: class {
    func cellFactoryCreateCell(cell: UITableViewCell, atIndexPath indexPath: IndexPath)
}

open class FGBaseTableViewModel: NSObject, UITableViewDataSource, UITableViewDelegate {
    open weak var delegate: FGBaseTableViewModelDelegate?

    open var cellModels = [FGTableViewCellModelProtocol]()

    open var didSelectRow: ((IndexPath, FGTableViewCellModelProtocol) -> Void)?

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellModels.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = FGCellFactory.tableView(tableView, cellForCellModel: cellModels[indexPath.row], atIndexPath: indexPath) as? UITableViewCell
        self.delegate?.cellFactoryCreateCell(cell: cell!, atIndexPath: indexPath)
        return cell!
    }

    open func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return FGCellFactory.tableView(tableView, heightForCellModel: cellModels[indexPath.row])
    }

    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return FGCellFactory.tableView(tableView, heightForCellModel: cellModels[indexPath.row])
    }

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRow?(indexPath, cellModels[indexPath.row])
    }
}
