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

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = isPortrait ? .horizontal : .vertical
        view.alignment = .center
        view.spacing = Constants.minButtonsSpacing
        return view
    }()

    let isPortrait: Bool
    init(items: [AspectRatioButtonItem], isPortrait: Bool) {
        self.items = items
        self.isPortrait = isPortrait
        super.init(frame: .zero)
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        setupStackView()
        addButtonsWithItems(items)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var stackFrameLayoutGuides: [NSLayoutConstraint] = []
    private func setupStackView() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor)
        ])
        if isPortrait {
            stackFrameLayoutGuides = [
                stackView.heightAnchor.constraint(equalTo: frameLayoutGuide.heightAnchor)
            ]
        } else {
            stackFrameLayoutGuides = [
                stackView.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor)
            ]
        }

        NSLayoutConstraint.activate(stackFrameLayoutGuides)
    }

    func addButtonsWithItems(_ items: [AspectRatioButtonItem]) {
        for item in items {
            let button = AspectRatioButton(item: item)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(buttonClicked(_:)), for: .touchUpInside)
            if item.isSelected {
                selectedButton = button
            }
            stackView.addArrangedSubview(button)
        }

    }

    func flip() {
        stackView.axis = (stackView.axis == .horizontal) ? .vertical : .horizontal

        NSLayoutConstraint.deactivate(stackFrameLayoutGuides)
        if stackView.axis == .horizontal {
            stackFrameLayoutGuides = [
                stackView.heightAnchor.constraint(equalTo: frameLayoutGuide.heightAnchor)
            ]
        } else {
            stackFrameLayoutGuides = [
                stackView.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor)
            ]
        }
        NSLayoutConstraint.activate(stackFrameLayoutGuides)

        stackView.layoutIfNeeded() // fix stackview autolayout warnings after changing axis
    }

    func reloadItems(_ items: [AspectRatioButtonItem]) {
        stackView.removeFullyAllArrangedSubviews()
        addButtonsWithItems(items)
    }

    @objc private func buttonClicked(_ sender: AspectRatioButton) {
        handleButtonsState(sender)
        didSelectedRatio?(sender.item.ratio)
    }

    private func handleButtonsState(_ new: AspectRatioButton) {
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
