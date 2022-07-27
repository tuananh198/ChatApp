//
//  ConversationViewController.swift
//  ChatApp
//
//  Created by iOSTeam on 05/07/2022.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class ConversationViewController: UIViewController {
    
    var conversations = [Conversation]()
    
    let tableView: UITableView = {
        let tableview = UITableView()
        tableview.isHidden = true
        tableview.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return tableview
    }()
    
    let noConversationLabel: UILabel = {
        let noConversationLabel = UILabel()
        noConversationLabel.text = "No Conversations!"
        noConversationLabel.textAlignment = .center
        noConversationLabel.textColor = .lightGray
        noConversationLabel.font = .systemFont(ofSize: 21, weight: .medium)
        return noConversationLabel
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(composeButtonClicked))
        view.addSubview(tableView)
        view.addSubview(noConversationLabel)
        tableView.delegate = self
        tableView.dataSource = self
        startListeningConversations()
    }
    
    func startListeningConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.share.safeEmail(emailAddress: email)
        DatabaseManager.share.getAllConversation(email: safeEmail) { [weak self] result in
            switch result {
            case .success(let conversations):
                guard conversations.isEmpty else {
                    self?.tableView.isHidden = false
                    self?.noConversationLabel.isHidden = true
                    self?.conversations = conversations
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                    return
                }
                self?.tableView.isHidden = true
                self?.noConversationLabel.isHidden = false
            case .failure(let error):
                print("Get All conversation Fail or No conversation match with Email: \(error)")
            }
            
        }
    }
    
    //Click button Tìm kiếm User
    @objc func composeButtonClicked() {
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            guard let self = self else {
                return
            }
            
            let currentConversation = self.conversations
            //Nếu Email trả về khi select User tìm được ở màn search trùng với otherEmail trong list conversation hiện tại thì không tạo mới Conversation
            if let targetConversation = currentConversation.first(where: {
                $0.otherEmail == DatabaseManager.share.safeEmail(emailAddress: result.email)
            }) {
                let vc = ChatViewController(otherUserEmail: targetConversation.otherEmail,
                                            id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: true)
                
            } else {
                self.createNewConversation(result: result)
            }
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    func createNewConversation(result: SearchResult) {
        let name = result.name
        let email = DatabaseManager.share.safeEmail(emailAddress: result.email)
        
        DatabaseManager.share.conversationExist(targetRecipientEmail: email) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .failure(_):
                let vc = ChatViewController(otherUserEmail: email, id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: true)
            case .success(let conversationID):
                let vc = ChatViewController(otherUserEmail: email, id: conversationID)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        validateAuth()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noConversationLabel.frame = CGRect(x: 0,
                                           y: (view.frame.size.height - 100)/2,
                                           width: view.frame.size.width,
                                           height: 100)
    }
    
    func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    
    func fetchData() {
        tableView.isHidden = false
    }
}

//MARK: - Setup data for table view in Conversation Screen

extension ConversationViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier,
                                                 for: indexPath) as! ConversationTableViewCell
        cell.configure(model: model)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        openConversation(model: model)
    }
    
    func openConversation(model: Conversation) {
        let vc = ChatViewController(otherUserEmail: model.otherEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let conversation = conversations[indexPath.row]
            let conversationID = conversation.id
            DatabaseManager.share.deleteConversation(conversationID: conversationID) { [weak self] result in
                if result {
                    self?.conversations.remove(at: indexPath.row)
                    self?.tableView.beginUpdates()
                    self?.tableView.deleteRows(at: [indexPath], with: .left)
                    self?.tableView.endUpdates()
                    if self?.conversations.count == 0 {
                        self?.tableView.isHidden = true
                        self?.noConversationLabel.isHidden = false
                    }
                } else {
                    print("Delete conversation fail")
                }
            }
        }
    }
    
}

