//
//  DatabaseManager.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 9/29/20.
//

import Foundation
import FirebaseDatabase
import MessageKit
import CoreLocation

final class DatabaseManager {

    public static let shared = DatabaseManager()

    let database = Database.database().reference()

    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }

    /// creates a new talk with target user email  and first sent message
    public func createNewTalk(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)

        let reference = database.child("\(safeEmail)")

        reference.observeSingleEvent(of: .value, with: { [weak self] snapshot in
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
                    talks.append(recipient_newTalkData)
                    self?.database.child("\(otherUserEmail)/talks").setValue(talkId)
                }
                else {
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

                var kind: MessageKind?
                if type == "photo" {
                    // photo
                    guard let imageUrl = URL(string: content),
                    let placeHolder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }
                else if type == "video" {
                    // photo
                    guard let videoUrl = URL(string: content),
                        let placeHolder = UIImage(named: "video_placeholder") else {
                            return nil
                    }

                    let media = Media(url: videoUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                }
                else if type == "location" {
                    let locationComponents = content.components(separatedBy: ",")
                    guard let longitude = Double(locationComponents[0]),
                        let latitude = Double(locationComponents[1]) else {
                        return nil
                    }
                    print("Rendering location; long=\(longitude) | lat=\(latitude)")
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                            size: CGSize(width: 300, height: 300))
                    kind = .location(location)
                }
                else {
                    kind = .text(content)
                }

                guard let finalKind = kind else {
                    return nil
                }

                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)

                return Message(sender: sender, messageId: messageId, sentDate: date, kind: finalKind)
            })
            completion(.success(messages))
        })
    }

}

