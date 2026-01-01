//
//  EmojiMapper.swift
//  FaceEmojiMessagesExtension
//
//  Created on $(DATE)
//

import Foundation

/// Maps facial expressions to emoji suggestions with confidence scores
class EmojiMapper {
    
    // MARK: - Emoji Mappings
    
    private static let emojiMappings: [Expression: [String]] = [
        .happy: ["😊", "😄", "🙂", "😁", "🥰"],
        .sad: ["😢", "😞", "🥺", "😔"],
        .surprised: ["😮", "😲", "🤯", "😳"],
        .angry: ["😠", "😤", "😡", "🤬"],
        .neutral: ["😐", "😶", "🙂", "😑"],
        .disgusted: ["🤢", "😖", "🤮"],
        .fearful: ["😨", "😰", "😱"]
    ]
    
    // Special mapping for very high confidence happy expressions (laughing)
    private static let laughingEmojis: [String] = ["😂", "🤣", "😆"]
    
    // MARK: - Confidence Thresholds
    
    private static let highIntensityThreshold: Double = 0.7
    private static let mediumIntensityThreshold: Double = 0.4
    private static let lowIntensityThreshold: Double = 0.2
    
    // MARK: - Public Methods
    
    /// Returns the top 3 emoji matches for a given expression with confidence scores
    /// - Parameters:
    ///   - expression: The detected facial expression
    ///   - confidence: The confidence score of the expression detection (0.0-1.0)
    /// - Returns: Array of tuples containing emoji and confidence, sorted by confidence (highest first)
    func topEmojis(for expression: Expression, confidence: Double) -> [(emoji: String, confidence: Double)] {
        // Get base emoji pool for the expression
        var emojiPool: [String]
        
        // Special case: very happy expressions can use laughing emojis
        if expression == .happy && confidence >= highIntensityThreshold {
            // Mix laughing emojis with regular happy emojis
            let happyEmojis = Self.emojiMappings[.happy] ?? []
            emojiPool = (Self.laughingEmojis + happyEmojis).shuffled()
        } else {
            emojiPool = Self.emojiMappings[expression]?.shuffled() ?? []
        }
        
        guard !emojiPool.isEmpty else {
            // Fallback to neutral if expression not found
            let neutralEmojis = Self.emojiMappings[.neutral] ?? ["😐"]
            return neutralEmojis.prefix(3).map { (emoji: $0, confidence: 0.5) }
        }
        
        // Calculate confidence scores for each emoji
        var emojiResults: [(emoji: String, confidence: Double)] = []
        
        for (index, emoji) in emojiPool.enumerated() {
            let baseConfidence = calculateBaseConfidence(
                expression: expression,
                emojiIndex: index,
                totalCount: emojiPool.count
            )
            
            let intensityModifier = calculateIntensityModifier(
                expressionConfidence: confidence,
                emojiIndex: index
            )
            
            // Combine base confidence with intensity modifier
            let finalConfidence = min(1.0, max(0.0, baseConfidence * intensityModifier))
            
            emojiResults.append((emoji: emoji, confidence: finalConfidence))
        }
        
        // Sort by confidence (highest first) and return top 3
        let sortedResults = emojiResults.sorted { $0.confidence > $1.confidence }
        return Array(sortedResults.prefix(3))
    }
    
    // MARK: - Private Methods
    
    /// Calculates base confidence for an emoji based on its position in the mapping
    /// Earlier emojis in the list are considered more representative
    private func calculateBaseConfidence(expression: Expression, emojiIndex: Int, totalCount: Int) -> Double {
        // First emoji gets highest base confidence, subsequent ones get slightly less
        let positionFactor = 1.0 - (Double(emojiIndex) * 0.15)
        return max(0.3, positionFactor)
    }
    
    /// Calculates intensity modifier based on expression confidence
    /// Higher confidence expressions favor more intense emojis (earlier in list)
    private func calculateIntensityModifier(expressionConfidence: Double, emojiIndex: Int) -> Double {
        // Intensity modifier: higher confidence = favor earlier (more intense) emojis
        let intensityFactor: Double
        
        if expressionConfidence >= highIntensityThreshold {
            // High confidence: strongly favor first emojis
            intensityFactor = 1.0 - (Double(emojiIndex) * 0.2)
        } else if expressionConfidence >= mediumIntensityThreshold {
            // Medium confidence: moderate favor
            intensityFactor = 1.0 - (Double(emojiIndex) * 0.1)
        } else {
            // Low confidence: less favor, more even distribution
            intensityFactor = 1.0 - (Double(emojiIndex) * 0.05)
        }
        
        // Apply expression confidence as a multiplier
        return max(0.5, min(1.2, intensityFactor * (0.7 + expressionConfidence * 0.3)))
    }
    
    // MARK: - Static Helper
    
    /// Get all available emojis for an expression (for testing/debugging)
    static func allEmojis(for expression: Expression) -> [String] {
        if expression == .happy {
            return (emojiMappings[.happy] ?? []) + laughingEmojis
        }
        return emojiMappings[expression] ?? []
    }
}

