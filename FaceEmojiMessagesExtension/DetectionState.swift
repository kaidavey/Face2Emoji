//
//  DetectionState.swift
//  FaceEmojiMessagesExtension
//
//  Created on $(DATE)
//

import Foundation

/// Represents the current state of face detection and emoji generation
enum DetectionState {
    case initial          // Camera preview loading, emoji slots empty
    case scanning         // "Hold Still" - camera active, detecting face
    case analyzing        // "Analyzing..." - processing expression
    case results          // Emojis displayed with confidence
}

