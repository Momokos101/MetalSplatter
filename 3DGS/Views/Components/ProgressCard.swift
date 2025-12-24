//
//  ProgressCard.swift
//  3DGS Scanner
//
//  上传进度卡片 - 移动端优化版本
//

import SwiftUI

struct ProgressCard: View {
    let fileName: String
    let progress: Int
    let onCancel: () -> Void
    
    @State private var scanOffset: CGFloat = -200
    @State private var shimmerOffset: CGFloat = -100
    @State private var borderGlow: Double = 0.4
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.11, green: 0.11, blue: 0.12).opacity(0.95),
                    Color(red: 0.17, green: 0.17, blue: 0.18).opacity(0.95)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(12)
            .background(.ultraThinMaterial)
            
            // Border
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.cyan.opacity(0.3), lineWidth: 1)
            
            // 扫描线效果
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.cyan.opacity(0.3),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .offset(x: scanOffset)
                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 2.5)
                            .repeatForever(autoreverses: false)
                    ) {
                        scanOffset = 400
                    }
                }
            
            // Content
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        // 状态标签
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 6, height: 6)
                                .shadow(color: Color.cyan, radius: 4)
                            
                            Text("上传中")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.cyan)
                        }
                        
                        Text(fileName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 取消按钮
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.red.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                // Progress Bar
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(white: 0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.cyan.opacity(0.2), lineWidth: 1)
                        )
                        .frame(height: 10)
                    
                    // Progress Fill
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 渐变填充
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan,
                                    Color.blue,
                                    Color.cyan
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .cornerRadius(6)
                            .frame(width: geometry.size.width * CGFloat(progress) / 100)
                            .shadow(color: Color.cyan.opacity(0.6), radius: 8)
                            
                            // Shimmer 闪光效果
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.clear,
                                            Color.white.opacity(0.4),
                                            Color.clear
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 60)
                                .offset(x: shimmerOffset)
                                .mask(
                                    Rectangle()
                                        .frame(width: geometry.size.width * CGFloat(progress) / 100)
                                )
                                .onAppear {
                                    withAnimation(
                                        Animation.linear(duration: 1.5)
                                            .repeatForever(autoreverses: false)
                                    ) {
                                        shimmerOffset = geometry.size.width + 100
                                    }
                                }
                        }
                    }
                    .frame(height: 10)
                    
                    // 动画边框发光
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.cyan.opacity(borderGlow), lineWidth: 1.5)
                        .frame(height: 10)
                        .onAppear {
                            withAnimation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                            ) {
                                borderGlow = 0.8
                            }
                        }
                }
                
                // 进度信息
                HStack {
                    Text("\(progress)%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.cyan)
                    
                    Spacer()
                    
                    Text("\(progress)/100")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.5))
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 12)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .shadow(color: Color.cyan.opacity(0.2), radius: 12)
    }
}

#Preview {
    VStack(spacing: 12) {
        ProgressCard(
            fileName: "video_recording_2024.mp4",
            progress: 45,
            onCancel: {}
        )
        
        ProgressCard(
            fileName: "scene_capture_001.mp4",
            progress: 85,
            onCancel: {}
        )
    }
    .padding(16)
    .background(Color.black)
    .preferredColorScheme(.dark)
}
