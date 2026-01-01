# FaceEmoji - iMessage App Extension

An iOS iMessage App Extension that allows users to send emoji messages through the Messages app.

## Project Structure

```
FaceEmoji/
├── FaceEmoji/                          # Containing App
│   ├── FaceEmojiApp.swift              # Main app entry point
│   ├── ContentView.swift               # Main app UI (shown when app is launched directly)
│   └── Info.plist                      # App configuration
│
├── FaceEmojiMessagesExtension/         # iMessage Extension
│   ├── MessagesViewController.swift    # Extension's main view controller
│   ├── ExtensionContentView.swift      # SwiftUI view for the extension
│   ├── MessageComposer.swift           # Helper for creating and sending messages
│   └── Info.plist                      # Extension configuration
│
└── README.md                           # This file
```

## Setup Instructions

1. **Open in Xcode**: Create a new Xcode project or add these files to an existing project
2. **Configure Targets**:
   - Create an "App" target for `FaceEmoji`
   - Create an "iMessage Extension" target for `FaceEmojiMessagesExtension`
   - Set the extension's target to depend on the app target
3. **Set Deployment Target**: Ensure both targets have iOS 17.0 as the minimum deployment target
4. **Bundle Identifiers**: 
   - App: `com.yourcompany.FaceEmoji`
   - Extension: `com.yourcompany.FaceEmoji.FaceEmojiMessagesExtension`
5. **Add SwiftUI Framework**: Ensure both targets link against SwiftUI

## File Descriptions

### Containing App (`FaceEmoji/`)

- **FaceEmojiApp.swift**: The main entry point for the containing app. Required by Apple for all app extensions. Users can launch this app directly, though its primary purpose is to host the extension.

- **ContentView.swift**: A simple SwiftUI view shown when the containing app is launched directly. Displays a placeholder UI.

- **Info.plist**: Configuration file for the containing app, including bundle identifier, version, and supported orientations.

### iMessage Extension (`FaceEmojiMessagesExtension/`)

- **MessagesViewController.swift**: The main view controller for the iMessage extension. It:
  - Hosts the SwiftUI view using `UIHostingController`
  - Handles lifecycle methods for the extension (becoming active, resigning active, etc.)
  - Manages the conversation state
  - Updates the UI when the conversation changes

- **ExtensionContentView.swift**: The SwiftUI interface for the extension. Features:
  - Emoji selection grid
  - Large emoji preview
  - Send button
  - Integration with Messages framework to send messages

- **MessageComposer.swift**: Helper utility class that:
  - Creates `MSMessage` objects with emoji content
  - Handles message insertion into conversations
  - Provides a clean API for message composition

- **Info.plist**: Extension configuration including:
  - Extension point identifier (`com.apple.messageui`)
  - Presentation styles (compact and expanded)
  - Principal class reference

## Key Features

- **SwiftUI-based UI**: Modern, declarative interface
- **iOS 17+ Support**: Uses latest iOS features
- **Message Integration**: Properly sends messages through the Messages framework
- **Lifecycle Management**: Handles extension activation/deactivation correctly

## Testing

1. Build and run the containing app target
2. Open the Messages app
3. Start a conversation
4. Tap the App Store icon in the message input area
5. Select FaceEmoji from the list of extensions
6. The extension UI should appear, allowing you to select and send emojis

## Notes

- The containing app is required by Apple but may have minimal functionality
- The extension runs in a separate process from the Messages app
- Extension UI is constrained by the Messages app's presentation styles
- Messages can be sent programmatically using the `MSConversation` API

