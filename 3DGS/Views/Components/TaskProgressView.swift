//
//  TaskProgressView.swift
//  3DGS Scanner
//
//  任务进度详情视图 - 简约现代风格
//

import SwiftUI

struct TaskProgressView: View {
    let model: Model3D
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 0) {
                // 拖动指示条
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                // 状态图标
                StatusIconView(status: model.status)
                    .padding(.bottom, 20)

                // 模型名称
                Text(model.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)

                // 当前阶段
                Text(model.stage ?? "准备中...")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 24)

                // 进度条
                ProgressBarView(status: model.status)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)

                // 状态说明
                StatusDescriptionView(status: model.status, error: model.errorMessage)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                // 操作按钮
                ActionButtonsView(
                    model: model,
                    viewModel: viewModel,
                    dismiss: { isPresented = false }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(white: 0.1))
            )
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Status Icon View
struct StatusIconView: View {
    let status: ModelStatus
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor.opacity(0.15))
                .frame(width: 80, height: 80)

            if status == .processing || status == .queued {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(iconColor, lineWidth: 3)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
            }

            Image(systemName: iconName)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(iconColor)
        }
    }

    private var iconName: String {
        switch status {
        case .completed: return "checkmark"
        case .failed: return "xmark"
        case .processing, .uploading: return "arrow.triangle.2.circlepath"
        case .queued: return "clock"
        }
    }

    private var iconColor: Color {
        switch status {
        case .completed: return .green
        case .failed: return .red
        case .processing, .uploading: return .cyan
        case .queued: return .orange
        }
    }

    private var backgroundColor: Color {
        iconColor
    }
}

// MARK: - Progress Bar View
struct ProgressBarView: View {
    let status: ModelStatus
    @State private var animatedProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))

                RoundedRectangle(cornerRadius: 4)
                    .fill(progressColor)
                    .frame(width: geo.size.width * animatedProgress)
            }
        }
        .frame(height: 6)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = targetProgress
            }
        }
        .onChange(of: status) { _, _ in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = targetProgress
            }
        }
    }

    private var targetProgress: CGFloat {
        switch status {
        case .queued: return 0.1
        case .uploading: return 0.2
        case .processing: return 0.6
        case .completed: return 1.0
        case .failed: return 0.0
        }
    }

    private var progressColor: Color {
        switch status {
        case .completed: return .green
        case .failed: return .red
        default: return .cyan
        }
    }
}

// MARK: - Status Description View
struct StatusDescriptionView: View {
    let status: ModelStatus
    let error: String?

    var body: some View {
        Text(descriptionText)
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.5))
            .multilineTextAlignment(.center)
    }

    private var descriptionText: String {
        switch status {
        case .queued:
            return "任务已加入队列，等待服务器处理"
        case .uploading:
            return "正在上传文件到服务器..."
        case .processing:
            return "服务器正在处理，请耐心等待"
        case .completed:
            return "处理完成，点击查看3D模型"
        case .failed:
            return error ?? "处理失败，请重试"
        }
    }
}

// MARK: - Action Buttons View
struct ActionButtonsView: View {
    let model: Model3D
    @ObservedObject var viewModel: AppViewModel
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                viewModel.deleteModel(model)
                dismiss()
            }) {
                Text("删除")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(10)
            }

            if model.status == .completed {
                Button(action: {
                    dismiss()
                    viewModel.selectModel(model)
                }) {
                    Text("查看模型")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.cyan)
                        .cornerRadius(10)
                }
            } else {
                Button(action: dismiss) {
                    Text("关闭")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(10)
                }
            }
        }
    }
}
