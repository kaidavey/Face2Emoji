//
//  DynamicIslandView.swift
//  FaceEmojiMessagesExtension
//
//  Created on $(DATE)
//

import SwiftUI

/// Dynamic Island-style UI component for face detection and emoji selection
struct DynamicIslandView<CameraPreview: View>: View {
    @Binding var state: DetectionState
    @Binding var emojis: [(emoji: String, confidence: Double)]
    var onEmojiSelected: (String) -> Void
    var cameraPreview: () -> CameraPreview
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Status text and progress indicator
            HStack {
                statusText
                Spacer()
                if state == .analyzing {
                    progressIndicator
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            
            // Main pill container
            HStack(spacing: 16) {
                // Camera preview on the left
                cameraPreview()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                
                // Emoji slots on the right
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        emojiSlot(at: index)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color.black)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Status Text
    
    private var statusText: some View {
        Text(statusMessage)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)
    }
    
    private var statusMessage: String {
        switch state {
        case .initial:
            return "Initializing..."
        case .scanning:
            return "Hold Still"
        case .analyzing:
            return "Analyzing..."
        case .results:
            return "Tap an emoji"
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                .scaleEffect(0.8)
            Text("In Progress")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Emoji Slot
    
    private func emojiSlot(at index: Int) -> some View {
        Group {
            if index < emojis.count {
                // Emoji with confidence-based border
                Button(action: {
                    hapticTap()
                    onEmojiSelected(emojis[index].emoji)
                }) {
                    Text(emojis[index].emoji)
                        .font(.system(size: 32))
                        .frame(width: 50, height: 50)
                        .background(Color.clear)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    borderColor(for: emojis[index].confidence),
                                    style: borderStyle(for: emojis[index].confidence),
                                    lineWidth: borderWidth(for: emojis[index].confidence)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Placeholder circle
                Circle()
                    .fill(Color.clear)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                Color.white.opacity(0.3),
                                style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                            )
                    )
            }
        }
    }
    
    // MARK: - Border Styling Helpers
    
    private func borderColor(for confidence: Double) -> Color {
        if confidence >= 0.8 {
            return Color.white
        } else if confidence >= 0.5 {
            return Color.white.opacity(0.8)
        } else {
            return Color.white.opacity(0.5)
        }
    }
    
    private func borderStyle(for confidence: Double) -> StrokeStyle {
        if confidence < 0.5 {
            return StrokeStyle(lineWidth: borderWidth(for: confidence), dash: [4, 4])
        } else {
            return StrokeStyle(lineWidth: borderWidth(for: confidence))
        }
    }
    
    private func borderWidth(for confidence: Double) -> CGFloat {
        if confidence >= 0.8 {
            return 3.0
        } else if confidence >= 0.5 {
            return 2.0
        } else {
            return 1.0
        }
    }
    
    // MARK: - Haptic Feedback
    
    private func hapticTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var state: DetectionState = .scanning
        @State private var emojis: [(emoji: String, confidence: Double)] = []
        
        var body: some View {
            VStack {
                DynamicIslandView(
                    state: $state,
                    emojis: $emojis,
                    onEmojiSelected: { emoji in
                        print("Selected: \(emoji)")
                    },
                    cameraPreview: {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 50, height: 50)
                    }
                )
                Spacer()
            }
            .background(Color(.systemBackground))
            .onAppear {
                // Simulate state changes
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    state = .analyzing
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    state = .results
                    emojis = [
                        (emoji: "😊", confidence: 0.92),
                        (emoji: "😄", confidence: 0.75),
                        (emoji: "🙂", confidence: 0.45)
                    ]
                }
            }
        }
    }
    
    return PreviewWrapper()
}

