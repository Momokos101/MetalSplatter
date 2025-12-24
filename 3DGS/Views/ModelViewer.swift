//
//  ModelViewer.swift
//  3DGS Scanner
//
//  3D模型查看器 - 使用 MetalSplatter 渲染 3D Gaussian Splatting
//

import SwiftUI

struct ModelViewer: View {
    let model: Model3D
    @Binding var isPresented: Bool

    @State private var showHint = true

    private var plyURL: URL? {
        guard let path = model.plyPath else { return nil }
        return URL(fileURLWithPath: path)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // MetalSplatter 渲染视图
            if let url = plyURL {
                SplatSceneView(plyURL: url)
                    .ignoresSafeArea()
            } else {
                // 无模型文件时显示占位
                PlaceholderView()
            }
            
            // First-time hint
            if showHint {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "hand.draw")
                            .font(.system(size: 14))
                        Text("单指旋转 · 双指缩放/平移 · 双击重置")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding(.bottom, 100)
                }
                .transition(.opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation { showHint = false }
                    }
                }
            }

            // 顶部导航栏
            VStack {
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text(model.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()
            }
        }
    }
}

// MARK: - Placeholder View
struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("模型文件不存在")
                .font(.system(size: 15))
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    ModelViewer(
        model: Model3D(
            id: "1",
            taskId: "task1",
            name: "测试模型",
            thumbnail: "",
            type: "视频",
            timestamp: Date(),
            status: .completed,
            plyPath: nil,
            stage: nil,
            errorMessage: nil
        ),
        isPresented: .constant(true)
    )
}
