//
//  DatabaseManager.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 9/29/20.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()

    private let database = Database.database().reference()

    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

extension DatabaseManager {

    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        self.database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.fetchFailure))
                return
            }
            completion(.success(value))
        }
    }

    public func userExists(with email: String, completion: @escaping ((Bool) -> Void )) {

        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")

        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }

    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name" : user.firstName,
            "last_name" : user.lastName
        ], withCompletionBlock: { error, _ in
            guard error == nil else {
                print("failed to write to database")
                completion(false)
                return
            }

            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    // append to user dictionary
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
                else {
                    //create the array
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]

                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
            })
        })
    }

    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {

        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.fetchFailure))
                return
            }
            completion(.success(value))
        })
    }

    public enum DatabaseError: Error {
        case fetchFailure
    }
}

extension DatabaseManager {

    /// creates a new talk with target user email  and first sent message
    public func createNewTalk(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)

        let reference = database.child("\(safeEmail)")
        reference.observeSingleEvent(of: .value, andPreviousSiblingKeyWith: { [weak self] snapshot, _  in

            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("no results for users")
                return
            }

            let messageDate = firstMessage.sentDate
            let dateString = SingleTalkViewController.dateFormatter.string(from: messageDate)
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

            let talkId = "talk_\(firstMessage.messageId)"

            let newTalkData: [String: Any] = [
                "id": talkId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]

            let recipient_newTalkData: [String: Any] = [
                "id": talkId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            // Update recipient talk entry
            self?.database.child("\(otherUserEmail)/talks").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var talks = snapshot.value as? [[String: Any]] {
                    // append
                    talks.append(recipient_newTalkData)
                    self?.database.child("\(otherUserEmail)/talks").setValue(talkId)
                }
                else {
                    // create
                    self?.database.child("\(otherUserEmail)/talks").setValue([recipient_newTalkData])
                }
            })

            // update current user entry
            if var talks = userNode["talks"] as? [[String: Any]] {
                // current user already has an existing talks array, so APPEND
                talks.append(newTalkData)
                userNode["talks"] = talks
                reference.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingSingleTalk(name: name, talkId: talkId, firstMessage: firstMessage, completion: completion)
                })
            }
            else {
                // the talk array does not exist, CREATE talk array and APPEND
                userNode["talks"] = [newTalkData]

                reference.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingSingleTalk(name: name, talkId: talkId, firstMessage: firstMessage, completion: completion)
                })
            }
        })
    }

    private func finishCreatingSingleTalk(name: String, talkId: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {

        let messageDate = firstMessage.sentDate
        let dateString = SingleTalkViewController.dateFormatter.string(from: messageDate)

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

        guard let userEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }

        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: userEmail)

        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name
        ]

        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]

        database.child("\(talkId)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }

    /// fetches and returns all talks for the user that passed the email
    public func getAllTalks(for email: String, completion: @escaping (Result<[Talk], Error>) -> Void) {
        database.child("\(email)/talks").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.fetchFailure))
                return
            }
            let talks: [Talk] = value.compactMap({ dictionary in
                guard let talkId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                    return nil
                }

                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)

                return Talk(id: talkId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            })
            completion(.success(talks))
        })

    }

    /// gets all messages for a signgle existing talk
    public func getAllMessagesForSingleTalk(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.fetchFailure))
                return
            }
            let messages: [Message] = value.compactMap({ dictionary in
                guard let messageId = dictionary["id"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let name = dictionary["name"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let content = dictionary["content"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = SingleTalkViewController.dateFormatter.date(from: dateString),
                      let type = dictionary["type"] as? String else {
                    return nil
                }


                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)

                return Message(sender: sender, messageId: messageId, sentDate: date, kind: .text(content))
            })
            completion(.success(messages))
        })
    }
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
                    guard var currentUserTalks = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }

                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]

                    var targetTalk: [String: Any]?
                    var position = 0

                    for talkDictionary in currentUserTalks {
                        if let currentId = talkDictionary["id"] as? String, currentId == talk {
                            targetTalk = talkDictionary
                            break
                        }
                        position += 1
                    }

                    targetTalk?["latest_message"] = updatedValue
                    guard let finalTalk = targetTalk else{
                        completion(false)
                        return
                    }

                    currentUserTalks[position] = finalTalk
                    strongSelf.database.child("\(currentEmail)/talks").setValue(currentUserTalks, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }


                        // Update latest message for recipient user
                        strongSelf.database.child("\(otherUserEmail)/talks").observeSingleEvent(of: .value, with: { snapshot in
                            guard var otherUserTalks = snapshot.value as? [[String: Any]] else {
                                completion(false)
                                return
                            }

                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]

                            var targetTalk: [String: Any]?
                            var position = 0

                            for talkDictionary in otherUserTalks {
                                if let currentId = talkDictionary["id"] as? String, currentId == talk {
                                    targetTalk = talkDictionary
                                    break
                                }
                                position += 1
                            }

                            targetTalk?["latest_message"] = updatedValue
                            guard let finalTalk = targetTalk else{
                                completion(false)
                                return
                            }

                            otherUserTalks[position] = finalTalk
                            strongSelf.database.child("\(otherUserEmail)/talks").setValue(otherUserTalks, withCompletionBlock: { error, _ in
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
