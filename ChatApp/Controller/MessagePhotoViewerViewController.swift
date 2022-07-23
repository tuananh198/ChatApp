//
//  MessagePhotoViewerViewController.swift
//  ChatApp
//
//  Created by iOSTeam on 21/07/2022.
//

import UIKit

class MessagePhotoViewerViewController: UIViewController {
    
    let url: URL
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Photo"
        navigationItem.largeTitleDisplayMode = .never
        tabBarController?.tabBar.isHidden = true
        imageView.sd_setImage(with: url)
        view.addSubview(imageView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = view.bounds
    }

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
