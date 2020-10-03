//
//  SingleTalkViewController.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 9/28/20.
//

import UIKit
import MessageKit
import InputBarAccessoryView

class SingleTalkViewController: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {

    public static let dateFormatter = DateFormatter().then {
        $0.dateStyle = .medium
        $0.timeStyle = .long
        $0.locale = .current
    }

    public var isNewTalk = false

    public let otherUserEmail: String

    private var messages = [Message]()

    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email")as? String else {
            return nil
        }
        return Sender(photoURL: "", senderId: email, displayName: "Cookie Cook-y")
    }

    init(with email: String) {
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .mediumGreen

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }

    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("SelfSender is nil, email needs to be cached")
        return Sender(photoURL: "", senderId: "35", displayName: "")
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }

}

extension SingleTalkViewController: InputBarAccessoryViewDelegate {

    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageId = createMessageId() else {
            return
        }

        print("sending: \(text)")
        // send messages

        if isNewTalk {
            // create convo in database
            let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))

            DatabaseManager.shared.createNewTalk(with: otherUserEmail, name: self.title ?? "User", firstMessage: message, completion: { [weak self] success in
                if success {
                    print("message sent")
                }
                else {
                    print("failed to send")
                }

            })
        }
        else {
            // append to existing talk data
        }
    }

    private func createMessageId() -> String? {

        // date, otherUserEmail, senderEmail, randomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"

        print("MessageId: \(newIdentifier)")

        return newIdentifier
    }
}
