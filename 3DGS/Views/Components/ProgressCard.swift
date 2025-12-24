//
//  ProgressCard.swift
//  3DGS Scanner
//
//  上传进度卡片 - 简约现代风格
//

import SwiftUI

struct ProgressCard: View {
    let fileName: String
    let progress: Int
    let stage: String
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 进度环
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: CGFloat(progress) / 100)
                    .stroke(Color.cyan, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))

                Text("\(progress)%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
            }

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(fileName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(stage)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // 取消按钮
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .background(Color(white: 0.1))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 12) {
        ProgressCard(
            fileName: "video.mp4",
            progress: 45,
            stage: "正在上传...",
            onCancel: {}
        )
        ProgressCard(
            fileName: "scene.mp4",
            progress: 85,
            stage: "正在处理...",
            onCancel: {}
        )
    }
    .padding(16)
    .background(Color.black)
}
