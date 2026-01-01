//
//  CameraPermissionManager.swift
//  FaceEmojiMessagesExtension
//
//  Created on $(DATE)
//

import AVFoundation
import UIKit

/// Manages camera permission requests and status
enum CameraPermissionManager {
    
    /// Current authorization status
    static var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    /// Check if camera permission is granted
    static var isAuthorized: Bool {
        authorizationStatus == .authorized
    }
    
    /// Request camera permission
    /// - Parameter completion: Called with the authorization status after request
    static func requestPermission(completion: @escaping (AVAuthorizationStatus) -> Void) {
        switch authorizationStatus {
        case .authorized:
            completion(.authorized)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted ? .authorized : .denied)
                }
            }
        case .denied, .restricted:
            completion(authorizationStatus)
        @unknown default:
            completion(.denied)
        }
    }
    
    /// Open Settings app to allow user to grant permission
    static func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

