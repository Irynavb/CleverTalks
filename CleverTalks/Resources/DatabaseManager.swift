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
    public func createNewTalk(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)

        let reference = database.child("\(safeEmail)")
        reference.observeSingleEvent(of: .value, andPreviousSiblingKeyWith: { snapshot, _  in

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

            let talkData: [String: Any] = [
                "id": "talk_\(firstMessage.messageId)",
                "other_user_email": otherUserEmail,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]

            if var talks = userNode["talks"] as? [[String: Any]] {
                // current user already has an existing talks array, so APPEND
                talks.append(talkData)
                userNode["talks"] = talks
                reference.setValue(userNode, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    completion(true)
                })
            }
            else {
                // the talk array does not exist, CREATE talk array and APPEND
                userNode["talks"] = [talkData]

                reference.setValue(userNode, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    completion(true)
                })
            }
        })
    }

    /// fetches and returns all talks for the user that passed the email
    public func getAllTalks(for email: String, completion: @escaping (Result<String, Error>) -> Void) {

    }

    /// gets all messages for a signgle existing talk
    public func getAllMessagesForSingleTalk(with id: String, completion: @escaping (Result<String, Error>) -> Void) {

    }
    /// sends a message to an existing talk
    public func sendMessage(to existingTalk: String, message: Message, completion: @escaping (Bool) -> Void) {

    }
}
