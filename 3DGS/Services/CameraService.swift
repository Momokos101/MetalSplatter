//
//  CameraService.swift
//  3DGS Scanner
//
//  相机服务 - AVFoundation 视频录制和照片拍摄
//

import AVFoundation
import UIKit
import Combine

// MARK: - Camera Service Delegate
protocol CameraServiceDelegate: AnyObject {
    func cameraService(_ service: CameraService, didFinishRecordingTo url: URL)
    func cameraService(_ service: CameraService, didCapturePhoto image: UIImage, url: URL)
    func cameraService(_ service: CameraService, didFailWithError error: Error)
}

// MARK: - Camera Service
class CameraService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isSessionRunning = false
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0

    // MARK: - Properties
    weak var delegate: CameraServiceDelegate?
    let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var audioDeviceInput: AVCaptureDeviceInput?
    private let movieFileOutput = AVCaptureMovieFileOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var recordingTimer: Timer?

    // MARK: - Initialization
    override init() {
        super.init()
    }

    // MARK: - Session Configuration
    func configureSession() {
        sessionQueue.async { [weak self] in
            self?.setupSession()
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Add video input
        guard let videoDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            print("无法获取后置摄像头")
            session.commitConfiguration()
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
                videoDeviceInput = videoInput
            }
        } catch {
            print("无法创建视频输入: \(error)")
            session.commitConfiguration()
            return
        }

        // Add audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            do {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                    audioDeviceInput = audioInput
                }
            } catch {
                print("无法创建音频输入: \(error)")
            }
        }

        // Add movie output
        if session.canAddOutput(movieFileOutput) {
            session.addOutput(movieFileOutput)

            if let connection = movieFileOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
        }

        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }

        session.commitConfiguration()
    }

    // MARK: - Session Control
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                }
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }

    // MARK: - Video Recording
    func startRecording() {
        guard !isRecording else { return }

        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            let outputURL = self.generateOutputURL(extension: "mov")

            self.movieFileOutput.startRecording(to: outputURL, recordingDelegate: self)

            DispatchQueue.main.async {
                self.isRecording = true
                self.recordingDuration = 0
                self.startRecordingTimer()
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        sessionQueue.async { [weak self] in
            self?.movieFileOutput.stopRecording()
        }
    }

    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.recordingDuration += 1
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    // MARK: - Photo Capture
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Helper Methods
    private func generateOutputURL(extension ext: String) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let tempDirectory = documentsPath.appendingPathComponent("Temp", isDirectory: true)

        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        let fileName = "\(UUID().uuidString).\(ext)"
        return tempDirectory.appendingPathComponent(fileName)
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.isRecording = false
            self.stopRecordingTimer()

            if let error = error {
                self.delegate?.cameraService(self, didFailWithError: error)
            } else {
                self.delegate?.cameraService(self, didFinishRecordingTo: outputFileURL)
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.cameraService(self, didFailWithError: error)
            }
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }

        let outputURL = generateOutputURL(extension: "jpg")

        do {
            try imageData.write(to: outputURL)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.cameraService(self, didCapturePhoto: image, url: outputURL)
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.cameraService(self, didFailWithError: error)
            }
        }
    }
}