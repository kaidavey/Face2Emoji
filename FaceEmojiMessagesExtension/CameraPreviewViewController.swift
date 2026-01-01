//
//  CameraPreviewViewController.swift
//  FaceEmojiMessagesExtension
//
//  Created on $(DATE)
//

import UIKit
import AVFoundation

/// UIKit view controller that manages the camera preview layer
class CameraPreviewViewController: UIViewController {
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let cameraQueue = DispatchQueue(label: "com.faceemoji.camera")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    private func setupCamera() {
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
                    self.setupPreviewLayer()
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error setting up camera: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func setupPreviewLayer() {
        guard let session = captureSession else { return }
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        
        view.layer.addSublayer(layer)
        previewLayer = layer
    }
    
    private func startSession() {
        cameraQueue.async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    private func stopSession() {
        cameraQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    deinit {
        stopSession()
    }
}

