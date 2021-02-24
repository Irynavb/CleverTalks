//
//  DeleteTalk.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 2/23/21.
//

import Foundation

extension DatabaseManager {

    public func deleteTalk(talkId: String, completion: @escaping (Bool) -> Void) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)

        print("Deleting talk id: \(talkId)")

        let reference = database.child("\(safeEmail)/talks")

        reference.observeSingleEvent(of: .value) { snapshot in
            if var talks = snapshot.value as? [[String: Any]] {
                var positionToRemove = 0
                for talk in talks {
                    if let id = talk["id"] as? String,
                        id == talkId {
                        print("found talk to delete")
                        break
                    }
                    positionToRemove += 1
                }

                talks.remove(at: positionToRemove)
                reference.setValue(talks, withCompletionBlock: { error, _  in

                    guard error == nil else {
                        completion(false)
                        return
                    }
                    print("Talk deleted")

                    completion(true)
                })
            }
        }
    }

    public func talkExists(iwth targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAddress: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)

        database.child("\(safeRecipientEmail)/talks").observeSingleEvent(of: .value, with: { snapshot in
            guard let collection = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.fetchFailure))
                return
            }

            if let talk = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }) {
                // get id
                guard let id = talk["id"] as? String else {
                    completion(.failure(DatabaseError.fetchFailure))
                    return
                }
                completion(.success(id))
                return
            }

            completion(.failure(DatabaseError.fetchFailure))
            return
        })
    }
}
