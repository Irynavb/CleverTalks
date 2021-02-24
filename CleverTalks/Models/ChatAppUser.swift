//
//  ChatAppUser.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 9/30/20.
//

import Foundation
import FirebaseDatabase

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String

    #warning("check this part of code for redunduncy")
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }

    var profileImageFileName: String {
        //iryna-gmail-com_profile_picture.png
        "\(safeEmail)_profile_picture.png"
    }
}

