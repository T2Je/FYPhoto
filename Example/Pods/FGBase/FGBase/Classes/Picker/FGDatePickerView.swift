//
//  FGDatePickerView.swift
//  FYACDM
//
//  Created by 肖扬 on 2017/10/24.
//  Copyright © 2017年 feeyo. All rights reserved.
//

import Foundation

public class FGDatePickerView: UIView {
    /// selected date
    public var date: Date {
        return datePicker.date
    }

    private var cancelButton: UIBarButtonItem?
    private var doneButton: UIBarButtonItem?

    private let animationInterval = 0.3

    private var toolBarHeight: CGFloat = 44.0
    private var datePickerViewHeight: CGFloat = 216
    private var totalHeight: CGFloat {
        return toolBarHeight + datePickerViewHeight
    }
    var indexPath: IndexPath?

    lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker(frame: CGRect(x: 0, y: toolBarHeight, width: UIScreen.main.bounds.width, height: datePickerViewHeight))
        datePicker.backgroundColor = .white
        datePicker.datePickerMode = mode
        datePicker.alpha = 0
        datePicker.locale = NSLocale.current
        datePicker.maximumDate = Date(timeInterval: 24*3600, since: Date())
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        return datePicker
    }()

    lazy var headerView: FGDatePickerHeaderView = {
        let headerView = FGDatePickerHeaderView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: toolBarHeight))
        //        headerView.backgroundColor = UIColor(hex: 0xddf0ed)
        headerView.alpha = 0
        return headerView
    }()

    private var cancelBlock: (() -> Void)?
    private var confirmBlock: ((Date) -> Void)?

    //    public static let shared = FGDatePickerView()
    private let mode: UIDatePicker.Mode

    // MARK: - Init
    public init(mode: UIDatePicker.Mode = .dateAndTime, frame: CGRect = .zero) {
        self.mode = mode
        super.init(frame: frame)

        self.addSubview(datePicker)
        self.addSubview(headerView)

        headerView.cancelBlock = { [weak self] in
            guard let self = self else { return }
            self.hide()
            self.cancelBlock?()
        }

        headerView.confirmBlock = { [weak self] in
            guard let self = self else { return }
            self.hide()
            self.confirmBlock?(self.date)
        }
    }


    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //    @objc func datePickerValueChanged(_ datePicker: UIDatePicker) {
    //        //        print("date %@", datePicker.date)
    //    }

    // MARK: - Setter
    public func setHeaderViewBackgroundColor(_ color: UIColor) {
        headerView.backgroundColor = color
        setNeedsDisplay()
    }

    public func setCancelButtonText(_ text: String?) {
        headerView.cancelButton.setTitle(text, for: .normal)
        setNeedsDisplay()
    }

    public func setCancelButtonFont(_ font: UIFont) {
        headerView.cancelButton.titleLabel?.font = font
        setNeedsDisplay()
    }

    public func setConfirmButtonTextColor(_ color: UIColor) {
        headerView.confirmButton.setTitleColor(color, for: .normal)
        setNeedsDisplay()
    }

    public func setConfirmButtonText(_ text: String?) {
        headerView.confirmButton.setTitle(text, for: .normal)
        setNeedsDisplay()
    }

    public func setConfirmButtonFont(_ font: UIFont) {
        headerView.confirmButton.titleLabel?.font = font
        setNeedsDisplay()
    }

    public func setConfirmButtonBackgroundColor(_ color: UIColor) {
        headerView.confirmButton.backgroundColor = color
        setNeedsDisplay()
    }

    public func setConfirmButtonCornerRadius(_ cornerRadius: CGFloat) {
        headerView.confirmButton.layer.cornerRadius = cornerRadius
        setNeedsDisplay()
    }

    public func setTitle(_ title: String) {
        headerView.titleLabel.text = title
        setNeedsDisplay()
    }

    public func setTitleFont(_ font: UIFont) {
        headerView.titleLabel.font = font
        setNeedsDisplay()
    }

    public func setTitleTextColor(_ color: UIColor) {
        headerView.titleLabel.textColor = color
        setNeedsDisplay()
    }

    public func setHeaderViewSeparatorLineIsHidden(_ isHidden: Bool) {
        headerView.line.isHidden = isHidden
        setNeedsDisplay()
    }

    public func setSelectedDate(_ date: Date) {
        datePicker.date = date
        setNeedsDisplay()
    }

    public func setMaximumDate(_ date: Date = Date(timeInterval: 24*3600, since: Date())) {
        datePicker.maximumDate = date
        setNeedsDisplay()
    }

    // MARK: - Present
    public func showDatePicker(inView containerView: UIView, cancelBlock: (() -> Void)?, confirmBlock: @escaping ((Date) -> Void)) {
        if containerView.subviews.contains(self) {
            self.removeFromSuperview()
        }
        containerView.addSubview(self)
        self.cancelBlock = cancelBlock
        self.confirmBlock = confirmBlock

        self.frame = CGRect(x: containerView.bounds.origin.x, y: containerView.bounds.size.height, width: containerView.bounds.size.width, height: totalHeight)
        self.headerView.frame = CGRect(x: 0, y: 0, width: containerView.bounds.size.width, height: toolBarHeight)

        UIView.animate(withDuration: animationInterval, animations: {
            self.datePicker.alpha = 1
            self.headerView.alpha = 1
            self.frame = CGRect(x: 0, y: containerView.bounds.size.height - self.totalHeight, width: containerView.bounds.size.width, height: self.totalHeight)
        })
    }

    public func hide() {
        UIView.animate(withDuration: animationInterval, animations: {
            self.datePicker.alpha = 0
            self.headerView.alpha = 0
            //            self.height = 0
            guard let superV = self.superview else {
                return
            }
            self.frame = CGRect(x: 0, y: superV.frame.height, width: superV.frame.width, height: self.frame.height)
        }, completion: { (_) in
            if self.superview != nil {
                self.removeFromSuperview()
            }
        })
    }

}

internal class FGDatePickerHeaderView: UIView {
    let cancelButton = UIButton()
    let confirmButton = UIButton()

    let titleLabel = UILabel()

    let line = UIView()

    var confirmBlock: (() -> Void)?
    var cancelBlock: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(cancelButton)
        addSubview(confirmButton)
        addSubview(titleLabel)
        addSubview(line)

        cancelButton.setTitle("Cancel".baseTablelocalized, for: .normal)
        confirmButton.setTitle("Confirm".baseTablelocalized, for: .normal)

        cancelButton.setTitleColor(UIColor.lightGray, for: .normal)
        confirmButton.setTitleColor(FGUIConfiguration.shared.navBGColor, for: .normal)

        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)

        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.textAlignment = .center

        cancelButton.addTarget(self, action: #selector(cancelButtonClicked(_:)), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmButtonClicked(_:)), for: .touchUpInside)

        line.backgroundColor = UIColor(hexString: "#DEDEDE")
        line.isHidden = true
        updateSubViewsFrame()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func cancelButtonClicked(_ sender: UIBarButtonItem) {
        if let cancel = cancelBlock {
            cancel()
        }
    }

    @objc func confirmButtonClicked(_ sender: UIBarButtonItem) {
        if let confirm = confirmBlock {
            confirm()
        }
    }

    override var frame: CGRect {
        didSet {
            updateSubViewsFrame()
        }
    }

    func updateSubViewsFrame() {
        cancelButton.frame = CGRect(x: 0, y: 0, width: 70, height: frame.size.height)
        confirmButton.frame = CGRect(x: frame.size.width - 10 - 60, y: 10, width: 60, height: frame.size.height - 20)

        titleLabel.frame = CGRect(x: 70, y: 0, width: frame.size.width - 70 - 70, height: frame.size.height)
        line.frame = CGRect(x: 0, y: frame.size.height - 0.5, width: frame.width, height: 0.5)
    }
}
