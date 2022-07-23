//
//  StorageManager.swift
//  ChatApp
//
//  Created by iOSTeam on 12/07/2022.
//

import Foundation
import FirebaseStorage

class StorageManager {
    
    static let share = StorageManager()
    
    let storage = Storage.storage().reference()
    
    func uploadProfilePicture(data: Data,
                              fileName: String,
                              completion: @escaping (Result<String, Error>) -> Void
    ) {
        storage.child("images/\(fileName)").putData(data,
                                                    metadata: nil)
        { metaData, error in
            guard error == nil else {
                print("Failed to upload to Firebase")
                completion(.failure(error!))
                return
            }
            self.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(error!))
                    return
                }
                
                let urlString = url.absoluteString
                completion(.success(urlString))
            }
        }
    }
    
    func uploadPhotoMessage(data: Data,
                            fileName: String,
                            completion: @escaping (Result<String, Error>) -> Void
    ) {
        storage.child("message_images/\(fileName)").putData(data,
                                                            metadata: nil)
        { metaData, error in
            guard error == nil else {
                print("Failed to upload photo message to Firebase")
                completion(.failure(error!))
                return
            }
            self.storage.child("message_images/\(fileName)").downloadURL { url, error in
                guard let url = url, error == nil else {
                    print("Failed to get download url photo message")
                    completion(.failure(error!))
                    return
                }
                
                let urlString = url.absoluteString
                completion(.success(urlString))
            }
        }
    }
    
    func uploadVideoMessage(url: NSURL,
                            fileName: String,
                            completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = url.filePathURL else {
            print("Get file path fail")
            return
        }
        storage.child("message_video/\(fileName)").putFile(from: url,
                                                           metadata: nil)
        { [weak self] metaData, error in
            guard error == nil else {
                print("Failed to upload video message to Firebase")
                completion(.failure(error!))
                return
            }
            self?.storage.child("message_video/\(fileName)").downloadURL { url, error in
                guard let url = url, error == nil else {
                    print("Failed to get download url photo message")
                    completion(.failure(error!))
                    return
                }
                
                let urlString = url.absoluteString
                completion(.success(urlString))
            }
        }
    }
    
    func getUrlProfilePicture(path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        storage.child(path).downloadURL { url, error in
            guard let url = url, error == nil else {
                completion(.failure(error!))
                return
            }
            completion(.success(url))
        }
    }
}
