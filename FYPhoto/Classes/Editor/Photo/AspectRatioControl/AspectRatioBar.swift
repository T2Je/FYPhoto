//
//  AspectRatioBar.swift
//  FYPhoto
//
//  Created by xiaoyang on 2021/5/6.
//

import UIKit

class AspectRatioBar: UIScrollView {
    private struct Constants {
        static let maxButtonsSpacing: CGFloat = 10.0
        static let minButtonsSpacing: CGFloat = 8.0
        static let minButtonVisibleWidth: CGFloat = 20.0
        static let minButtonWidth: CGFloat = 56.0
        static let minHeight: CGFloat = 28.0
        static let sideInset: CGFloat = 16.0
    }
 
    var didSelectedRatio: ((Double?) -> Void)?
    
    let items: [AspectRatioButtonItem]
    
    private var selectedButton: AspectRatioButton?
    
    private var stackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.spacing = Constants.minButtonsSpacing
        return view
    }()
    
    init(items: [AspectRatioButtonItem]) {
        self.items = items
        super.init(frame: .zero)
        showsHorizontalScrollIndicator = false
        setupStackView()
        addButtonsWithItems(items)
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupStackView() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: frameLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: frameLayoutGuide.bottomAnchor)
        ])
    }
    
    func addButtonsWithItems(_ items: [AspectRatioButtonItem]) {
        
        for item in items {
            let button = AspectRatioButton(item: item)
            button.addTarget(self, action: #selector(buttonClicked(_:)), for: .touchUpInside)
            if item.isSelected {
                selectedButton = button
            }
            stackView.addArrangedSubview(button)
        }
    }
    
    func flip() {
        let pre = stackView.axis
        stackView.axis = (pre == .horizontal) ? .vertical : .horizontal
    }
    
    func reloadItems(_ items: [AspectRatioButtonItem]) {
        stackView.removeFullyAllArrangedSubviews()
        addButtonsWithItems(items)
    }
    
    @objc func buttonClicked(_ sender: AspectRatioButton) {
        
//        items.forEach { $0.isSelected = false }
        
        handleButtonsState(sender)
        didSelectedRatio?(sender.item.ratio)
    }
    
    func handleButtonsState(_ new: AspectRatioButton) {
        if let old = selectedButton {
            if old === new {
                return
            } else {
                old.isSelected = false
                new.isSelected = true
            }
        } else {
            new.isSelected = true
        }
        selectedButton = new
    }
}


