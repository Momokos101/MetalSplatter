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
                // 标题区域
                VStack(alignment: .leading, spacing: 4) {
                    Text("创建3D模型")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text("选择拍摄方式开始创建")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
                .padding(.horizontal, 16)
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
                        stage: progress.stage,
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
                onComplete: { videoURL in
                    viewModel.uploadVideo(url: videoURL)
                }
            )
        }
        .fullScreenCover(isPresented: $viewModel.showPhotoCapture) {
            PhotoCaptureView(
                isPresented: $viewModel.showPhotoCapture,
                onComplete: { imageURLs in
                    viewModel.uploadImages(urls: imageURLs)
                }
            )
        }
        .sheet(isPresented: $viewModel.showGallery) {
            GalleryPickerView(
                isPresented: $viewModel.showGallery,
                onVideoSelected: { videoURL in
                    viewModel.uploadVideo(url: videoURL)
                },
                onImagesSelected: { imageURLs in
                    viewModel.uploadImages(urls: imageURLs)
                }
            )
        }
    }
}

// MARK: - 简约操作按钮
struct MobileActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let style: ButtonStyle
    let action: () -> Void

    enum ButtonStyle {
        case primary, secondary, tertiary
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // 图标
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconBackground)
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }

                // 文字
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(white: 0.1))
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var iconBackground: Color {
        switch style {
        case .primary: return .cyan
        case .secondary: return .purple
        case .tertiary: return Color(white: 0.2)
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    UploadTab(viewModel: AppViewModel())
        .preferredColorScheme(.dark)
}
