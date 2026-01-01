//
//  ExtensionContentView.swift
//  FaceEmojiMessagesExtension
//
//  Created on $(DATE)
//

import SwiftUI
import Messages

struct ExtensionContentView: View {
    @State private var selectedEmoji: String = "😀"
    let conversation: MSConversation?
    let onSendMessage: ((String) -> Void)?
    
    let emojis = ["😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "😉", "😊", "😇", "🥰", "😍", "🤩"]
    
    init(conversation: MSConversation? = nil, onSendMessage: ((String) -> Void)? = nil) {
        self.conversation = conversation
        self.onSendMessage = onSendMessage
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("FaceEmoji")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Select an emoji to send")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Large display of selected emoji
                Text(selectedEmoji)
                    .font(.system(size: 80))
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.vertical)
                
                // Emoji grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(action: {
                            selectedEmoji = emoji
                        }) {
                            Text(emoji)
                                .font(.system(size: 40))
                                .frame(width: 60, height: 60)
                                .background(selectedEmoji == emoji ? Color.blue.opacity(0.3) : Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Send button
                Button(action: {
                    // Send message action will be implemented
                    sendMessage()
                }) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Send")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
    
    private func sendMessage() {
        guard let conversation = conversation else {
            print("No active conversation")
            return
        }
        
        let message = MessageComposer.createMessage(with: selectedEmoji, in: conversation)
        MessageComposer.insertMessage(message, into: conversation)
        
        // Call the callback if provided
        onSendMessage?(selectedEmoji)
    }
}

#Preview {
    ExtensionContentView()
}

