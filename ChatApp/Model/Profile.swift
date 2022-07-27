//
//  Profile.swift
//  ChatApp
//
//  Created by iOSTeam on 27/07/2022.
//

import Foundation

enum ProfileViewType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewType
    let title: String
    let handler: (() -> Void)?
}
