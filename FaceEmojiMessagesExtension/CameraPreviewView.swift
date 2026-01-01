//
//  CameraPreviewView.swift
//  FaceEmojiMessagesExtension
//
//  Created on $(DATE)
//

import SwiftUI
import AVFoundation

/// SwiftUI view that displays a live camera preview in a circular frame
struct CameraPreviewView: View {
    @State private var permissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var isRequestingPermission = false
    
    var body: some View {
        ZStack {
            switch permissionStatus {
            case .authorized:
                CameraPreviewRepresentable()
                    .clipShape(Circle())
            case .notDetermined:
                if isRequestingPermission {
                    ProgressView()
                        .frame(width: 50, height: 50)
                } else {
                    PermissionPlaceholderView(
                        icon: "camera.fill",
                        message: "Tap to enable camera",
                        action: requestPermission
                    )
                }
            case .denied, .restricted:
                PermissionPlaceholderView(
                    icon: "camera.fill",
                    message: "Camera access denied",
                    action: openSettings
                )
            @unknown default:
                PermissionPlaceholderView(
                    icon: "exclamationmark.triangle",
                    message: "Camera unavailable",
                    action: nil
                )
            }
        }
        .frame(width: 50, height: 50)
        .onAppear {
            checkPermissionStatus()
        }
    }
    
    private func checkPermissionStatus() {
        permissionStatus = CameraPermissionManager.authorizationStatus
    }
    
    private func requestPermission() {
        isRequestingPermission = true
        CameraPermissionManager.requestPermission { status in
            permissionStatus = status
            isRequestingPermission = false
        }
    }
    
    private func openSettings() {
        CameraPermissionManager.openSettings()
    }
}

/// UIViewRepresentable wrapper for the camera preview
private struct CameraPreviewRepresentable: UIViewRepresentable {
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .black
        
        context.coordinator.setupCamera(in: containerView)
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame if needed
        context.coordinator.updatePreviewLayerFrame(in: uiView)
    }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.cleanup()
    }
    
    class Coordinator {
        private var captureSession: AVCaptureSession?
        private var previewLayer: AVCaptureVideoPreviewLayer?
        private let cameraQueue = DispatchQueue(label: "com.faceemoji.camera")
        
        func setupCamera(in containerView: UIView) {
            cameraQueue.async { [weak self] in
                guard let self = self else { return }
                
                let session = AVCaptureSession()
                session.sessionPreset = .low // Use low preset for better performance in extension
                
                guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                    DispatchQueue.main.async {
                        print("Front camera not available")
                    }
                    return
                }
                
                do {
                    let input = try AVCaptureDeviceInput(device: frontCamera)
                    
                    if session.canAddInput(input) {
                        session.addInput(input)
                    } else {
                        DispatchQueue.main.async {
                            print("Could not add camera input")
                        }
                        return
                    }
                    
                    // Configure camera for low latency
                    if frontCamera.isFocusModeSupported(.continuousAutoFocus) {
                        try frontCamera.lockForConfiguration()
                        frontCamera.focusMode = .continuousAutoFocus
                        frontCamera.unlockForConfiguration()
                    }
                    
                    DispatchQueue.main.async {
                        self.captureSession = session
                        self.setupPreviewLayer(in: containerView, session: session)
                        self.startSession()
                    }
                } catch {
                    DispatchQueue.main.async {
                        print("Error setting up camera: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        private func setupPreviewLayer(in containerView: UIView, session: AVCaptureSession) {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            layer.frame = containerView.bounds
            
            containerView.layer.addSublayer(layer)
            previewLayer = layer
        }
        
        func updatePreviewLayerFrame(in containerView: UIView) {
            previewLayer?.frame = containerView.bounds
        }
        
        private func startSession() {
            cameraQueue.async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
        
        func cleanup() {
            cameraQueue.async { [weak self] in
                self?.captureSession?.stopRunning()
                self?.captureSession = nil
            }
            previewLayer?.removeFromSuperlayer()
            previewLayer = nil
        }
    }
}

/// Placeholder view shown when camera permission is not granted
private struct PermissionPlaceholderView: View {
    let icon: String
    let message: String
    let action: (() -> Void)?
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    
                    if message.count <= 10 {
                        Text(message)
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
}

#Preview {
    HStack(spacing: 20) {
        CameraPreviewView()
        CameraPreviewView()
        CameraPreviewView()
    }
    .padding()
}

