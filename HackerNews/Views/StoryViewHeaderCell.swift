//
//  StoryViewHeaderCellTableViewCell.swift
//  HackerNews
//
//  Created by Kenichi Fujita on 1/12/20.
//  Copyright © 2020 Kenichi Fujita. All rights reserved.
//

import UIKit

protocol StoryViewHeaderCellDelegate: AnyObject {
    func StoryViewHeaderCellHostButtonTapped(_ cell: StoryViewHeaderCell)
}

class StoryViewHeaderCell: UITableViewCell {
    
    private let htmlView: HTMLView = HTMLView(frame: CGRect.zero)
    weak var delegate: StoryViewHeaderCellDelegate?
    
    private let storyTitleLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = UIFont.preferredFont(forTextStyle: .title3).bold()
        return label
    }()
    
    private let hostButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.systemBlue, for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.contentHorizontalAlignment = .left
        button.heightAnchor.constraint(equalToConstant: 20).isActive = true
        return button
    }()
    
    private let storyInfoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.clear
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.textColor = .secondaryLabel
        label.heightAnchor.constraint(equalToConstant: 20).isActive = true
        return label
    }()
    
    private let vStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()
    
    private let ogImageView: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.borderColor = UIColor.systemGray2.cgColor
        image.layer.borderWidth = 1
        image.layer.cornerRadius = 10
        return image
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        contentView.addSubview(vStack)
        vStack.addArrangedSubview(storyTitleLabel)
        vStack.addArrangedSubview(hostButton)
        vStack.addArrangedSubview(storyInfoLabel)
        vStack.addArrangedSubview(ogImageView)
        vStack.addArrangedSubview(htmlView)
        
        hostButton.addTarget(self, action: #selector(hostButtonTapped(_:)), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            vStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            vStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            vStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            vStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15),
            
            ogImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 175),
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureStory (with story: Story, image: UIImage?) {
        storyTitleLabel.text = story.title
        storyInfoLabel.text = story.info
        if let image = image {
            ogImageView.image = image
        } else {
            ogImageView.removeFromSuperview()
        }
        if let urlString = story.url, let url = URL(string: urlString) {
            hostButton.setTitle(url.hostWithoutWWW, for: .normal)
        } else {
            hostButton.removeFromSuperview()
        }
        if let storyText = story.text {
            htmlView.html = storyText
        }
        else {
            htmlView.removeFromSuperview()
        }
    }
    
    @objc func hostButtonTapped(_ sender: UIButton) {
        delegate?.StoryViewHeaderCellHostButtonTapped(self)
    }

}

