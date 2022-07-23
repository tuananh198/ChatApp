//
//  NewConversationCell.swift
//  ChatApp
//
//  Created by iOSTeam on 21/07/2022.
//

import Foundation
import SDWebImage

class NewConversationCell: UITableViewCell {
    
    static let identifier = "NewConversationViewCell"
    
    let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 50
        return imageView
    }()
    
    var userNameLabel: UILabel = {
        let userNameLabel = UILabel()
        userNameLabel.font = .systemFont(ofSize: 21, weight: .semibold)
        return userNameLabel
    }()

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
        
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 100,
                                     height: 100)
        
        userNameLabel.frame = CGRect(x: userImageView.frame.width + 20,
                                     y: 10,
                                     width: contentView.frame.width - 20 - userImageView.frame.width,
                                     height: (contentView.frame.height - 20)/2)
        
    }
    
    //Set Image cho User Avatar
    func configure(model: SearchResult) {
        self.userNameLabel.text = model.name
        let path = "images/\(model.email)-profile-picture.png"
        StorageManager.share.getUrlProfilePicture(path: path) { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}

