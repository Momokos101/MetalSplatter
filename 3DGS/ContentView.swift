import SwiftUI
import UIKit

// MARK: - 颜色定义
extension Color {
    static let cyberCyan = Color(red: 0/255, green: 212/255, blue: 255/255)      // #00D4FF
    static let cyberPink = Color(red: 255/255, green: 0/255, blue: 255/255)      // #FF00FF
    static let cyberGreen = Color(red: 0/255, green: 255/255, blue: 136/255)     // #00FF88
    static let cyberPurple = Color(red: 88/255, green: 86/255, blue: 214/255)    // #5856D6
    static let cyberBlue = Color(red: 0/255, green: 122/255, blue: 255/255)      // #007AFF
}

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // 背景层
            Color.black
                .ignoresSafeArea()
            
            // 轻量级科技感背景
            LightTechBackground()
            
            // 主内容区
            VStack(spacing: 0) {
                // Tab内容
                Group {
                    if selectedTab == 0 {
                        UploadTab(viewModel: viewModel)
                    } else {
                        ModelsTab(viewModel: viewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // 底部Tab栏
                MobileTabBar(selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.startAnimation()
        }
    }
}

// MARK: - 轻量级科技感背景
struct LightTechBackground: View {
    @State private var gridOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 网格背景
            GeometryReader { geometry in
                Canvas { context, size in
                    let gridSize: CGFloat = 30
                    
                    // 垂直线
                    for x in stride(from: 0, to: size.width, by: gridSize) {
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        context.stroke(path, with: .color(Color.cyan.opacity(0.08)), lineWidth: 0.5)
                    }
                    
                    // 水平线
                    for y in stride(from: 0, to: size.height, by: gridSize) {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        context.stroke(path, with: .color(Color.cyan.opacity(0.08)), lineWidth: 0.5)
                    }
                }
            }
            
            // 浮动粒子（少量）
            FloatingParticlesView()
                .opacity(0.4)
        }
    }
}

// MARK: - 浮动粒子视图（轻量级）
struct FloatingParticlesView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<12, id: \.self) { i in
                    FloatingParticle(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height),
                        delay: Double.random(in: 0...2),
                        duration: Double.random(in: 4...7)
                    )
                }
            }
        }
    }
}

struct FloatingParticle: View {
    let x: CGFloat
    let y: CGFloat
    let delay: Double
    let duration: Double
    
    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(Color.cyan.opacity(0.6))
            .frame(width: 2, height: 2)
            .shadow(color: Color.cyan, radius: 3)
            .offset(x: x + offsetX, y: y + offsetY)
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    opacity = 1
                    
                    withAnimation(
                        Animation.linear(duration: duration)
                            .repeatForever(autoreverses: false)
                    ) {
                        if let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = screen.windows.first {
                            offsetY = -window.bounds.height - 50
                        } else {
                            offsetY = -800
                        }
                        offsetX = CGFloat.random(in: -15...15)
                    }
                }
            }
    }
}

// MARK: - 移动端Tab栏
struct MobileTabBar: View {
    @Binding var selectedTab: Int
    @State private var glowOffset: CGFloat = -200
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部分隔线
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.cyan.opacity(0.25),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    Color.cyan,
                                    Color.pink,
                                    Color.cyan,
                                    Color.clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 80, height: 0.5)
                        .offset(x: glowOffset)
                        .blur(radius: 1)
                )
                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 2.5)
                            .repeatForever(autoreverses: false)
                    ) {
                        if let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = screen.windows.first {
                            glowOffset = window.bounds.width + 100
                        } else {
                            glowOffset = 500
                        }
                    }
                }
            
            // Tab按钮
            HStack(spacing: 0) {
                TabButton(
                    icon: "video.fill",
                    title: "创建",
                    isSelected: selectedTab == 0,
                    action: { withAnimation(.spring(response: 0.25)) { selectedTab = 0 } }
                )
                
                TabButton(
                    icon: "square.grid.3x3.fill",
                    title: "模型",
                    isSelected: selectedTab == 1,
                    action: { withAnimation(.spring(response: 0.25)) { selectedTab = 1 } }
                )
            }
            .frame(height: 56)
            .background(
                ZStack {
                    Color.black.opacity(0.98)
                        .background(.ultraThinMaterial)
                    
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.cyan,
                                        Color.pink,
                                        Color.cyan
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width / 2 - 12, height: 2)
                            .shadow(color: Color.cyan.opacity(0.6), radius: 3)
                            .offset(
                                x: selectedTab == 0 ? 6 : geometry.size.width / 2 + 6,
                                y: 0
                            )
                            .animation(.spring(response: 0.25), value: selectedTab)
                    }
                }
            )
        }
        .background(Color.black)
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Tab按钮
struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack {
                    if isSelected {
                        Circle()
                            .stroke(Color.cyan.opacity(0.25), lineWidth: 1.5)
                            .frame(width: 36, height: 36)
                            .scaleEffect(pulseScale)
                            .opacity(2 - pulseScale)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? Color.cyan : Color(white: 0.45))
                        .shadow(
                            color: isSelected ? Color.cyan.opacity(0.6) : .clear,
                            radius: isSelected ? 8 : 0
                        )
                }
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? Color.cyan : Color(white: 0.45))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if isSelected {
                withAnimation(
                    Animation.easeOut(duration: 1.8)
                        .repeatForever(autoreverses: false)
                ) {
                    pulseScale = 1.4
                }
            }
        }
        .onChange(of: isSelected) { oldValue, newValue in
            if newValue {
                pulseScale = 1.0
                withAnimation(
                    Animation.easeOut(duration: 1.8)
                        .repeatForever(autoreverses: false)
                ) {
                    pulseScale = 1.4
                }
            } else {
                pulseScale = 1.0
            }
        }
    }
}

// MARK: - 动画标题（共享组件）
struct AnimatedTitle: View {
    let text: String
    let colors: [Color]
    
    @State private var gradientOffset: CGFloat = -1
    
    init(text: String, colors: [Color] = [.white, .cyan, .pink, .cyan, .white]) {
        self.text = text
        self.colors = colors
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: colors),
                    startPoint: UnitPoint(x: gradientOffset, y: 0),
                    endPoint: UnitPoint(x: gradientOffset + 1, y: 0)
                )
            )
            .minimumScaleFactor(0.8)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 3)
                        .repeatForever(autoreverses: false)
                ) {
                    gradientOffset = 2
                }
            }
    }
}

// MARK: - 动画下划线
struct AnimatedUnderline: View {
    @State private var width: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue,
                        Color.cyan,
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: 1)
            .onAppear {
                withAnimation(
                    Animation.easeOut(duration: 1)
                        .repeatForever(autoreverses: true)
                ) {
                    width = 60
                }
            }
    }
}

#Preview {
    ContentView()
}
