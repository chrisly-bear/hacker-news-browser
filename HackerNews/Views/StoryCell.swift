//
//  TableViewCell.swift
//  HackerNews
//
//  Created by Kenichi Fujita on 11/21/19.
//  Copyright © 2019 Kenichi Fujita. All rights reserved.
//

import UIKit
import Kingfisher

protocol StoryCellDelegate: class {
    func storyCellCommentButtonTapped(_ cell: StoryCell)
}

class StoryCell: UITableViewCell {
    
    weak var delegate: StoryCellDelegate?
    var story: Story?
    
    private let storyTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.clipsToBounds = true
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        label.font = UIFont.preferredFont(forTextStyle: .title3)
        return label
    }()
    
    private let storyInfoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.clear
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let commentButton: UIButton = {
        let commentButton = UIButton(type: .custom)
        commentButton.setTitleColor(.label, for: .normal)
        commentButton.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        commentButton.translatesAutoresizingMaskIntoConstraints = false
        commentButton.setContentHuggingPriority(.required, for: .horizontal)
        let commentButtonImage = UIImage(named: "commentButtonImage")?.withRenderingMode(.alwaysTemplate)
        commentButton.tintColor = .label
        commentButton.setBackgroundImage(commentButtonImage, for: .normal)
        return commentButton
    }()
    
    public let faviconImageView: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.heightAnchor.constraint(equalToConstant: 60).isActive = true
        image.widthAnchor.constraint(equalToConstant: 60).isActive = true
        image.layer.cornerRadius = 10
        image.clipsToBounds = true
        image.layer.borderWidth = 0.5
        image.layer.borderColor = UIColor.gray.cgColor
        return image
    }()
    
    public let hostLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 1
        label.font = UIFont.preferredFont(forTextStyle: .body)
        return label
    }()
    
    public let vStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .fill
        stackView.axis = .vertical
        stackView.spacing = 4
        return stackView
    }()
    
    public let hStack: UIStackView = {
       let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.spacing = 12
        return stackView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.systemBackground
        contentView.addSubview(hStack)
        
        hStack.addArrangedSubview(faviconImageView)
        hStack.addArrangedSubview(vStack)
        hStack.addArrangedSubview(commentButton)
        
        commentButton.addTarget(self, action: #selector(commentButtonTapped(_:)), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            hStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func configure(with story: Story) {
        self.story = story
        storyInfoLabel.text = story.info
        storyTitleLabel.text = story.title
        commentButton.setTitle(String(story.descendants), for: .normal)
        if let storyURL = story.url {
            hostLabel.text = URL(string: storyURL)?.hostWithoutWWW
        }
        vStack.replaceArrangedSubviews(with: [hostLabel, storyTitleLabel, storyInfoLabel].filter { $0.text != nil })
        if let storyURL = story.url, let host = URL(string: storyURL)?.host {
            StoryImageInfoStore.shared.iconImageURL(url: storyURL, host: host) { (url) in
                if let url = url {
                    self.setImage(url: url, story: story)
                } else {
                    guard let desiredURL = self.story?.url, desiredURL == story.url else { return }
                    self.faviconImageView.image = story.defaultTouchIcon()
                }
            }
        } else {
            self.faviconImageView.image = story.defaultTouchIcon()
            return
        }
    }
    
    private func setImage(url: URL, story: Story) {
        KingfisherManager.shared.retrieveImage(with: url) { (result) in
            switch result {
            case .success(let value):
                guard let desiredURL = self.story?.url,
                    desiredURL == story.url else { return }
                let image = value.image as UIImage
                if image.size.height < 64 {
                    self.faviconImageView.image = story.defaultTouchIcon()
                    return
                }
                self.faviconImageView.image = value.image as UIImage
            case .failure(_):
                guard let desiredURL = self.story?.url,
                    desiredURL == story.url else { return }
                self.faviconImageView.image = story.defaultTouchIcon()
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        storyInfoLabel.text = nil
        storyTitleLabel.text = nil
        commentButton.setTitle(nil, for: .normal)
        faviconImageView.image = nil
        hostLabel.text = nil
    }
    
    @objc func commentButtonTapped(_ sende: UIButton) {
        delegate?.storyCellCommentButtonTapped(self)
    }
    
}

extension UIStackView {
    
    func replaceArrangedSubviews(with views: [UIView]) {
        if arrangedSubviews == views {
            return
        }
        
        arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        views.forEach {
            addArrangedSubview($0)
        }
    }
}

extension Story {
    
    func defaultTouchIcon() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let actions: (UIGraphicsRendererContext) -> Void = { context in
            let fillSize = CGRect(x: 0, y: 0, width: 40, height: 40)
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 15),
                                                             .foregroundColor: UIColor.white]
            self.backgroundColorForTouchIcon.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
            self.textForTouchIcon.drawVerticallyCentered(in: fillSize, attributes: attributes)
        }
        return UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40), format: format).image(actions: actions)
    }
    
    private var textForTouchIcon: String {
        guard let urlString = self.url, let host = URL(string: urlString)?.hostWithoutWWW, let initial = host.first else {
            switch self.type {
            case .normal:
                return "HN"
            case .ask:
                return "Ask"
            case .show:
                return "Show"
            }
        }
        return String(initial.uppercased())
    }
    
    private var backgroundColorForTouchIcon: UIColor {
        if let storyURL = self.url, let url = URL(string: storyURL), let host = url.hostWithoutWWW {
            return .customColor(for: host)
        } else {
            return .systemOrange
        }
    }
}

extension String {
    func drawVerticallyCentered (in rect: CGRect, attributes: [NSAttributedString.Key: Any]?) {
        let attributedString = NSAttributedString(string: self, attributes: attributes)
        let textSize = attributedString.size()
        let center = CGPoint(x: (rect.width - textSize.width)/2, y: (rect.height - textSize.height)/2)
        attributedString.draw(at: center)
    }
}

extension URL {
    var hostWithoutWWW: String? {
        guard let host = self.host else {
            return nil
        }
        if host.prefix(4) == "www." {
            guard let indexOfDot = host.firstIndex(of: ".") else {
                return host
            }
            var host = host
            host.removeSubrange(host.startIndex...indexOfDot)
            return host
        }
        return host
    }
}

extension UIColor {
    static func customColor(for text: String) -> UIColor {
        if let initial = text.first, let asciiValue = Character(initial.lowercased()).asciiValue {
            let colorName = "customColor" + String(Int(asciiValue) % 9)
            if let colorName = UIColor.init(named: colorName) {
                return colorName
            }
        }
        return .systemYellow
    }
}
