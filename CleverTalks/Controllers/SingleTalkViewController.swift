//
//  SingleTalkViewController.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 9/28/20.
//

import UIKit
import MessageKit

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct Sender: SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
}

class SingleTalkViewController: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {

    private var messages = [Message]()

    private var selfSender = Sender(photoURL: "", senderId: "1", displayName: "Cookie Cook-y")

    override func viewDidLoad() {
        super.viewDidLoad()

        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("Hi, I'm already here. Do you want a coffee?")))
        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("Hi, I'm already here. Do you want a coffee? Or would you prefer tea?")))

        view.backgroundColor = .mediumGreen

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }

    func currentSender() -> SenderType {
        selfSender
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }

}
