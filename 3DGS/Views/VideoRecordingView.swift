//
//  VideoRecordingView.swift
//  3DGS Scanner
//
//  视频录制界面 - 全屏相机录制
//  TODO: 集成 AVFoundation 实现真实相机功能
//

import SwiftUI
import AVFoundation

struct VideoRecordingView: View {
    @Binding var isPresented: Bool
    let onComplete: (String) -> Void
    
    @State private var isRecording = false
    @State private var duration = 0
    @State private var showPreview = false
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            // Background gradient
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
            
            // Floating particles
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 4, height: 4)
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -400...400)
                    )
                    .animation(
                        Animation.linear(duration: Double.random(in: 3...5))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...3)),
                        value: isRecording
                    )
            }
            
            VStack(spacing: 0) {
                // Top Bar
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
                    
                    // Timer
                    HStack {
                        ZStack {
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                                .background(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0),
                                    Color.blue.opacity(0.2),
                                    Color.blue.opacity(0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .clipShape(Capsule())
                            
                            Text(formatTime(duration))
                                .font(.system(size: 28, design: .monospaced))
                                .foregroundColor(isRecording ? .red : .white)
                                .shadow(
                                    color: isRecording ? .red.opacity(0.8) : .clear,
                                    radius: 10
                                )
                        }
                        .frame(width: 120, height: 40)
                    }
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Camera Preview Area
                ZStack {
                    // Simulated camera view
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.17, green: 0.17, blue: 0.18),
                                    Color(red: 0.11, green: 0.11, blue: 0.12)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Camera grid overlay (rule of thirds)
                    GeometryReader { geometry in
                        Path { path in
                            // Vertical lines
                            let vSpacing = geometry.size.width / 3
                            path.move(to: CGPoint(x: vSpacing, y: 0))
                            path.addLine(to: CGPoint(x: vSpacing, y: geometry.size.height))
                            path.move(to: CGPoint(x: vSpacing * 2, y: 0))
                            path.addLine(to: CGPoint(x: vSpacing * 2, y: geometry.size.height))
                            
                            // Horizontal lines
                            let hSpacing = geometry.size.height / 3
                            path.move(to: CGPoint(x: 0, y: hSpacing))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: hSpacing))
                            path.move(to: CGPoint(x: 0, y: hSpacing * 2))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: hSpacing * 2))
                        }
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    }
                    .opacity(0.3)
                    
                    // TODO: 集成 AVCaptureSession 显示真实相机画面
                    Text(showPreview ? "视频预览" : "相机预览")
                        .font(.system(size: 17))
                        .foregroundColor(Color(white: 0.6))
                    
                    // Recording indicator
                    if isRecording {
                        VStack {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: .red.opacity(0.8), radius: 10)
                                
                                Text("录制中")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.red.opacity(0.2))
                                    .background(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.red.opacity(0.5), lineWidth: 1)
                                    )
                            )
                            .padding(.top, 80)
                            
                            Spacer()
                        }
                    }
                    
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
                
                // Bottom Controls
                VStack(spacing: 16) {
                    if !showPreview {
                        Text(isRecording ? "点击停止录制" : "点击开始录制")
                            .font(.system(size: 15))
                            .foregroundColor(Color(white: 0.6))
                        
                        // Record button
                        Button(action: {
                            if isRecording {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        }) {
                            ZStack {
                                // Pulse ring when recording
                                if isRecording {
                                    Circle()
                                        .strokeBorder(Color.red, lineWidth: 4)
                                        .frame(width: 90, height: 90)
                                        .scaleEffect(1.2)
                                        .opacity(0.5)
                                        .animation(
                                            Animation.easeOut(duration: 1)
                                                .repeatForever(autoreverses: false),
                                            value: isRecording
                                        )
                                }
                                
                                Circle()
                                    .strokeBorder(
                                        isRecording ? Color.red : Color.white,
                                        lineWidth: 5
                                    )
                                    .frame(width: 80, height: 80)
                                    .background(
                                        isRecording
                                            ? Color.red
                                            : Color.clear
                                    )
                                    .clipShape(Circle())
                                    .shadow(
                                        color: isRecording ? .red.opacity(0.6) : .white.opacity(0.3),
                                        radius: 20
                                    )
                                
                                if isRecording {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white)
                                        .frame(width: 32, height: 32)
                                } else {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 56, height: 56)
                                }
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Text("最长30秒")
                            .font(.system(size: 13))
                            .foregroundColor(Color(white: 0.6))
                    } else {
                        HStack(spacing: 12) {
                            Button(action: retake) {
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
                    }
                }
                .padding(.vertical, 32)
            }
        }
    }
    
    // MARK: - Actions
    private func startRecording() {
        isRecording = true
        duration = 0
        
        // TODO: 启动 AVCaptureSession 录制
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            duration += 1
            if duration >= 30 {
                stopRecording()
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        timer?.invalidate()
        timer = nil
        showPreview = true
        
        // TODO: 停止 AVCaptureSession 录制
    }
    
    private func retake() {
        duration = 0
        showPreview = false
    }
    
    private func confirm() {
        let fileName = "video_\(Date().timeIntervalSince1970).mp4"
        onComplete(fileName)
        isPresented = false
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Camera Corner
struct CameraCorner: View {
    let position: Position
    
    enum Position {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    var body: some View {
        Path { path in
            let size: CGFloat = 32
            
            switch position {
            case .topLeft:
                path.move(to: CGPoint(x: 0, y: size))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: size, y: 0))
            case .topRight:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: size, y: 0))
                path.addLine(to: CGPoint(x: size, y: size))
            case .bottomLeft:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: size))
                path.addLine(to: CGPoint(x: size, y: size))
            case .bottomRight:
                path.move(to: CGPoint(x: size, y: 0))
                path.addLine(to: CGPoint(x: size, y: size))
                path.addLine(to: CGPoint(x: 0, y: size))
            }
        }
        .stroke(Color.blue.opacity(0.5), lineWidth: 2)
        .frame(width: 32, height: 32)
    }
}

#Preview {
    VideoRecordingView(
        isPresented: .constant(true),
        onComplete: { _ in }
    )
}
