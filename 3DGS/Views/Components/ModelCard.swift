//
//  ModelCard.swift
//  3DGS Scanner
//
//  模型卡片组件 - 移动端优化版本
//

import SwiftUI

struct ModelCard: View {
    let model: Model3D
    let action: () -> Void
    
    @State private var scanPosition: CGFloat = -1
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                ModelCardThumbnail(model: model, scanPosition: $scanPosition)
                ModelCardInfo(model: model)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.11, green: 0.11, blue: 0.12),
                        Color(red: 0.17, green: 0.17, blue: 0.18)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .shadow(color: .blue.opacity(0.15), radius: 6)
        .disabled(model.status != .completed)
    }
}

// MARK: - Model Card Thumbnail
struct ModelCardThumbnail: View {
    let model: Model3D
    @Binding var scanPosition: CGFloat
    
    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.11, green: 0.11, blue: 0.12),
                            Color(red: 0.17, green: 0.17, blue: 0.18)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // 轻量级网格
            ModelCardGrid()
            
            // Content based on status
            ModelCardContent(model: model, scanPosition: $scanPosition)
            
            // Status badge
            VStack {
                HStack {
                    Spacer()
                    StatusBadge(status: model.status)
                        .padding(6)
                }
                Spacer()
            }
        }
        .aspectRatio(16/9, contentMode: .fill)
        .clipped()
    }
}

// MARK: - Model Card Grid
struct ModelCardGrid: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let gridSize: CGFloat = 15
                
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
    }
}

// MARK: - Model Card Content
struct ModelCardContent: View {
    let model: Model3D
    @Binding var scanPosition: CGFloat
    
    var body: some View {
        Group {
            switch model.status {
            case .completed:
                CompletedCardContent(scanPosition: $scanPosition)
            case .processing:
                ProcessingCardContent(scanPosition: $scanPosition)
            case .failed:
                FailedCardContent()
            }
        }
    }
}

// MARK: - Completed Card Content
struct CompletedCardContent: View {
    @Binding var scanPosition: CGFloat
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)
            
            Image(systemName: "cube.transparent.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue.opacity(0.4))
            
            // 扫描线动画
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0),
                            Color.cyan.opacity(0.3),
                            Color.blue.opacity(0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 30)
                .offset(y: scanPosition * 150)
                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 2)
                            .repeatForever(autoreverses: false)
                    ) {
                        scanPosition = 1
                    }
                }
        }
    }
}

// MARK: - Processing Card Content
struct ProcessingCardContent: View {
    @Binding var scanPosition: CGFloat
    
    var body: some View {
        ZStack {
            // 旋转加载环
            ZStack {
                Circle()
                    .strokeBorder(Color.cyan.opacity(0.2), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.cyan, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .rotationEffect(.degrees(scanPosition * 360))
                
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 18))
                    .foregroundColor(.cyan)
            }
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 2)
                        .repeatForever(autoreverses: false)
                ) {
                    scanPosition = 1
                }
            }
            
            // 浮动粒子
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.8),
                                Color.blue.opacity(0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 3, height: 3)
                    .offset(
                        x: CGFloat(15 + index * 12),
                        y: scanPosition * -80
                    )
                    .opacity(1.0 - abs(scanPosition))
                    .animation(
                        Animation.linear(duration: 2.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.2),
                        value: scanPosition
                    )
            }
        }
    }
}

// MARK: - Failed Card Content
struct FailedCardContent: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundColor(.red.opacity(0.7))
            Text("加载失败")
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.5))
        }
    }
}

// MARK: - Model Card Info
struct ModelCardInfo: View {
    let model: Model3D
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(model.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("\(model.timestamp.timeAgoDisplay()) · \(model.type)")
                .font(.system(size: 11))
                .foregroundColor(Color(white: 0.55))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 10)
        .padding(.trailing, 10)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.11, green: 0.11, blue: 0.12).opacity(0.9),
                    Color.clear
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: ModelStatus
    
    var body: some View {
        HStack(spacing: 3) {
            if status == .processing {
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 5, height: 5)
            }
            
            Text(statusText)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(backgroundColor)
                .shadow(color: shadowColor, radius: 4)
        )
    }
    
    private var statusText: String {
        switch status {
        case .processing: return "处理中"
        case .completed: return "已完成"
        case .failed: return "失败"
        }
    }
    
    private var backgroundColor: Color {
        switch status {
        case .processing: return Color.cyan.opacity(0.8)
        case .completed: return Color.green.opacity(0.8)
        case .failed: return Color.red.opacity(0.8)
        }
    }
    
    private var shadowColor: Color {
        switch status {
        case .processing: return .cyan.opacity(0.5)
        case .completed: return .green.opacity(0.5)
        case .failed: return .red.opacity(0.5)
        }
    }
}

// MARK: - Date Extension
extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    VStack {
        HStack(spacing: 8) {
            ModelCard(
                model: Model3D(
                    id: "1",
                    name: "客厅场景",
                    thumbnail: "",
                    type: "视频",
                    timestamp: Date(),
                    status: .completed
                ),
                action: {}
            )
            
            ModelCard(
                model: Model3D(
                    id: "2",
                    name: "处理中模型",
                    thumbnail: "",
                    type: "连拍",
                    timestamp: Date(),
                    status: .processing
                ),
                action: {}
            )
        }
        .padding(8)
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}
