//
//  GridView.swift
//  FGBase
//
//  Created by kun wang on 2019/11/27.
//

import UIKit
import SnapKit

public class SimpleGridView: UIStackView {
    private let totalCount: Int
    private let column: Int
    private let row: Int

    private var cells = [TwoLabelItemView]()

    public var titleConfig: GridLabelConfig? {
        didSet {
            if let temp = titleConfig {
                cells.forEach { view in
                    view.titleConfig = temp
                }
            }
        }
    }

    public var contentConfig: GridLabelConfig? {
        didSet {
            if let temp = contentConfig {
                cells.forEach { view in
                    view.contentConfig = temp
                }
            }
        }
    }


    public init(totalCount: Int, column: Int) {
        self.totalCount = totalCount
        self.column = column
        self.row = totalCount%column == 0 ? (totalCount/column) : ((totalCount/column) + 1)

        super.init(frame: .zero)

        if totalCount <= column {
            axis = .horizontal
            distribution = .fillEqually
            for _ in 0..<totalCount {
                let view = TwoLabelItemView()
                cells.append(view)
                addArrangedSubview(view)
            }
        } else {
            axis = .vertical
            distribution = .fillEqually
            for _ in 0..<row {
                let stackRow = UIStackView()
                stackRow.axis = .horizontal
                stackRow.distribution = .fillEqually

                for _ in 0..<column {
                    let view = TwoLabelItemView()
                    cells.append(view)
                    stackRow.addArrangedSubview(view)
                }
                addArrangedSubview(stackRow)
            }
        }
    }

    public func reload(data: [(title: String, content: String)]) {
        for (index, view) in cells.enumerated() {
            if index >= data.count {
                view.topLabel.text = nil
                view.bottomLabel.text = nil
            } else {
                let item = data[index]
                view.topLabel.text = item.title
                view.bottomLabel.text = item.content
            }
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public struct GridLabelConfig {
    public let textColor: UIColor
    public let font: UIFont
    public let alignment: NSTextAlignment

    public init(textColor: UIColor, font: UIFont, alignment: NSTextAlignment) {
        self.textColor = textColor
        self.font = font
        self.alignment = alignment
    }
}

class TwoLabelItemView: UIView {
    var titleConfig = GridLabelConfig(textColor: UIColor(red: 0.608, green: 0.608, blue: 0.608, alpha: 1),
                                  font: .systemFont(ofSize: 13),
                                  alignment: .center) {
        didSet {
            self.topLabel.textColor = titleConfig.textColor
            self.topLabel.font = titleConfig.font
            self.topLabel.textAlignment = titleConfig.alignment
        }
    }
    var contentConfig = GridLabelConfig(textColor: UIColor(red: 0.259, green: 0.259, blue: 0.259, alpha: 1),
                                    font: .systemFont(ofSize: 14),
                                    alignment: .center) {
        didSet {
            self.bottomLabel.textColor = contentConfig.textColor
            self.bottomLabel.font = contentConfig.font
            self.bottomLabel.textAlignment = contentConfig.alignment
        }
    }

    var space: CGFloat = 10 {
        didSet {
            bottomLabel.snp.updateConstraints { make in
                make.top.equalTo(self.snp.bottom).dividedBy(2).offset(space/2)
            }

            topLabel.snp.updateConstraints { make in
                make.bottom.equalToSuperview().dividedBy(2).offset(-space/2)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(topLabel)
        addSubview(bottomLabel)
        topLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().dividedBy(2).offset(-5)
        }

        bottomLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.snp.bottom).dividedBy(2).offset(5)
        }

        topLabel.setContentHuggingPriority(.required, for: .vertical)
        bottomLabel.setContentHuggingPriority(.required, for: .vertical)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var topLabel: UILabel = {
        let label = UILabel()
        label.font = self.titleConfig.font
        label.textColor = self.titleConfig.textColor
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.textAlignment = self.titleConfig.alignment
        return label
    }()

    lazy var bottomLabel: UILabel = {
        let label = UILabel()
        label.font = self.contentConfig.font
        label.textColor = self.contentConfig.textColor
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.textAlignment = self.contentConfig.alignment
        return label
    }()
}
