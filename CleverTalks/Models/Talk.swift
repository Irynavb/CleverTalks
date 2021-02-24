//
//  Talk.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 10/3/20.
//

import Foundation

struct Talk {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
