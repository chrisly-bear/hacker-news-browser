//
//  StoryViewCell.swift
//  HackerNews
//
//  Created by Kenichi Fujita on 12/4/19.
//  Copyright © 2019 Kenichi Fujita. All rights reserved.
//

import UIKit

protocol CommentCellDelegate: AnyObject {
    func commentCell(_ commentCell: CommentCell, linkTapped url: URL)
}

class CommentCell: UITableViewCell {
    
    weak var delegate: CommentCellDelegate?
    private var userAndTimeLabelLeadingAnchoConstraint = NSLayoutConstraint()
    private var htmlViewLeadingAnchorConstraint = NSLayoutConstraint()
    private var tier: Int = 0
    
    private let dummyVerticalLeftSeparator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.widthAnchor.constraint(equalToConstant: 1).isActive = true
        return view
    }()
    
    private let dummyVerticalRightSeparator: UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.widthAnchor.constraint(equalToConstant: 0).isActive = true
        return view
    }()
    
    private let htmlView: HTMLView = {
        let htmlView = HTMLView(frame: CGRect.zero)
        htmlView.translatesAutoresizingMaskIntoConstraints = false
        return htmlView
    }()
    
    private let verticalSeparatorStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        return stackView
    }()
    
    private let topHorizontalSeparatorView: UIView = {
        let separatorView = UIView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = .systemGray4
        return separatorView
    }()
    
    private let userAndTimeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.clear
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.textColor = .secondaryLabel
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .systemBackground
        htmlView.delegate = self
        contentView.addSubview(userAndTimeLabel)
        contentView.addSubview(htmlView)
        contentView.addSubview(topHorizontalSeparatorView)
        contentView.addSubview(verticalSeparatorStackView)
        
        NSLayoutConstraint.activate([
            userAndTimeLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            userAndTimeLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            userAndTimeLabel.bottomAnchor.constraint(equalTo: htmlView.topAnchor),
            htmlView.leadingAnchor.constraint(equalTo: userAndTimeLabel.leadingAnchor),
            htmlView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            htmlView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            topHorizontalSeparatorView.topAnchor.constraint         (equalTo: contentView.topAnchor),
            topHorizontalSeparatorView.heightAnchor.constraint      (equalToConstant: 2),
            topHorizontalSeparatorView.leadingAnchor.constraint     (equalTo: contentView.leadingAnchor),
            topHorizontalSeparatorView.trailingAnchor.constraint    (equalTo: contentView.trailingAnchor),
            verticalSeparatorStackView.topAnchor.constraint         (equalTo: contentView.topAnchor),
            verticalSeparatorStackView.leadingAnchor.constraint     (equalTo: contentView.leadingAnchor),
            verticalSeparatorStackView.trailingAnchor.constraint    (equalTo: userAndTimeLabel.leadingAnchor),
            verticalSeparatorStackView.bottomAnchor.constraint      (equalTo: contentView.bottomAnchor)
            ])
        
        userAndTimeLabelLeadingAnchoConstraint = userAndTimeLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor)
        htmlViewLeadingAnchorConstraint = htmlView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor)
        userAndTimeLabelLeadingAnchoConstraint.isActive = true
        htmlViewLeadingAnchorConstraint.isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with comment: Comment) {
        htmlView.html = comment.text
        userAndTimeLabel.text = comment.info
        self.tier = comment.tier
        topHorizontalSeparatorView.isHidden = comment.tier != 0
        addSeparatorView(for: comment.tier)
        self.layoutIfNeeded()
    }
    
    private func addSeparatorView(for tier: Int) {
        verticalSeparatorStackView.addArrangedSubview(dummyVerticalLeftSeparator)
        if tier > 0 {
            for _ in 1...tier {
                let separatorView = UIView()
                separatorView.translatesAutoresizingMaskIntoConstraints = false
                separatorView.backgroundColor = .systemGray4
                separatorView.widthAnchor.constraint(equalToConstant: 1).isActive = true
                verticalSeparatorStackView.addArrangedSubview(separatorView)
            }
        }
        verticalSeparatorStackView.addArrangedSubview(dummyVerticalRightSeparator)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        htmlView.html = nil
        userAndTimeLabel.text = nil
        verticalSeparatorStackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let leftMargin = Int(contentView.directionalLayoutMargins.leading)
        let indent = CGFloat(self.tier * leftMargin)
        userAndTimeLabelLeadingAnchoConstraint.constant = indent
        htmlViewLeadingAnchorConstraint.constant = indent
    }
    
}

extension CommentCell: HTMLViewDelegate {
    func htmlView(_ htmlView: HTMLView, linkTapped url: URL) {
        delegate?.commentCell(self, linkTapped: url)
    }
}
