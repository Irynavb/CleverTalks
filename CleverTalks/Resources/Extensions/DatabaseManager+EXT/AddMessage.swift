//
//  AddMessage.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 2/23/21.
//

import Foundation

extension DatabaseManager {

    /// sends a message to an existing talk
    public func sendMessage(to talk: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {

        guard let userEmail = UserDefaults.standard.value(forKey: "email") as? String else {

            completion(false)

            return
        }

        let currentEmail = DatabaseManager.safeEmail(emailAddress: userEmail)

        database.child("\(talk)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in

            guard let strongSelf = self else {
                return
            }

            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }

            let messageDate = newMessage.sentDate
            let dateString = SingleTalkViewController.dateFormatter.string(from: messageDate)

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
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            case .linkPreview(_):
                break
            }

            guard let userEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }

            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: userEmail)

            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]

            currentMessages.append(newMessageEntry)

            strongSelf.database.child("\(talk)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }

                strongSelf.database.child("\(currentEmail)/talks").observeSingleEvent(of: .value, with: { snapshot in
                    var databaseEntryTalks = [[String: Any]]()

                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]

                    if var currentUserTalks = snapshot.value as? [[String: Any]] {
                        var targetTalk: [String: Any]?
                        var position = 0

                        for talkDictionary in currentUserTalks {
                            if let currentId = talkDictionary["id"] as? String, currentId == talk {
                                targetTalk = talkDictionary
                                break
                            }
                            position += 1
                        }

                        if var targetTalk = targetTalk {
                            targetTalk["latest_message"] = updatedValue
                            currentUserTalks[position] = targetTalk
                            databaseEntryTalks = currentUserTalks
                        }
                        else {
                            let newTalkData: [String: Any] = [
                                "id": talk,
                                "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                                "name": name,
                                "latest_message": updatedValue
                            ]
                            currentUserTalks.append(newTalkData)
                            databaseEntryTalks = currentUserTalks
                        }
                    }
                    else {
                        let newTalkData: [String: Any] = [
                            "id": talk,
                            "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                            "name": name,
                            "latest_message": updatedValue
                        ]
                        databaseEntryTalks = [
                            newTalkData
                        ]
                    }

                    strongSelf.database.child("\(currentEmail)/talks").setValue(databaseEntryTalks, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }

                        // Update latest message for recipient user
                        strongSelf.database.child("\(otherUserEmail)/talks").observeSingleEvent(of: .value, with: { snapshot in

                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]

                            var databaseEntryTalks = [[String: Any]]()

                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                                return
                            }

                            if var otherUserTalks = snapshot.value as? [[String: Any]] {
                                var targetTalk: [String: Any]?
                                var position = 0

                                for talkDictionary in otherUserTalks {
                                    if let currentId = talkDictionary["id"] as? String, currentId == talk {
                                        targetTalk = talkDictionary
                                        break
                                    }
                                    position += 1
                                }

                                if var targetTalk = targetTalk {
                                    targetTalk["latest_message"] = updatedValue
                                    otherUserTalks[position] = targetTalk
                                    databaseEntryTalks = otherUserTalks
                                }
                                else {
                                    // failed to find in current colleciton
                                    let newTalkData: [String: Any] = [
                                        "id": talk,
                                        "other_user_email": DatabaseManager.safeEmail(emailAddress: currentEmail),
                                        "name": currentName,
                                        "latest_message": updatedValue
                                    ]
                                    otherUserTalks.append(newTalkData)
                                    databaseEntryTalks = otherUserTalks
                                }
                            }
                            else {
                                // current collection does not exist
                                let newTalkData: [String: Any] = [
                                    "id": talk,
                                    "other_user_email": DatabaseManager.safeEmail(emailAddress: currentEmail),
                                    "name": currentName,
                                    "latest_message": updatedValue
                                ]
                                databaseEntryTalks = [
                                    newTalkData
                                ]
                            }

                            strongSelf.database.child("\(otherUserEmail)/talks").setValue(databaseEntryTalks, withCompletionBlock: { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }

                                completion(true)
                            })
                        })
                    })
                })
            }
        })
    }

}
