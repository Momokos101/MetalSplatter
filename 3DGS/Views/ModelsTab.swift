//
//  ModelsTab.swift
//  3DGS Scanner
//
//  模型库界面 - 真正的移动端布局
//

import SwiftUI

struct ModelsTab: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedProgressModel: Model3D?

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 标题区域
                    VStack(alignment: .leading, spacing: 4) {
                        Text("我的模型")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    // 模型网格
                    if viewModel.models.isEmpty {
                        EmptyStateView()
                            .padding(.top, 60)
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ],
                            spacing: 8
                        ) {
                            ForEach(viewModel.models) { model in
                                ModelCard(model: model) {
                                    handleModelTap(model)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }

            // 进度详情弹窗
            if let model = selectedProgressModel {
                TaskProgressView(
                    model: model,
                    isPresented: Binding(
                        get: { selectedProgressModel != nil },
                        set: { if !$0 { selectedProgressModel = nil } }
                    ),
                    viewModel: viewModel
                )
                .transition(.opacity)
            }
        }
        .fullScreenCover(item: $viewModel.selectedModel) { model in
            ModelViewer(model: model, isPresented: Binding(
                get: { viewModel.selectedModel != nil },
                set: { if !$0 { viewModel.selectedModel = nil } }
            ))
        }
    }

    private func handleModelTap(_ model: Model3D) {
        if model.status == .completed {
            viewModel.selectModel(model)
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                selectedProgressModel = model
            }
        }
    }
}

// MARK: - 空状态视图 - 移动端优化
struct EmptyStateView: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 140, height: 140)
                    .blur(radius: 50)
                
                Circle()
                    .strokeBorder(Color.blue.opacity(0.25), lineWidth: 2)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(
                            Animation.linear(duration: 3)
                                .repeatForever(autoreverses: false)
                        ) {
                            rotationAngle = 360
                        }
                    }
                
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .shadow(color: .blue.opacity(0.5), radius: 10)
            }
            
            Text("还没有模型")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(white: 0.55), .white]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("快去创建一个吧！")
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.55))
            
            Button(action: {}) {
                Text("创建3D模型")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .cornerRadius(8)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ModelsTab(viewModel: AppViewModel())
        .preferredColorScheme(.dark)
}
