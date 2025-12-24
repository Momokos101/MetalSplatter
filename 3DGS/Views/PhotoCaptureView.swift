//
//  PhotoCaptureView.swift
//  3DGS Scanner
//
//  连续拍摄界面 - 拍摄多张照片
//

import SwiftUI
import UIKit

struct PhotoCaptureView: View {
    @Binding var isPresented: Bool
    let onComplete: ([URL]) -> Void

    @StateObject private var cameraService = CameraService()
    @State private var photos: [CapturedPhoto] = []
    @State private var showPreview = false

    private let maxPhotos = 20
    private let minPhotos = 10
    
    var progress: CGFloat {
        CGFloat(photos.count) / CGFloat(maxPhotos) * 100
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0, green: 0.1, blue: 0.2),
                    Color.black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                VStack(spacing: 12) {
                    HStack {
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.7))
                                        .background(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        
                        Spacer()
                        
                        // Photo count
                        ZStack {
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                                .background(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            
                            Text("已拍摄 \(photos.count)/\(maxPhotos)")
                                .font(.system(size: 22, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                        }
                        .frame(height: 40)
                        
                        Spacer()
                        
                        Color.clear.frame(width: 44, height: 44)
                    }
                    .padding(.horizontal)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(red: 0.17, green: 0.17, blue: 0.18))
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(Color.blue)
                                .frame(
                                    width: geometry.size.width * progress / 100,
                                    height: 4
                                )
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal)
                    
                    // Hint
                    Text(hintText)
                        .font(.system(size: 15))
                        .foregroundColor(Color(white: 0.6))
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Camera/Preview Area
                if !showPreview {
                    // Camera preview
                    ZStack {
                        CameraPreviewView(session: cameraService.session)
                            .ignoresSafeArea()

                        // Corner frames
                        VStack {
                            HStack {
                                CameraCorner(position: .topLeft)
                                Spacer()
                                CameraCorner(position: .topRight)
                            }
                            Spacer()
                            HStack {
                                CameraCorner(position: .bottomLeft)
                                Spacer()
                                CameraCorner(position: .bottomRight)
                            }
                        }
                        .padding(16)
                    }
                } else {
                    // Preview grid
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ],
                            spacing: 8
                        ) {
                            ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                                ZStack {
                                    Rectangle()
                                        .fill(Color(red: 0.17, green: 0.17, blue: 0.18))
                                        .aspectRatio(1, contentMode: .fit)
                                        .cornerRadius(8)
                                    
                                    Text("\(index + 1)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Color(white: 0.6))
                                    
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Button(action: { removePhoto(at: index) }) {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .frame(width: 24, height: 24)
                                                    .background(
                                                        Circle()
                                                            .fill(Color.red)
                                                    )
                                            }
                                            .buttonStyle(ScaleButtonStyle())
                                            .padding(4)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 150)
                    }
                }
                
                // Bottom Controls
                if !showPreview {
                    HStack(alignment: .bottom) {
                        // Recent thumbnails
                        HStack(spacing: 8) {
                            ForEach(photos.suffix(2)) { photo in
                                Rectangle()
                                    .fill(Color(red: 0.17, green: 0.17, blue: 0.18))
                                    .frame(width: 56, height: 56)
                                    .cornerRadius(8)
                                    .overlay(
                                        Text("\(photos.firstIndex(where: { $0.id == photo.id })! + 1)")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(white: 0.6))
                                    )
                            }
                        }
                        .frame(width: 120, alignment: .leading)
                        
                        Spacer()
                        
                        // Capture button
                        Button(action: capturePhoto) {
                            ZStack {
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 5)
                                    .frame(width: 64, height: 64)
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 48, height: 48)
                            }
                        }
                        .disabled(photos.count >= maxPhotos)
                        .opacity(photos.count >= maxPhotos ? 0.5 : 1)
                        .buttonStyle(ScaleButtonStyle())
                        
                        Spacer()
                        
                        // Complete button
                        Button(action: complete) {
                            ZStack {
                                Circle()
                                    .fill(
                                        photos.count >= minPhotos
                                            ? Color.green
                                            : Color(red: 0.17, green: 0.17, blue: 0.18)
                                    )
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(photos.count < minPhotos)
                        .opacity(photos.count < minPhotos ? 0.5 : 1)
                        .buttonStyle(ScaleButtonStyle())
                        .frame(width: 120, alignment: .trailing)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 32)
                } else {
                    // Preview controls
                    HStack(spacing: 12) {
                        Button(action: { showPreview = false }) {
                            Text("重新拍摄")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.17, green: 0.17, blue: 0.18),
                                            Color(red: 0.11, green: 0.11, blue: 0.12)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: confirm) {
                            ZStack {
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .cornerRadius(12)
                                
                                Text("确认上传")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 32)
                }
            }
        }
        .onAppear {
            cameraService.delegate = PhotoCaptureDelegate(
                onPhotoCaptured: { image, url in
                    let photo = CapturedPhoto(id: UUID().uuidString, url: url, image: image)
                    photos.append(photo)
                }
            )
            cameraService.configureSession()
            cameraService.startSession()
        }
        .onDisappear {
            cameraService.stopSession()
        }
    }

    // MARK: - Computed Properties
    private var hintText: String {
        if photos.count < minPhotos {
            return "还需要\(minPhotos - photos.count)张照片"
        } else if photos.count < maxPhotos {
            return "已达到最低要求，可以继续拍摄或完成"
        } else {
            return "已达到最大数量"
        }
    }
    
    // MARK: - Actions
    private func capturePhoto() {
        guard photos.count < maxPhotos else { return }
        cameraService.capturePhoto()
    }

    private func removePhoto(at index: Int) {
        let photo = photos[index]
        try? FileManager.default.removeItem(at: photo.url)
        photos.remove(at: index)
    }

    private func complete() {
        guard photos.count >= minPhotos else { return }
        showPreview = true
    }

    private func confirm() {
        let urls = photos.map { $0.url }
        onComplete(urls)
        isPresented = false
    }
}

// MARK: - Models
struct CapturedPhoto: Identifiable {
    let id: String
    let url: URL
    let image: UIImage
}

#Preview {
    PhotoCaptureView(
        isPresented: .constant(true),
        onComplete: { _ in }
    )
}

// MARK: - Photo Capture Delegate
class PhotoCaptureDelegate: CameraServiceDelegate {
    let onPhotoCaptured: (UIImage, URL) -> Void

    init(onPhotoCaptured: @escaping (UIImage, URL) -> Void) {
        self.onPhotoCaptured = onPhotoCaptured
    }

    func cameraService(_ service: CameraService, didFinishRecordingTo url: URL) {}

    func cameraService(_ service: CameraService, didCapturePhoto image: UIImage, url: URL) {
        DispatchQueue.main.async {
            self.onPhotoCaptured(image, url)
        }
    }

    func cameraService(_ service: CameraService, didFailWithError error: Error) {
        print("拍照失败: \(error)")
    }
}
