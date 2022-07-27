//
//  ProfileViewController.swift
//  ChatApp
//
//  Created by iOSTeam on 07/07/2022.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import FirebaseStorage
import SDWebImage

class ProfileViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var data = [ProfileViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Name: \(UserDefaults.standard.value(forKey: "name") ?? "No Name")",
                                     handler: nil))
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Email: \(UserDefaults.standard.value(forKey: "email") ?? "No Email")",
                                     handler: nil))
        data.append(ProfileViewModel(viewModelType: .logout,
                                     title: "Logout",
                                     handler: { [weak self] in
            guard let self = self else {
                return
            }
            
            let loginManager = LoginManager()
            loginManager.logOut()
            
            UserDefaults.standard.setValue(nil, forKey: "email")
            UserDefaults.standard.setValue(nil, forKey: "name")
            
            do {
                try FirebaseAuth.Auth.auth().signOut()
                let vc = LoginViewController()
                
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true)
            } catch {
                print("Failed to logout")
            }
        }))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
    }
    
    func createTableHeader() -> UIView? {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            print("Doesn't exist email in local storage")
            return nil
        }
        let safeEmail = DatabaseManager.share.safeEmail(emailAddress: email)
        let fileName = safeEmail + "-profile-picture.png"
        let path = "images/" + fileName
        
        let headerView = UIView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: view.frame.width,
                                              height: 300))
        headerView.backgroundColor = .link
        
        let imageView = UIImageView(frame: CGRect(x: headerView.frame.width/2 - 75,
                                                  y: headerView.frame.height/2 - 75,
                                                  width: 150,
                                                  height: 150))
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = imageView.frame.width/2
        
        headerView.addSubview(imageView)
        
        StorageManager.share.getUrlProfilePicture(path: path) { [weak self] result in
            guard self != nil else {
                return
            }
            switch result {
            case .failure(let error):
                print("Loading failed url when fetching image data user profile: \(error)")
            case .success(let url):
                imageView.sd_setImage(with: url)
            }
        }
        
        return headerView
    }
    
}

//MARK: - TableView

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row].title
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let viewModel = data[indexPath.row].handler?()
    }
}
