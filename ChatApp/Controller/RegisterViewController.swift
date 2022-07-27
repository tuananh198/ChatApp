//
//  RegisterViewController.swift
//  ChatApp
//
//  Created by iOSTeam on 05/07/2022.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    let hubSpinner = JGProgressHUD(style: .dark)

    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "default-profile-image")
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    let firstNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 2
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "First Name..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        return field
    }()
    
    let lastNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 2
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "First Name..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        return field
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
    
    let buttonRegister: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.addTarget(self, action: #selector(registerButtonClicked), for: .touchUpInside)
        return button
    }()
    
    @objc func registerButtonClicked() {
        if emailField.text == "" || passwordField.text == "" || lastNameField.text == "" || firstNameField.text == "" {
            showSimpleAlert(messeger: "Email and Password,... cannot be left blank")
        } else {
            
            hubSpinner.show(in: view)
            
            guard let email = emailField.text,
                  let password = passwordField.text,
                  let firstName = firstNameField.text,
                  let lastName = lastNameField.text else {
                return
            }
            
            DatabaseManager.share.userExist(email: email) { [weak self] exist in
                guard let self = self else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.hubSpinner.dismiss()
                }

                guard !exist else {
                    self.showSimpleAlert(messeger: "Account already register")
                    return
                }
                
                Auth.auth().createUser(withEmail: email,
                                       password: password)
                { authResult, error in
        
                    guard authResult != nil, error == nil else {
                        print(error!.localizedDescription)
                        return
                    }
                    
                    let chatUser = ChapAppUser(firstName: firstName,
                                               lastName: lastName,
                                               emailAddress: email)
                    
                    let fullNameCurrentUser = "\(firstName) \(lastName)"
                    
                    UserDefaults.standard.set(email, forKey: "email")
                    UserDefaults.standard.set(fullNameCurrentUser, forKey: "name")
                    
                    DatabaseManager.share.insertUser(user: chatUser) { success in
                        if success {
                            //Upload image
                            guard let image = self.imageView.image else {
                                return
                            }
                            guard let data = image.pngData() else {
                                return
                            }
                                
                            let fileName = chatUser.profilePicture
                            StorageManager.share.uploadProfilePicture(data: data,
                                                                      fileName: fileName)
                            { result in
                                switch result {
                                case .success(let downloadURL):
                                    print("Image uploaded. Url: \(downloadURL)")
                                case .failure(let error):
                                    print("Upload Profile Picture Fail: \(error)")
                                }
                            }
                        }
                    }
                    
                    self.navigationController?.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    func showSimpleAlert(messeger: String) {
        let alert = UIAlertController(title: messeger, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Register"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(registerClicked))
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(buttonRegister)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapToImageProfile))
        imageView.addGestureRecognizer(gesture)
    }
    
    @objc func tapToImageProfile() {
        presentPhotoAction()
    }
    
    @objc func registerClicked() {
        let vc = RegisterViewController()
        vc.title = "Register"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.frame.width/4
        imageView.frame = CGRect(x: (scrollView.frame.size.width - size)/2, y: 20, width: size, height: size)
        imageView.layer.cornerRadius = imageView.frame.size.width/2
        firstNameField.frame = CGRect(x: 30, y: imageView.frame.size.height + imageView.frame.origin.y + 30, width: scrollView.frame.size.width - 60, height: 52)
        lastNameField.frame = CGRect(x: 30, y: firstNameField.frame.size.height + firstNameField.frame.origin.y + 10, width: firstNameField.frame.size.width, height: firstNameField.frame.size.height)
        emailField.frame = CGRect(x: 30, y: lastNameField.frame.size.height + lastNameField.frame.origin.y + 10, width: firstNameField.frame.size.width, height: firstNameField.frame.size.height)
        passwordField.frame = CGRect(x: 30, y: emailField.frame.size.height + emailField.frame.origin.y + 10, width: firstNameField.frame.size.width, height: firstNameField.frame.size.height)
        buttonRegister.frame = CGRect(x: 30, y: passwordField.frame.size.height + passwordField.frame.origin.y + 10, width: emailField.frame.size.width, height: emailField.frame.size.height)
    }

}

extension RegisterViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func presentPhotoAction() {
        let action = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture", preferredStyle: .actionSheet)
        action.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        action.addAction(UIAlertAction(title: "Take a Photo", style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        action.addAction(UIAlertAction(title: "Select From Library", style: .default, handler: { [weak self] _ in
            self?.presentLibrary()
        }))
        present(action, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func presentLibrary() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let imageSelected = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        imageView.image = imageSelected
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
    }
}
