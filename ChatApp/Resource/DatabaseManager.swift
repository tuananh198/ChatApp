//
//  DatabaseManager.swift
//  ChatApp
//
//  Created by iOSTeam on 06/07/2022.
//

import Foundation
import FirebaseDatabase
import MessageKit
import SwiftUI

final class DatabaseManager {
    static let share = DatabaseManager()
    
    private let database = Database.database().reference()
    
    //Vì RealTime Database của Firebase không lưu được kí tự đặc biệt (như @, .) vào Key nên chuyển các kí tự đó về dấu -
    func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    
}

//MARK: - Get Name User Login By Email

extension DatabaseManager {
    func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        database.child("\(path)").getData { error, snapshot in
            guard let value = snapshot?.value,
                    error == nil else {
                completion(.failure(DatabaseError.failToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

//MARK: - Quan Ly Account

extension DatabaseManager {
    
    func userExist(email: String, completion: @escaping ((Bool) -> Void)) {
        
        let safeEmail = safeEmail(emailAddress: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value) { snapShot in
            guard snapShot.value as? [String: Any] != nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    public func insertUser(user: ChapAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "firstName": user.firstName,
            "lastName": user.lastName
        ]) { error, _ in
            guard error == nil else {
                print("Failded to write database")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value) { snapShot in
                if var userCollection = snapShot.value as? [[String: String]] {
                    let newUser: [String: String] = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    userCollection.append(newUser)
                    
                    self.database.child("users").setValue(userCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                    }
                    completion(true)
                } else {
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]

                    self.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil else {
                            print("Can't create new user into real time database")
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    }
                }
            }
        }
    }
    
    func getAllUser(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { snapShot in
            guard let value = snapShot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    enum DatabaseError: Error {
        case failToFetch
    }
}

extension DatabaseManager {
    //Tạo conversation mới với user và tin nhắn đầu tiên
    func creatNewConversation(otherUserEmail: String,
                              firstMessage: Message,
                              name: String,
                              completion: @escaping (Bool) -> Void) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String,
              let currentUserName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        let safeEmail = DatabaseManager.share.safeEmail(emailAddress: email)
        
        database.child("\(safeEmail)").observeSingleEvent(of: .value) { [weak self] snapShot in
            guard var userNode = snapShot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            
            switch firstMessage.kind {
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "lastet_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipientNewConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentUserName,
                "lastet_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            self?.database.child("\(otherUserEmail)/conversation").observeSingleEvent(of: .value, with: { [weak self] snapShot in
                if var conversation = snapShot.value as? [[String: Any]] {
                    conversation.append(recipientNewConversationData)
                    self?.database.child("\(otherUserEmail)/conversation").setValue(conversation)
                    
                } else {
                    self?.database.child("\(otherUserEmail)/conversation").setValue([recipientNewConversationData])
                }
                
            })
            
            if var conversation = userNode["conversation"] as? [[String: Any]] {
                conversation.append(newConversationData)
                userNode["conversation"] = conversation
                self?.database.child("\(safeEmail)").setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreateconversation(name: name,
                                                   conversationId: conversationId,
                                                   firstMessage: firstMessage,
                                                   completion: { _ in
                    })
                    completion(true)
                }
            } else {
                userNode["conversation"] = [newConversationData]
                self?.database.child("\(safeEmail)").setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreateconversation(name: name,
                                                   conversationId: conversationId,
                                                   firstMessage: firstMessage,
                                                   completion: { _ in
                    })
                    completion(true)
                }
            }
        }
    }
    
    private func finishCreateconversation(name: String,
                                          conversationId: String,
                                          firstMessage: Message,
                                          completion: @escaping (Bool) -> Void)
    {
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let safeEmail = safeEmail(emailAddress: email)
        
        let messageFullInfo: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.descriptionKind,
            "name": name,
            "content": message,
            "sender_email": safeEmail,
            "date": dateString,
            "is_read": false
        ]
        
        let value: [String: Any] = [
            "messages": [
                messageFullInfo
            ]
        ]
        
        database.child("\(conversationId)").setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    //Get tất cả Conversation match với Email
    
    func getAllConversation(email: String,
                            completion: @escaping (Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversation").observe(.value) { snapShot in
            guard let value = snapShot.value as? [[String: Any]] else {
                print("Fail to fetch or no conversation match email: \(email)")
                completion(.failure(DatabaseError.failToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap { dictionary in
                guard let conversationID = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let lastestMessage = dictionary["lastet_message"] as? [String: Any],
                      let date = lastestMessage["date"] as? String,
                      let isRead = lastestMessage["is_read"] as? Bool,
                      let message = lastestMessage["message"] as? String else {
                    return nil
                }
                
                let lastestObjectMessage = LastestMessege(date: date,
                                                      text: message,
                                                      isRead: isRead)
                
                return Conversation(id: conversationID,
                                    name: name,
                                    otherEmail: otherUserEmail,
                                    lastestMessege: lastestObjectMessage)
            }
            completion(.success(conversations))
        }
    }
    
    // Get toàn bộ Message của Conversation theo ID
    
    func getAllMessage(id: String,
                       completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value) { snapShot in
            guard let value = snapShot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failToFetch))
                return
            }
            let messages: [Message] = value.compactMap { dictionary in
                guard let name = dictionary["name"] as? String,
                      let content = dictionary["content"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString),
                      let messageID = dictionary["id"] as? String,
                      //Sẽ dụng trong chức năng thông báo tin nhắn đã đọc
                      let isRead = dictionary["is_read"] as? Bool,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String else {
                    return nil
                }
                
                var kind: MessageKind?
                
                if type == "photo" {
                    guard let url = URL(string: content),
                          let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 250, height: 250))
                    kind = .photo(media)
                } else if type == "text" {
                    kind = .text(content)
                } else if type == "video" {
                    guard let url = URL(string: content),
                          let placeholder = UIImage(named: "video_placeholder") else {
                        return nil
                    }
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 250, height: 250))
                    kind = .video(media)
                }
                
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                guard let kindMessage = kind else {
                    return nil
                }
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: kindMessage)
            }
            
            completion(.success(messages))
        }
    }
    
    func sendMessage(conversationID: String,
                     otherUserEmail: String,
                     newMessage: Message,
                     name: String,
                     completion: @escaping (Bool) -> Void) {
        
        database.child("\(conversationID)/messages").observeSingleEvent(of: .value)
        { [weak self] snapShot in
            
            guard let self = self else {
                return
            }
            
            // Get current Messages from Firebase and append new Message
            
            guard var currentMessages = snapShot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let safeEmailSender = self.safeEmail(emailAddress: email)
            
            let messageFullInfo: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.descriptionKind,
                "name": name,
                "content": message,
                "sender_email": safeEmailSender,
                "date": dateString,
                "is_read": false
            ]
            
            currentMessages.append(messageFullInfo)
            
            self.database.child("\(conversationID)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                //Update Lastest Message For Current User
                
                self.database.child("\(safeEmailSender)/conversation").observeSingleEvent(of: .value) { snapShot in
                    var databaseEntryConversation = [[String: Any]]()
                    let safeOtherUserEmail = DatabaseManager.share.safeEmail(emailAddress: otherUserEmail)
                    if var conversations = snapShot.value as? [[String: Any]] {
                        let lastestMessage: [String: Any] = [
                            "date": dateString,
                            "is_read": false,
                            "message": message
                        ]
                        
                        var position = 0
                        
                        var targetConversation: [String: Any]?
                        
                        for conversation in conversations {
                            if conversationID == conversation["id"] as? String {
                                targetConversation = conversation
                                break
                            }
                            position += 1
                        }
                        
                        if var targetConversation = targetConversation {
                            targetConversation["lastet_message"] = lastestMessage
                            conversations[position] = targetConversation
                            databaseEntryConversation = conversations
                        } else {
                            let newConversationData: [String: Any] = [
                                "id": conversationID,
                                "other_user_email": safeOtherUserEmail,
                                "name": name,
                                "lastet_message": lastestMessage
                            ]
                            conversations.append(newConversationData)
                            databaseEntryConversation = conversations
                        }
                        
                        
                    } else {
                        let newConversationData: [String: Any] = [
                            "id": conversationID,
                            "other_user_email": safeOtherUserEmail,
                            "name": name,
                            "lastet_message": [
                                "date": dateString,
                                "message": message,
                                "is_read": false
                            ]
                        ]
                        
                        databaseEntryConversation = [
                            newConversationData
                        ]
                    }
                    
                    self.database.child("\(safeEmailSender)/conversation").setValue(databaseEntryConversation) { error, _ in
                        guard error == nil else {
                            print("Save lastest message to Firebase fail")
                            completion(false)
                            return
                        }
                    }
                }
                
                //Update Lastest Message for Other User in conversation
                
                self.database.child("\(otherUserEmail)/conversation").observeSingleEvent(of: .value) { snapShot in
                    var databaseEntryConversation = [[String: Any]]()
                    guard let currentUserName = UserDefaults.standard.value(forKey: "name") as? String else {
                        return
                    }
                    if var otherUserconversations = snapShot.value as? [[String: Any]] {
                        let lastestMessageOtherUser: [String: Any] = [
                            "date": dateString,
                            "is_read": false,
                            "message": message
                        ]
                        
                        var positionOtherUser = 0
                        
                        var targetConversationOtherUser: [String: Any]?
                        
                        for conversation in otherUserconversations {
                            if conversationID == conversation["id"] as? String {
                                targetConversationOtherUser = conversation
                                break
                            }
                            positionOtherUser += 1
                        }
                        
                        if var targetConversationOtherUser = targetConversationOtherUser {
                            targetConversationOtherUser["lastet_message"] = lastestMessageOtherUser
                            otherUserconversations[positionOtherUser] = targetConversationOtherUser
                            databaseEntryConversation = otherUserconversations
                        } else {
                            let newConversationData: [String: Any] = [
                                "id": conversationID,
                                "other_user_email": safeEmailSender,
                                "name": currentUserName,
                                "lastet_message": [
                                    "date": dateString,
                                    "message": message,
                                    "is_read": false
                                ]
                            ]
                            otherUserconversations.append(newConversationData)
                            databaseEntryConversation = otherUserconversations
                        }
                        
                    } else {
                        let newConversationData: [String: Any] = [
                            "id": conversationID,
                            "other_user_email": safeEmailSender,
                            "name": currentUserName,
                            "lastet_message": [
                                "date": dateString,
                                "message": message,
                                "is_read": false
                            ]
                        ]
                        
                        databaseEntryConversation = [
                            newConversationData
                        ]
                    }
                    
                    self.database.child("\(otherUserEmail)/conversation").setValue(databaseEntryConversation) { error, _ in
                        guard error == nil else {
                            print("Save lastest message to Firebase fail")
                            completion(false)
                            return
                        }
                    }
                }
                
                completion(true)
            }
        }
    }
    
    func deleteConversation(conversationID: String, completion: @escaping (Bool) -> Void) {
        print("Begin Delete..")
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            print("Fail to get Current User Email")
            completion(false)
            return
        }
        let safeEmail = DatabaseManager.share.safeEmail(emailAddress: email)
        database.child("\(safeEmail)/conversation").observeSingleEvent(of: .value) {[weak self] snapshot in
            guard var conversations = snapshot.value as? [[String: Any]] else {
                print("Fail to get conversation math User Email")
                completion(false)
                return
            }
            var positionDelete = 0
            for conversation in conversations {
                if conversationID == conversation["id"] as? String {
                    break
                }
                positionDelete += 1
            }
            
            conversations.remove(at: positionDelete)
            
            self?.database.child("\(safeEmail)/conversation").setValue(conversations) { error, _ in
                guard error == nil else {
                    print("Overwrite Database Fail")
                    completion(false)
                    return
                }
                print("Overwrite Database Succes")
                completion(true)
            }
        }
    }
    
    func conversationExist(targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void ) {
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeSenderEmail = DatabaseManager.share.safeEmail(emailAddress: senderEmail)
        
        database.child("\(targetRecipientEmail)/conversation").observeSingleEvent(of: .value) { snapShot in
            guard let conversations = snapShot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failToFetch))
                return
            }
            
            if let conversation = conversations.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return targetSenderEmail == safeSenderEmail
            }) {
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseError.failToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseError.failToFetch))
        }
        
    }
}

