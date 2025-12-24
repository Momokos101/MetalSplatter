//
//  ModelViewer.swift
//  3DGS Scanner
//
//  3D模型查看器 - 显示和交互3D点云
//  TODO: 集成 Metal 渲染引擎和 3D Gaussian Splatting
//

import SwiftUI

struct ModelViewer: View {
    let model: Model3D
    @Binding var isPresented: Bool
    
    @State private var rotation = CGSize.zero
    @State private var lastRotation = CGSize.zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var showHint = true
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Animated grid background
            AnimatedGrid()
            
            // Radial glow
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 500, height: 500)
                .blur(radius: 100)
                .animation(
                    Animation.easeInOut(duration: 3)
                        .repeatForever(autoreverses: true),
                    value: scale
                )
            
            // 3D Point Cloud Visualization
            ZStack {
                // Orbit rings
                Circle()
                    .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                    .frame(width: 600, height: 600)
                    .rotationEffect(.degrees(rotation.width * 0.5))
                    .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: rotation)
                
                Circle()
                    .strokeBorder(Color.purple.opacity(0.2), lineWidth: 1)
                    .frame(width: 400, height: 400)
                    .rotationEffect(.degrees(-rotation.width * 0.3))
                    .animation(.linear(duration: 15).repeatForever(autoreverses: false), value: rotation)
                
                // Point cloud
                PointCloudView(rotation: rotation, scale: scale)
                    .frame(width: 320, height: 320)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        rotation = CGSize(
                            width: lastRotation.width + value.translation.width,
                            height: lastRotation.height + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        lastRotation = rotation
                        showHint = false
                    }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = lastScale * value
                    }
                    .onEnded { _ in
                        lastScale = scale
                        showHint = false
                    }
            )
            
            // First-time hint
            if showHint {
                VStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        
                        Text("单指旋转，双指缩放")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.8))
                            .background(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 30)
                    )
                }
                .transition(.opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showHint = false
                        }
                    }
                }
            }
            
            // Top controls
            VStack {
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "arrow.left")
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
                            .shadow(color: .blue.opacity(0.3), radius: 15)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Spacer()
                }
                .padding()
                .padding(.top, 8)
                
                Spacer()
            }
            
            // Bottom toolbar
            VStack {
                Spacer()
                
                HStack(spacing: 24) {
                    Button(action: resetView) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            
                            Text("重置视角")
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 1, height: 24)
                    
                    Text("\(Int(scale * 100))%")
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundColor(Color(white: 0.6))
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.8),
                            Color(red: 0.11, green: 0.11, blue: 0.12).opacity(0.9),
                            Color.black.opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        VStack {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.clear,
                                            Color.blue,
                                            Color.clear
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 1)
                            Spacer()
                        }
                    )
                    .shadow(color: .blue.opacity(0.2), radius: 30)
                )
                .padding(.bottom, 32)
            }
        }
    }
    
    private func resetView() {
        withAnimation(.spring()) {
            rotation = .zero
            lastRotation = .zero
            scale = 1.0
            lastScale = 1.0
        }
    }
}

// MARK: - Animated Grid Background
struct AnimatedGrid: View {
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let gridSize: CGFloat = 50
                
                // Vertical lines
                var x: CGFloat = offset.truncatingRemainder(dividingBy: gridSize)
                while x <= geometry.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    x += gridSize
                }
                
                // Horizontal lines
                var y: CGFloat = offset.truncatingRemainder(dividingBy: gridSize)
                while y <= geometry.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    y += gridSize
                }
            }
            .stroke(Color.blue.opacity(0.1), lineWidth: 1)
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                offset = 50
            }
        }
    }
}

// MARK: - Point Cloud View
struct PointCloudView: View {
    let rotation: CGSize
    let scale: CGFloat
    
    var body: some View {
        ZStack {
            // Center core glow
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 80, height: 80)
                .blur(radius: 40)
            
            // Point cloud particles
            ForEach(0..<300, id: \.self) { index in
                PointParticle(
                    index: index,
                    rotation: rotation,
                    scale: scale
                )
            }
        }
        .rotation3DEffect(
            .degrees(Double(rotation.height) * 0.5),
            axis: (x: 1, y: 0, z: 0)
        )
        .rotation3DEffect(
            .degrees(Double(rotation.width) * 0.5),
            axis: (x: 0, y: 1, z: 0)
        )
        .scaleEffect(scale)
    }
}

// MARK: - Point Particle
struct PointParticle: View {
    let index: Int
    let rotation: CGSize
    let scale: CGFloat
    
    private var position: (x: CGFloat, y: CGFloat, z: CGFloat) {
        let angle = CGFloat(index) / 300.0 * .pi * 2
        let radius = 50 + CGFloat.random(in: 0...50)
        let height = CGFloat.random(in: -50...50)
        
        return (
            x: cos(angle) * radius,
            y: height,
            z: sin(angle) * radius
        )
    }
    
    private var size: CGFloat {
        CGFloat.random(in: 2...5)
    }
    
    private var hue: CGFloat {
        200 + CGFloat.random(in: 0...40)
    }
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(hue: hue / 360, saturation: 1, brightness: 1),
                        Color(hue: hue / 360, saturation: 1, brightness: 0.6)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: size
                )
            )
            .frame(width: size, height: size)
            .shadow(color: Color(hue: hue / 360, saturation: 1, brightness: 1), radius: size * 2)
            .offset(x: position.x, y: position.y)
            .opacity(0.4 + CGFloat.random(in: 0...0.6))
    }
}

#Preview {
    ModelViewer(
        model: Model3D(
            id: "1",
            name: "测试模型",
            thumbnail: "",
            type: "视频",
            timestamp: Date(),
            status: .completed
        ),
        isPresented: .constant(true)
    )
}
