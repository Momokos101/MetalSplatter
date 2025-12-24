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
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 背景层
                Color.black
                    .ignoresSafeArea()

                // 轻量级科技感背景
                LightTechBackground()
                    .ignoresSafeArea()

                // Tab 内容区
                VStack(spacing: 0) {
                    if selectedTab == 0 {
                        UploadTab(viewModel: viewModel)
                    } else {
                        ModelsTab(viewModel: viewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 70 + geometry.safeAreaInsets.bottom)

                // 底部 Tab 栏 - 固定在底部
                GlassTabBar(selectedTab: $selectedTab)
                    .ignoresSafeArea(.all, edges: .bottom)
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

// MARK: - 毛玻璃 Tab 栏
struct GlassTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var animation

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 发光顶部边框
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.6), .purple.opacity(0.4), .cyan.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .shadow(color: .cyan.opacity(0.5), radius: 4, y: -2)

                // Tab 按钮
                HStack(spacing: 0) {
                    GlassTabItem(
                        icon: "video.fill",
                        title: "创建",
                        isSelected: selectedTab == 0,
                        namespace: animation
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = 0
                        }
                    }

                    GlassTabItem(
                        icon: "cube.transparent",
                        title: "模型",
                        isSelected: selectedTab == 1,
                        namespace: animation
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = 1
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
            }
            .background(
                ZStack {
                    // 深色背景
                    Color.black.opacity(0.8)
                    // 毛玻璃效果
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)
                }
            )
        }
        .frame(height: 70)
    }
}

// MARK: - Tab 项目
struct GlassTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // 选中背景光晕
                    if isSelected {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.cyan.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 25
                                )
                            )
                            .frame(width: 50, height: 50)
                            .matchedGeometryEffect(id: "glow", in: namespace)
                    }

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(
                            isSelected
                                ? LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [.gray, .gray], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: isSelected ? .cyan.opacity(0.8) : .clear, radius: 8)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }

                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .cyan : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
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
