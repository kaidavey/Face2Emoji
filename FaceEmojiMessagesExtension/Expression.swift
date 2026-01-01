//
//  Expression.swift
//  FaceEmojiMessagesExtension
//
//  Created on $(DATE)
//

import Foundation

/// Represents a detected facial expression
enum Expression: String, CaseIterable {
    case happy = "Happy"
    case sad = "Sad"
    case surprised = "Surprised"
    case angry = "Angry"
    case neutral = "Neutral"
}

/// Result of expression detection with confidence
struct ExpressionResult {
    let expression: Expression
    let confidence: Double
    
    init(expression: Expression, confidence: Double) {
        self.expression = expression
        self.confidence = max(0.0, min(1.0, confidence)) // Clamp between 0 and 1
    }
}

