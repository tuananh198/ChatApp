//
//  ChatViewController.swift
//  ChatApp
//
//  Created by iOSTeam on 11/07/2022.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SwiftUI
import AVFoundation
import AVKit
import CoreLocation

class ChatViewController: MessagesViewController {
    
    var currentUserAvatarURL: URL?
    
    var otherUserAvatarURL: URL?
    
    public static var dateFormatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    let otherUserEmail: String
    
    var isNewConversation = false
    
    var conversationID: String?
    
    var messages = [Message]()
    
    var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.share.safeEmail(emailAddress: email)
        return Sender(photoURL: "", senderId: safeEmail, displayName: "Me")
    }    

    init(otherUserEmail: String, id: String?) {
        self.otherUserEmail = otherUserEmail
        self.conversationID = id
        super.init(nibName: nil, bundle: nil)
        if let conversationID = conversationID {
            listenForMessage(id: conversationID)
        }
    }
    
    //Obseve Database và Gán giá trị cho message
    func listenForMessage(id: String) {
        DatabaseManager.share.getAllMessage(id: id) { [weak self] result in
            switch result {
            case .success(let message):
                guard !message.isEmpty else {
                    return
                }
                
                self?.messages = message

                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    self?.messagesCollectionView.scrollToLastItem(animated: true)
                }
            case .failure(let error):
                print("Failed to get All Message: \(error)")
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate.self = self
        messageInputBar.delegate = self
        setupInputButton()
    }
    
    func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 33, height: 33), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.inputButtonAction()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    func inputButtonAction() {
        let actionSheet = UIAlertController(title: "Attach file",
                                            message: "Select the file type you want to send",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video",
                                            style: .default,
                                            handler: { [weak self] _ in
            self?.presentVideoActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Location",
                                            style: .default,
                                            handler: { [weak self] _ in
            self?.presentLocationPicker()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel))
        
        present(actionSheet,
                animated: true)
    }
    
    func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "Upload Photo From ?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera",
                                            style: .default,
                                            handler: { _ in
            print("The function is developing")
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library",
                                            style: .default,
                                            handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    func presentVideoActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Upload Video From ?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera",
                                            style: .default,
                                            handler: { _ in
            print("The function is developing")
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video Library",
                                            style: .default,
                                            handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    //Hiển thị Map. Lấy giá trị lat và lon từ completion của LocationPickerViewController sau đó sendMessage
    func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil, isPickable: true)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] coordinate in
            
            guard let self = self else {
                return
            }
            
            guard let messageID = self.createMessageId(),
                  let name = self.title,
                  let selfSender = self.selfSender,
                  let conversationID = self.conversationID else {
                return
            }
            
            let locationItem = Location(location: CLLocation(latitude: coordinate.latitude,
                                                             longitude: coordinate.longitude),
                                        size: .zero)
            
            let messsage = Message(sender: selfSender,
                                   messageId: messageID,
                                   sentDate: Date(),
                                   kind: .location(locationItem))
            
            DatabaseManager.share.sendMessage(conversationID: conversationID,
                                              otherUserEmail: self.otherUserEmail,
                                              newMessage: messsage,
                                              name: name) { result in
                if result {
                    print("Send Location Success")
                } else {
                    print("Send Location Fail")
                }
            }
        }
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let conversationID = conversationID {
            listenForMessage(id: conversationID)
        }
    }
    
}

//MARK: - Upload photo message

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let messageID = createMessageId(),
              let conversationID = conversationID,
              let name = self.title,
              let selfSender = selfSender else {
            return
        }
        
        // Upload Photo Message
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
           let imageData = image.pngData() {
            
            let fileName = "photo_message_" + messageID
            StorageManager.share.uploadPhotoMessage(data: imageData,
                                                    fileName: fileName) { [weak self] result in
                switch result {
                    
                case .failure(let error):
                    print("Upload Photo Message Fail: \(error)")
                    
                case .success(let urlString):
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus"),
                          let self = self else {
                        return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let messsage = Message(sender: selfSender,
                                           messageId: messageID,
                                           sentDate: Date(),
                                           kind: .photo(media))
                    
                    DatabaseManager.share.sendMessage(conversationID: conversationID,
                                                      otherUserEmail: self.otherUserEmail,
                                                      newMessage: messsage,
                                                      name: name) { result in
                        if result {
                            print("Send Photo Success")
                        } else {
                            print("Send Photo Fail")
                        }
                    }
                }
            }
        }
        
        // Upload Video Messsage
        if let videoUrl = info[.mediaURL] as? NSURL {
            let fileName = "video_message_" + messageID + ".mov"
            StorageManager.share.uploadVideoMessage(url: videoUrl,
                                                    fileName: fileName) { [weak self] result in
                switch result {
                case .failure(let error):
                    print("Upload video Message Fail: \(error)")
                case .success(let urlString):
                    guard let nsurl = NSURL(string: urlString),
                          let placeholder = UIImage(systemName: "plus"),
                          let self = self else {
                        return
                    }
                    
                    let url = nsurl as URL
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let messsage = Message(sender: selfSender,
                                           messageId: messageID,
                                           sentDate: Date(),
                                           kind: .video(media))
                    
                    DatabaseManager.share.sendMessage(conversationID: conversationID,
                                                      otherUserEmail: self.otherUserEmail,
                                                      newMessage: messsage,
                                                      name: name) { result in
                        if result {
                            print("Send Photo Success")
                        } else {
                            print("Send Photo Fail")
                        }
                    }
                }
            }
        }
    }
}

//MARK: - Setup Event when click button send message

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard let selfSender = selfSender,
              let messageId = createMessageId() else {
            return
        }
        DispatchQueue.main.async {
            inputBar.inputTextView.text = ""
            self.messagesCollectionView.reloadData()
            self.messagesCollectionView.scrollToLastItem(animated: true)
        }
        
        let message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        
        if isNewConversation {
            DatabaseManager.share.creatNewConversation(otherUserEmail: otherUserEmail,
                                                       firstMessage: message,
                                                       name: self.title ?? "User")
            { [weak self] success in
                guard let self = self else {
                    return
                }
                if success {
                    DispatchQueue.main.async {
                        self.messagesCollectionView.scrollToLastItem(animated: true)
                    }
                    self.isNewConversation = false
                    let newConversationID = "conversation_\(message.messageId)"
                    self.conversationID = newConversationID
                    self.listenForMessage(id: newConversationID)
                    
                } else {
                    print("Messege send fail")
                }
            }
        } else {
            guard let conversationID = conversationID,
                let name = self.title else {
                return
            }

            DatabaseManager.share.sendMessage(conversationID: conversationID,
                                              otherUserEmail: otherUserEmail,
                                              newMessage: message,
                                              name: name, completion: { [weak self] success in
                guard let self = self else {
                    return
                }
                if success {
                    DispatchQueue.main.async {
                        self.messagesCollectionView.scrollToLastItem(animated: true)
                    }
                } else {
                    print("Sent Message Failed")
                }
            })
            
            
        }
    }
    
    //Tạo ID
    func createMessageId() -> String? {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeCurrentEmail = DatabaseManager.share.safeEmail(emailAddress: currentEmail)
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        let newIdentifer = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        return newIdentifer
    }
}

//MARK: - Provide Data for the MessageCollectionView

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Sender is nill")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
            
        case .photo(let mediaItem):
            guard let url = mediaItem.url else {
                return
            }
            imageView.sd_setImage(with: url)
            
        default:
            break
        }
    }
    
    //Chức năng show Avatar trong cuộc trò chuyện chưa hoàn thiện
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {

        let safeEmailSender = message.sender.senderId
        
        
        let path = "images/\(safeEmailSender)-profile-picture.png"
        
        if selfSender?.senderId == safeEmailSender {
            if let currentUserAvatarURL = currentUserAvatarURL {
                DispatchQueue.main.async {
                    avatarView.sd_setImage(with: currentUserAvatarURL)
                }
            } else {
                StorageManager.share.getUrlProfilePicture(path: path) { [weak self] result in
                    guard let self = self else {
                        return
                    }
                    switch result {
                    case .success(let url):
                        self.currentUserAvatarURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url)
                        }
                    case .failure(let error):
                        print("Load Url Current User Avatar Fail: \(error)")
                    }
                }
            }
        } else {
            if let otherUserAvatarURL = otherUserAvatarURL {
                DispatchQueue.main.async {
                    avatarView.sd_setImage(with: otherUserAvatarURL)
                }
            } else {
                StorageManager.share.getUrlProfilePicture(path: path) { [weak self] result in
                    guard let self = self else {
                        return
                    }
                    switch result {
                    case .success(let url):
                        self.otherUserAvatarURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url)
                        }
                    case .failure(let error):
                        print("Load Url Avatar Other User Fail: \(error)")
                    }
                }
            }
        }
    }
    
}

//MARK: - Event Cell Message

extension ChatViewController: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
            
        case .photo(let mediaItem):
            guard let url = mediaItem.url else {
                return
            }
            let vc = MessagePhotoViewerViewController(url: url)
            navigationController?.pushViewController(vc, animated: true)
            
        case .video(let mediaItem):
            guard let url = mediaItem.url else {
                return
            }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: url)
            present(vc, animated: true)
            
        default:
            break
        }
    }
    
    //Event khi Click vào Message
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
    
        switch message.kind {
        //Event khi click vào Messege Location
        case .location(let locationItem):
            let coordinates = locationItem.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates, isPickable: false)
            vc.title = "Location"
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}
