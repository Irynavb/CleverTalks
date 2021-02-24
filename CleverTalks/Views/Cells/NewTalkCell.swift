//
//  NewTalkCell.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 2/23/21.
//

import Foundation
import SDWebImage
import Then

class NewTalkCell: UITableViewCell {

    static let identifier = "NewTalkCell"

    private let userImageView = UIImageView().then {

        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = 35
        $0.layer.masksToBounds = true

    }

    private let userNameLabel = UILabel().then {

        $0.font = .systemFont(ofSize: 21, weight: .semibold)

    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Bubbles view for the talk messages

        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 70,
                                     height: 70)

        userNameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 20,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: 50)
    }

    public func configure(with model: SearchResult) {
        userNameLabel.text = model.name

        let path = "images/\(model.email)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url):

                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }

            case .failure(let error):
                print("failed to get image url: \(error)")
            }
        })
    }
}
