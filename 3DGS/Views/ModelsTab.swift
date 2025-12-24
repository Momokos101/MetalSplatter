//
//  ModelsTab.swift
//  3DGS Scanner
//
//  模型库界面 - 真正的移动端布局
//

import SwiftUI

struct ModelsTab: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // 标题区域 - 移动端样式
                VStack(alignment: .leading, spacing: 4) {
                    AnimatedTitle(
                        text: "我的模型",
                        colors: [.white, .blue, .cyan, .blue, .white]
                    )
                    
                    AnimatedUnderline()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .padding(.bottom, 12)
                
                // 模型网格 - 移动端2列布局
                if viewModel.models.isEmpty {
                    EmptyStateView()
                        .padding(.top, 60)
                        .padding(.bottom, 16)
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ],
                        spacing: 8
                    ) {
                        ForEach(Array(viewModel.models.enumerated()), id: \.element.id) { index, model in
                            ModelCard(model: model) {
                                viewModel.selectModel(model)
                            }
                            .transition(.scale.combined(with: .opacity))
                            .animation(
                                .spring(response: 0.4)
                                    .delay(Double(index) * 0.03),
                                value: viewModel.models.count
                            )
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .fullScreenCover(item: $viewModel.selectedModel) { model in
            ModelViewer(model: model, isPresented: Binding(
                get: { viewModel.selectedModel != nil },
                set: { if !$0 { viewModel.selectedModel = nil } }
            ))
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
