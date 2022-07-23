//
//  ChatAppUser.swift
//  ChatApp
//
//  Created by iOSTeam on 22/07/2022.
//

import Foundation

struct ChapAppUser {
    var firstName: String
    var lastName: String
    var emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePicture: String {
        return "\(safeEmail)-profile-picture.png"
    }
}
