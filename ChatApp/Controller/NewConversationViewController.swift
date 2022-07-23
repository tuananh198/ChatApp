//
//  NewConversationViewController.swift
//  ChatApp
//
//  Created by iOSTeam on 12/07/2022.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    //Trả về SearchResult gồm tên và email của user đã chọn
    var completion: ((SearchResult) -> Void)?
    
    let loadingSpinner = JGProgressHUD(style: .dark)
    
    var users = [[String: String]]()
    var result = [SearchResult]()
    var hasFetch = false
    
    let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search user"
        return searchBar
    }()
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(NewConversationCell.self,
                           forCellReuseIdentifier: NewConversationCell.identifier)
        return tableView
    }()
    
    let noResultLabel: UILabel = {
        let noResultLabel = UILabel()
        noResultLabel.isHidden = true
        noResultLabel.text = "No result"
        noResultLabel.textAlignment = .center
        noResultLabel.font = .systemFont(ofSize: 21, weight: .medium)
        noResultLabel.textColor = .green
        return noResultLabel
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        searchBar.delegate = self
        navigationController?.navigationBar.topItem?.titleView = searchBar
        searchBar.becomeFirstResponder()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                            target: self,
                                                            action: #selector(dismissSearch))
        view.addSubview(tableView)
        view.addSubview(noResultLabel)
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultLabel.frame = CGRect(x: view.frame.width/4,
                                     y: view.frame.height/2 - 100,
                                     width: view.frame.width/2,
                                     height: 200)
    }
    
    @objc func dismissSearch() {
        dismiss(animated: true, completion: nil)
    }

}

//MARK: - Setup data cho table view

extension NewConversationViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = result[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier,
                                                 for: indexPath) as! NewConversationCell
        cell.configure(model: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        result.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let targetUserData = result[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.completion?(targetUserData)
        }
        
    }
    
}

//MARK: - Tìm kiếm user

extension NewConversationViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        result.removeAll()
        loadingSpinner.show(in: view)
        searchUser(query: text)
    }
    
    func searchUser(query: String) {
        
        if hasFetch {
            filterUser(term: query)
        } else {
            //Lấy all user từ database
            DatabaseManager.share.getAllUser { [weak self] result in
                switch result {
                //Lấy thất bại hoặc không có user trên db
                case .failure(let error):
                    print("Error when get all user: \(error). Or the database has no data")
                    self?.loadingSpinner.dismiss(animated: true)
                    self?.updateUI()
                //Lấy thành công gán danh sách user cho biến users. Giá trị biến hasFetch = true
                case .success(let userCollection):
                    self?.users = userCollection
                    self?.hasFetch = true
                    //Gọi hàm filter danh sách tất cả user lấy được
                    self?.filterUser(term: query)
                }
            }
        }
    }
    
    //Hàm filter
    func filterUser(term: String) {
        //Check điều kiện đã lấy được danh sách user chưa
        guard hasFetch else {
            return
        }
        
        guard let emailCurrentUser = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmailCurrentUser = DatabaseManager.share.safeEmail(emailAddress: emailCurrentUser)
        
        //Huỷ animation
        loadingSpinner.dismiss(animated: true)
        //Filter giá trị từ danh sách (users) và gán cho biến result
        let result: [SearchResult] = users.filter({
            guard let name = $0["name"]?.lowercased() as? String,
                  $0["email"] != safeEmailCurrentUser else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }).compactMap {
            guard let name = $0["name"],
                  let email = $0["email"] else {
                return nil
            }
            return SearchResult(name: name, email: email)
        }
        
        self.result = result
        //Gọi hàm update giao diện
        updateUI()
    
    }
    
    //Hàm update giao diện
    func updateUI() {
        //Nếu biến result rỗng. Hiển thị Label thông báo "No result"
        if result.isEmpty {
            noResultLabel.isHidden = false
            tableView.isHidden = true
        //Nếu biến result có giá trị. Hiển thị table view
        } else {
            noResultLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
}
