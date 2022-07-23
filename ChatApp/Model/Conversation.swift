//
//  Conversation.swift
//  ChatApp
//
//  Created by iOSTeam on 22/07/2022.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherEmail: String
    let lastestMessege: LastestMessege
}

struct LastestMessege {
    let date: String
    let text: String
    let isRead: Bool
}
