//
//  LoginViewController.swift
//  ChatApp
//
//  Created by iOSTeam on 05/07/2022.
//

import UIKit
import FirebaseAuth
import Firebase
import FBSDKLoginKit
import JGProgressHUD

class LoginViewController: UIViewController {
    
    let hub = JGProgressHUD(style: .dark)

    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 2
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email address..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        return field
    }()
    
    let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 2
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.isSecureTextEntry = true
        return field
    }()
    
    let buttonLogin: UIButton = {
        let button = UIButton()
        button.setTitle("Login", for: .normal)
        button.backgroundColor = .link
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.addTarget(self, action: #selector(loginButtonClicked), for: .touchUpInside)
        return button
    }()
    
    let fbLoginButton: FBLoginButton = {
        let fbLoginButton = FBLoginButton()
        fbLoginButton.permissions = ["public_profile", "email"]
        fbLoginButton.backgroundColor = .link
        fbLoginButton.layer.cornerRadius = 12
        fbLoginButton.layer.masksToBounds = true
        fbLoginButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return fbLoginButton
    }()
    
    @objc func loginButtonClicked() {
        if emailField.text == "" || passwordField.text == "" {
            showSimpleAlert(messeger: "Email and Password cannot be left blank")
        } else {
            
            hub.show(in: view)
            
            guard let email = emailField.text,
                  let password = passwordField.text else {
                return
            }
            
            Auth.auth().signIn(withEmail: email,
                               password: password) { [weak self] authResult, error in
                guard let self = self else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.hub.dismiss()
                }
                
                guard let authResult = authResult, error == nil else {
                    print("Failed to login with email: \(email): \(error!)")
                    return
                }
                
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    
                    let safeEmail = DatabaseManager.share.safeEmail(emailAddress: email)
                    
                    DatabaseManager.share.getDataFor(path: "\(safeEmail)") { result in
                        switch result {
                        case .failure(let error):
                            print("Failed to get Name's User Login by Email: \(error)")
                        case .success(let result):
                            guard let userData = result as? [String: Any],
                                    let firstName = userData["firstName"] as? String,
                                    let lastName = userData["lastName"] as? String else {
                                return
                            }
                            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                            UserDefaults.standard.set(email, forKey: "email")
                        }
                    }
                    
                    self.navigationController?.dismiss(animated: true)
                }
            }
        }
    }
    
    func showSimpleAlert(messeger: String) {
        let alert = UIAlertController(title: messeger, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.fbLoginButton.delegate = self
        title = "Login"
        view.backgroundColor = .white
    
        let layoutConstraintsArr = fbLoginButton.constraints
        for lc in layoutConstraintsArr {
            if lc.constant == 28 {
                lc.isActive = false
                break
            }
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(registerClicked))
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(buttonLogin)
        scrollView.addSubview(fbLoginButton)
    }
    
    @objc func registerClicked() {
        let vc = RegisterViewController()
        vc.title = "Register"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let size = scrollView.frame.width/4
        imageView.frame = CGRect(x: (scrollView.frame.size.width - size)/2, y: 20, width: size, height: size)
        emailField.frame = CGRect(x: 30, y: imageView.frame.size.height + imageView.frame.origin.y + 30, width: scrollView.frame.size.width - 60, height: 52)
        passwordField.frame = CGRect(x: 30, y: emailField.frame.size.height + emailField.frame.origin.y + 10, width: emailField.frame.size.width, height: emailField.frame.size.height)
        buttonLogin.frame = CGRect(x: 30, y: passwordField.frame.size.height + passwordField.frame.origin.y + 10, width: emailField.frame.size.width, height: emailField.frame.size.height)
        fbLoginButton.frame = CGRect(x: 30, y: buttonLogin.frame.size.height + buttonLogin.frame.origin.y + 10, width: emailField.frame.size.width, height: 52)
    }

}

// MARK: - Get thông tin sau khi login bằng Facebook sau đó lưu thông tin vào RealTime Database

extension LoginViewController: LoginButtonDelegate {
    
    func loginButton(_ loginButton: FBLoginButton,
                     didCompleteWith result: LoginManagerLoginResult?,
                     error: Error?) {
        guard let token = result?.token?.tokenString else {
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email, name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start(completion: { [weak self] _, result, error in
            guard let self = self else {
                return
            }
            guard let result = result as? [String: Any], error == nil else {
                return
            }
            
            let email = result["email"] as? String
            
            let fullName = result["name"] as? String
            
            let picture = result["picture"] as? [String: Any]
            let data = picture?["data"] as? [String: Any]
            guard let urlProfileImage = data?["url"] as? String else {
                print("Can not get url profile image from facebook")
                return
            }
            
            guard email != nil, fullName != nil else {
                return
            }
            
            let fullNameArr = fullName?.components(separatedBy: " ")
            let firstName = fullNameArr![0]
            var lastName = ""
            
            if fullNameArr!.count > 1 {
                lastName = fullNameArr![fullNameArr!.count - 1]
            }
            
            let cridental = FacebookAuthProvider.credential(withAccessToken: token)
            
            FirebaseAuth.Auth.auth().signIn(with: cridental) { authResult, error in
                guard authResult != nil, error == nil else {
                    print("Unable to authenticate your account")
                    return
                }
                
                UserDefaults.standard.set(email, forKey: "email")
                UserDefaults.standard.set(fullName, forKey: "name")

                DatabaseManager.share.userExist(email: email!) { exist in
                    guard !exist else {
                        return
                    }
                    
                    let chatUser = ChapAppUser(firstName: firstName,
                                               lastName: lastName,
                                               emailAddress: email!)
                    
                    DatabaseManager.share.insertUser(user: chatUser)
                    { success in
                        
                        if success {
                            guard let url = URL(string: urlProfileImage) else {
                                print("Can't parse url")
                                return
                            }
                            
                            let fileName = chatUser.profilePicture
                            
                            URLSession.shared.dataTask(with: url) { data, _, _ in
                                
                                guard let data = data else {
                                    print("Cannot download image from url Facebook")
                                    return
                                }
                                
                                StorageManager.share.uploadProfilePicture(data: data,
                                                                          fileName: fileName)
                                { result in
                                    switch result {
                                    case .success(let downloadURL):
                                        print("Yayy. Image uploaded. Url: \(downloadURL)")
                                    case .failure(let error):
                                        print("Error: \(error)")
                                    }
                                }
                            }.resume()
                        }
                    }
                }
                self.navigationController?.dismiss(animated: true)
            }
        })
        
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        
    }
    
    
}
