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
 
    let items: [AspectRatioButtonItem]
    
    private var stackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.spacing = Constants.minButtonsSpacing
        return view
    }()
    
    init(items: [AspectRatioButtonItem]) {
        self.items = items
        super.init(frame: .zero)
        
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
            let button = AspectRatioButton()
            button.setTitle(item.title, for: .normal)
            button.isSelected = item.isSelected
            stackView.addArrangedSubview(button)
        }
    }
}


