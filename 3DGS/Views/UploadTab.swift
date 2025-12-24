//
//  UploadTab.swift
//  3DGS Scanner
//
//  上传界面 - 真正的移动端布局
//

import SwiftUI

struct UploadTab: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 标题区域 - 移动端样式
                VStack(alignment: .leading, spacing: 4) {
                    AnimatedTitle(
                        text: "创建3D模型",
                        colors: [.white, .cyan, .pink, .cyan, .white]
                    )
                    
                    Text("选择拍摄方式开始创建")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.65))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .padding(.bottom, 20)
                
                // 按钮列表 - 占满剩余空间
                VStack(spacing: 12) {
                    MobileActionButton(
                        icon: "video.fill",
                        title: "录制视频",
                        subtitle: "推荐：30秒以内，环绕拍摄效果最佳",
                        style: .primary,
                        action: { viewModel.startVideoRecording() }
                    )
                    .frame(height: (geometry.size.height - 200) / 3)
                    
                    MobileActionButton(
                        icon: "camera.fill",
                        title: "连续拍摄",
                        subtitle: "需要至少10-20张不同角度",
                        style: .secondary,
                        action: { viewModel.startPhotoCapture() }
                    )
                    .frame(height: (geometry.size.height - 200) / 3)
                    
                    MobileActionButton(
                        icon: "photo.fill",
                        title: "从相册选择",
                        subtitle: "支持 MP4 / MOV / HEIC",
                        style: .tertiary,
                        action: { viewModel.startGallerySelection() }
                    )
                    .frame(height: (geometry.size.height - 200) / 3)
                }
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .padding(.bottom, 16)
                
                Spacer()
                
                // 上传进度
                if let progress = viewModel.uploadProgress {
                    ProgressCard(
                        fileName: progress.fileName,
                        progress: progress.progress,
                        onCancel: { viewModel.cancelUpload() }
                    )
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showVideoRecording) {
            VideoRecordingView(
                isPresented: $viewModel.showVideoRecording,
                onComplete: { fileName in
                    viewModel.handleUpload(fileName: fileName)
                }
            )
        }
        .fullScreenCover(isPresented: $viewModel.showPhotoCapture) {
            PhotoCaptureView(
                isPresented: $viewModel.showPhotoCapture,
                onComplete: { fileName in
                    viewModel.handleUpload(fileName: fileName)
                }
            )
        }
        .sheet(isPresented: $viewModel.showGallery) {
            Text("相册选择器")
                .font(.title)
        }
    }
}

// MARK: - 移动端操作按钮 - 全宽设计
struct MobileActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary, tertiary
    }
    
    @State private var isPressed = false
    @State private var glowScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -300
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // 图标 - 更大更突出
                ZStack {
                    Group {
                        switch style {
                        case .primary:
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.cyan, Color.blue]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.6), lineWidth: 2)
                                    .scaleEffect(glowScale)
                                    .opacity(2 - glowScale)
                            }
                        case .secondary:
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple, Color.pink]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.pink.opacity(0.5), lineWidth: 2)
                                    .scaleEffect(glowScale)
                                    .opacity(2 - glowScale)
                            }
                        case .tertiary:
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(white: 0.15))
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan.opacity(0.4), lineWidth: 2)
                                    .scaleEffect(glowScale)
                                    .opacity(2 - glowScale)
                            }
                        }
                    }
                    .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // 文字 - 左对齐，全宽，更大
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.7))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 箭头 - 更大
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(white: 0.4))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.leading, 18)
            .padding(.trailing, 18)
            .padding(.top, 18)
            .padding(.bottom, 18)
            .background(
                ZStack {
                    buttonBackground
                    
                    // 所有按钮都有扫光效果
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    shimmerColor.opacity(0.2),
                                    Color.clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                        .blur(radius: 8)
                }
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.2), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            // 所有按钮都有脉冲动画
            withAnimation(
                Animation.easeOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                glowScale = 1.6
            }
            
            // 所有按钮都有扫光动画
            withAnimation(
                Animation.linear(duration: 2.5)
                    .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 400
            }
        }
    }
    
    private var buttonBackground: some View {
        Group {
            switch style {
            case .primary:
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.cyan.opacity(0.12),
                        Color.blue.opacity(0.08)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .secondary:
                Color(white: 0.08).opacity(0.5)
            case .tertiary:
                Color(white: 0.06).opacity(0.4)
            }
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary:
            return Color.cyan.opacity(0.25)
        case .secondary:
            return Color.purple.opacity(0.25)
        case .tertiary:
            return Color(white: 0.15)
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .primary:
            return 1.5
        case .secondary, .tertiary:
            return 1
        }
    }
    
    private var shimmerColor: Color {
        switch style {
        case .primary:
            return Color.white
        case .secondary:
            return Color.pink
        case .tertiary:
            return Color.cyan
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    UploadTab(viewModel: AppViewModel())
        .preferredColorScheme(.dark)
}
