//
//  ProfileViewModelType.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 2/23/21.
//

import Foundation

enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
