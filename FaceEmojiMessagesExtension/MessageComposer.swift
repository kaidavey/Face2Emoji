//
//  MessageComposer.swift
//  FaceEmojiMessagesExtension
//
//  Created on $(DATE)
//

import Messages
import UIKit

/// Helper class to compose and send messages from the extension
class MessageComposer {
    
    /// Creates an MSMessage with the given emoji
    /// - Parameters:
    ///   - emoji: The emoji string to send
    ///   - conversation: The active conversation
    /// - Returns: An MSMessage ready to be inserted into the conversation
    static func createMessage(with emoji: String, in conversation: MSConversation) -> MSMessage {
        let message = MSMessage()
        
        // Create a message layout
        let layout = MSMessageTemplateLayout()
        layout.caption = "FaceEmoji"
        layout.subcaption = emoji
        
        message.layout = layout
        message.summaryText = emoji
        
        // You can also add URL components for more complex messages
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "emoji", value: emoji)
        ]
        message.url = components.url
        
        return message
    }
    
    /// Inserts a message into the active conversation
    /// - Parameters:
    ///   - message: The MSMessage to insert
    ///   - conversation: The active conversation
    static func insertMessage(_ message: MSMessage, into conversation: MSConversation) {
        conversation.insert(message) { error in
            if let error = error {
                print("Error inserting message: \(error.localizedDescription)")
            }
        }
    }
}

