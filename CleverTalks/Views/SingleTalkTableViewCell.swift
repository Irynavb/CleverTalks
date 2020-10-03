//
//  SingleTalkTableViewCell.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 10/3/20.
//

import UIKit
import SDWebImage

class SingleTalkTableViewCell: UITableViewCell {

    static let identifier = "SingleTalkTableViewCell"

    private let userImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = 50
        $0.layer.masksToBounds = true
    }

    private let userNameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 21, weight: .semibold)
    }

    private let userMessageLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 19, weight: .regular)
        $0.numberOfLines = 0
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier reuseidentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseidentifier)

        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)

    }

    override func layoutSubviews() {
        super.layoutSubviews()

        userImageView.frame = CGRect(x: 10, y: 10, width: 100, height: 100)

        userNameLabel.frame = CGRect(x: userImageView.right + 10, y: 10, width: contentView.width - 20 - userImageView.width, height: (contentView.height - 20) / 2)

        userMessageLabel.frame = CGRect(x: userImageView.right + 10, y: userNameLabel.bottom + 10, width: contentView.width - 20 - userImageView.width, height: (contentView.height - 20) / 2)
    }

    func configure(with model: Talk) {
        self.userMessageLabel.text = model.latestMessage.text
        self.userNameLabel.text = model.name

        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("failed to get the image url: \(error)")
            }
        })

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
