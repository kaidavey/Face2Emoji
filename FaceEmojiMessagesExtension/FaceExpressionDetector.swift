//
//  FaceExpressionDetector.swift
//  FaceEmojiMessagesExtension
//
//  Created on $(DATE)
//

import Foundation
import Vision
import AVFoundation
import Combine
import CoreImage

/// Detects facial expressions from camera frames using Vision framework
class FaceExpressionDetector: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current detected expression result
    @Published var currentExpression: ExpressionResult?
    
    /// Whether detection is currently active
    @Published var isDetecting: Bool = false
    
    // MARK: - Combine Publishers
    
    /// PassthroughSubject for expression detection results
    let expressionSubject = PassthroughSubject<ExpressionResult, Never>()
    
    // MARK: - Private Properties
    
    private let visionQueue = DispatchQueue(label: "com.faceemoji.vision", qos: .userInitiated)
    private var faceDetectionRequest: VNDetectFaceLandmarksRequest?
    private var cancellables = Set<AnyCancellable>()
    
    // Throttling for ~10fps (100ms between detections)
    private let throttleInterval: TimeInterval = 0.1
    private var lastDetectionTime: Date = Date.distantPast
    
    // MARK: - Initialization
    
    init() {
        setupFaceDetectionRequest()
    }
    
    // MARK: - Setup
    
    private func setupFaceDetectionRequest() {
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Face detection error: \(error.localizedDescription)")
                return
            }
            
            self.processFaceLandmarks(request.results)
        }
        
        // Request all available landmarks for detailed analysis
        request.revision = VNDetectFaceLandmarksRequestRevision3
        self.faceDetectionRequest = request
    }
    
    // MARK: - Public Methods
    
    /// Process a camera frame sample buffer
    /// - Parameter sampleBuffer: CMSampleBuffer from camera
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        // Throttle to ~10fps
        let now = Date()
        guard now.timeIntervalSince(lastDetectionTime) >= throttleInterval else {
            return
        }
        lastDetectionTime = now
        
        guard let request = faceDetectionRequest else { return }
        
        visionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Create image request handler
            let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform face detection: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func processFaceLandmarks(_ results: [Any]) {
        guard let observations = results as? [VNFaceObservation],
              let faceObservation = observations.first else {
            DispatchQueue.main.async { [weak self] in
                self?.currentExpression = nil
                self?.isDetecting = false
            }
            return
        }
        
        guard let landmarks = faceObservation.landmarks else {
            DispatchQueue.main.async { [weak self] in
                self?.currentExpression = nil
                self?.isDetecting = false
            }
            return
        }
        
        // Analyze landmarks to determine expression
        let expression = analyzeExpression(faceObservation: faceObservation, landmarks: landmarks)
        
        // Publish via Combine
        expressionSubject.send(expression)
        
        // Update published properties on main thread
        DispatchQueue.main.async { [weak self] in
            self?.currentExpression = expression
            self?.isDetecting = true
        }
    }
    
    private func analyzeExpression(faceObservation: VNFaceObservation, landmarks: VNFaceLandmarks2D) -> ExpressionResult {
        // Get normalized landmark points
        guard let leftEyebrow = landmarks.leftEyebrow,
              let rightEyebrow = landmarks.rightEyebrow,
              let leftEye = landmarks.leftEye,
              let rightEye = landmarks.rightEye,
              let outerLips = landmarks.outerLips,
              let innerLips = landmarks.innerLips,
              let nose = landmarks.nose else {
            return ExpressionResult(expression: .neutral, confidence: 0.5)
        }
        
        // Convert normalized points to image coordinates
        let boundingBox = faceObservation.boundingBox
        let imageWidth = 1.0
        let imageHeight = 1.0
        
        // Calculate key metrics
        let smileScore = calculateSmileScore(outerLips: outerLips, innerLips: innerLips, boundingBox: boundingBox)
        let eyebrowRaise = calculateEyebrowRaise(leftEyebrow: leftEyebrow, rightEyebrow: rightEyebrow, 
                                                  leftEye: leftEye, rightEye: rightEye, boundingBox: boundingBox)
        let eyebrowFurrow = calculateEyebrowFurrow(leftEyebrow: leftEyebrow, rightEyebrow: rightEyebrow, 
                                                   boundingBox: boundingBox)
        let mouthOpenness = calculateMouthOpenness(outerLips: outerLips, innerLips: innerLips, boundingBox: boundingBox)
        let mouthCornersDown = calculateMouthCornersDown(outerLips: outerLips, boundingBox: boundingBox)
        
        // Determine expression based on metrics
        var detectedExpression: Expression = .neutral
        var confidence: Double = 0.5
        
        // Happy: Strong smile, no eyebrow furrow
        if smileScore > 0.3 && eyebrowFurrow < 0.2 {
            detectedExpression = .happy
            confidence = min(1.0, smileScore * 1.5)
        }
        // Surprised: Eyebrows raised + mouth open
        else if eyebrowRaise > 0.25 && mouthOpenness > 0.15 {
            detectedExpression = .surprised
            confidence = min(1.0, (eyebrowRaise + mouthOpenness) * 1.2)
        }
        // Angry: Eyebrows furrowed
        else if eyebrowFurrow > 0.3 {
            detectedExpression = .angry
            confidence = min(1.0, eyebrowFurrow * 1.5)
        }
        // Sad: Mouth corners down, low smile
        else if mouthCornersDown > 0.2 && smileScore < 0.1 {
            detectedExpression = .sad
            confidence = min(1.0, mouthCornersDown * 1.5)
        }
        // Neutral: Everything near baseline
        else {
            detectedExpression = .neutral
            confidence = 0.7
        }
        
        return ExpressionResult(expression: detectedExpression, confidence: confidence)
    }
    
    // MARK: - Expression Calculation Math
    
    /// Calculate smile score based on mouth corner positions
    /// Returns value from -1.0 (frown) to 1.0 (big smile)
    private func calculateSmileScore(outerLips: VNFaceLandmarkRegion2D, innerLips: VNFaceLandmarkRegion2D, boundingBox: CGRect) -> Double {
        let outerPoints = outerLips.normalizedPoints
        let innerPoints = innerLips.normalizedPoints
        
        guard outerPoints.count >= 2, innerPoints.count >= 2 else { return 0.0 }
        
        // Get mouth corners (first and last points of outer lips)
        let leftCorner = denormalizePoint(outerPoints[0], boundingBox: boundingBox)
        let rightCorner = denormalizePoint(outerPoints[outerPoints.count / 2], boundingBox: boundingBox)
        
        // Get mouth center (average of inner lip points)
        let mouthCenterY = innerPoints.map { denormalizePoint($0, boundingBox: boundingBox).y }.reduce(0, +) / Double(innerPoints.count)
        
        // Calculate vertical distance from corners to center
        let leftCornerY = denormalizePoint(outerPoints[0], boundingBox: boundingBox).y
        let rightCornerY = denormalizePoint(outerPoints[outerPoints.count / 2], boundingBox: boundingBox).y
        
        // Smile = corners above center, frown = corners below center
        let leftOffset = mouthCenterY - leftCornerY
        let rightOffset = mouthCenterY - rightCornerY
        let averageOffset = (leftOffset + rightOffset) / 2.0
        
        // Normalize to -1.0 to 1.0 range (assuming max offset of ~0.05 in normalized coordinates)
        return max(-1.0, min(1.0, averageOffset / 0.05))
    }
    
    /// Calculate eyebrow raise (surprise indicator)
    /// Returns value from 0.0 (neutral) to 1.0 (very raised)
    private func calculateEyebrowRaise(leftEyebrow: VNFaceLandmarkRegion2D, rightEyebrow: VNFaceLandmarkRegion2D,
                                       leftEye: VNFaceLandmarkRegion2D, rightEye: VNFaceLandmarkRegion2D,
                                       boundingBox: CGRect) -> Double {
        let leftEyebrowPoints = leftEyebrow.normalizedPoints
        let rightEyebrowPoints = rightEyebrow.normalizedPoints
        let leftEyePoints = leftEye.normalizedPoints
        let rightEyePoints = rightEye.normalizedPoints
        
        guard !leftEyebrowPoints.isEmpty, !rightEyebrowPoints.isEmpty,
              !leftEyePoints.isEmpty, !rightEyePoints.isEmpty else { return 0.0 }
        
        // Get average eyebrow Y position
        let leftEyebrowY = leftEyebrowPoints.map { denormalizePoint($0, boundingBox: boundingBox).y }.reduce(0, +) / Double(leftEyebrowPoints.count)
        let rightEyebrowY = rightEyebrowPoints.map { denormalizePoint($0, boundingBox: boundingBox).y }.reduce(0, +) / Double(rightEyebrowPoints.count)
        
        // Get average eye Y position (baseline)
        let leftEyeY = leftEyePoints.map { denormalizePoint($0, boundingBox: boundingBox).y }.reduce(0, +) / Double(leftEyePoints.count)
        let rightEyeY = rightEyePoints.map { denormalizePoint($0, boundingBox: boundingBox).y }.reduce(0, +) / Double(rightEyePoints.count)
        
        // Calculate distance between eyebrow and eye
        let leftDistance = leftEyeY - leftEyebrowY // Positive = eyebrow above eye
        let rightDistance = rightEyeY - rightEyebrowY
        
        let averageDistance = (leftDistance + rightDistance) / 2.0
        
        // Normalize (typical distance is ~0.03-0.06, raised would be >0.06)
        let baseline = 0.04
        let raiseAmount = max(0.0, averageDistance - baseline)
        return min(1.0, raiseAmount / 0.03)
    }
    
    /// Calculate eyebrow furrow (anger indicator)
    /// Returns value from 0.0 (neutral) to 1.0 (very furrowed)
    private func calculateEyebrowFurrow(leftEyebrow: VNFaceLandmarkRegion2D, rightEyebrow: VNFaceLandmarkRegion2D,
                                        boundingBox: CGRect) -> Double {
        let leftPoints = leftEyebrow.normalizedPoints
        let rightPoints = rightEyebrow.normalizedPoints
        
        guard leftPoints.count >= 3, rightPoints.count >= 3 else { return 0.0 }
        
        // Get inner and outer eyebrow points
        let leftInner = denormalizePoint(leftPoints[0], boundingBox: boundingBox)
        let leftOuter = denormalizePoint(leftPoints[leftPoints.count - 1], boundingBox: boundingBox)
        let rightInner = denormalizePoint(rightPoints[0], boundingBox: boundingBox)
        let rightOuter = denormalizePoint(rightPoints[rightPoints.count - 1], boundingBox: boundingBox)
        
        // Calculate angle/distance between inner points (furrowed = closer together)
        let innerDistance = sqrt(pow(rightInner.x - leftInner.x, 2) + pow(rightInner.y - leftInner.y, 2))
        let outerDistance = sqrt(pow(rightOuter.x - leftOuter.x, 2) + pow(rightOuter.y - leftOuter.y, 2))
        
        // Furrowed = inner points closer relative to outer points
        let ratio = innerDistance / (outerDistance + 0.001) // Avoid division by zero
        
        // Normalize (typical ratio is ~0.3-0.5, furrowed would be <0.3)
        let baseline = 0.4
        let furrowAmount = max(0.0, baseline - ratio)
        return min(1.0, furrowAmount / 0.2)
    }
    
    /// Calculate mouth openness (surprise indicator)
    /// Returns value from 0.0 (closed) to 1.0 (very open)
    private func calculateMouthOpenness(outerLips: VNFaceLandmarkRegion2D, innerLips: VNFaceLandmarkRegion2D,
                                       boundingBox: CGRect) -> Double {
        let outerPoints = outerLips.normalizedPoints
        let innerPoints = innerLips.normalizedPoints
        
        guard !outerPoints.isEmpty, !innerPoints.isEmpty else { return 0.0 }
        
        // Calculate average Y position of outer and inner lips
        let outerY = outerPoints.map { denormalizePoint($0, boundingBox: boundingBox).y }.reduce(0, +) / Double(outerPoints.count)
        let innerY = innerPoints.map { denormalizePoint($0, boundingBox: boundingBox).y }.reduce(0, +) / Double(innerPoints.count)
        
        // Distance between inner and outer lips indicates openness
        let openness = abs(outerY - innerY)
        
        // Normalize (typical closed mouth is ~0.01, open is >0.02)
        return min(1.0, openness / 0.03)
    }
    
    /// Calculate if mouth corners are down (sad indicator)
    /// Returns value from 0.0 (neutral/up) to 1.0 (very down)
    private func calculateMouthCornersDown(outerLips: VNFaceLandmarkRegion2D, boundingBox: CGRect) -> Double {
        let points = outerLips.normalizedPoints
        guard points.count >= 2 else { return 0.0 }
        
        // Get mouth corners (first and midpoint points)
        let leftCorner = denormalizePoint(points[0], boundingBox: boundingBox)
        let rightCorner = denormalizePoint(points[points.count / 2], boundingBox: boundingBox)
        
        // Get mouth center (average of all points)
        let centerY = points.map { denormalizePoint($0, boundingBox: boundingBox).y }.reduce(0, +) / Double(points.count)
        
        // Calculate if corners are below center
        let leftDown = max(0.0, leftCorner.y - centerY)
        let rightDown = max(0.0, rightCorner.y - centerY)
        let averageDown = (leftDown + rightDown) / 2.0
        
        // Normalize (typical down is >0.01)
        return min(1.0, averageDown / 0.02)
    }
    
    /// Convert normalized point (0.0-1.0) to image coordinates within bounding box
    private func denormalizePoint(_ point: CGPoint, boundingBox: CGRect) -> CGPoint {
        return CGPoint(
            x: boundingBox.origin.x + point.x * boundingBox.width,
            y: boundingBox.origin.y + point.y * boundingBox.height
        )
    }
}

