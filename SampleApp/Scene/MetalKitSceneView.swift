#if os(iOS)

import SwiftUI
import MetalKit
import UIKit

struct MetalKitSceneView: UIViewRepresentable {
    var modelIdentifier: ModelIdentifier?

    class Coordinator: NSObject {
        var renderer: MetalKitSceneRenderer?
        
        var panGesture: UIPanGestureRecognizer?
        var pinchGesture: UIPinchGestureRecognizer?
        var rotationGesture: UIRotationGestureRecognizer?
        
        var lastPanOffset: SIMD2<Float> = SIMD2<Float>(0, 0)
        var lastScale: Float = 1.0
        var lastRotation: Angle = .zero
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: UIViewRepresentableContext<MetalKitSceneView>) -> MTKView {
        makeView(context.coordinator)
    }

    private func makeView(_ coordinator: Coordinator) -> MTKView {
        let metalKitView = MTKView()

        if let metalDevice = MTLCreateSystemDefaultDevice() {
            metalKitView.device = metalDevice
        }

        let renderer = MetalKitSceneRenderer(metalKitView)
        coordinator.renderer = renderer
        metalKitView.delegate = renderer

        Task {
            do {
                try await renderer?.load(modelIdentifier)
            } catch {
                print("Error loading model: \(error.localizedDescription)")
            }
        }
        
        // 添加手势识别器
        setupGestures(for: metalKitView, coordinator: coordinator)

        return metalKitView
    }
    
    private func setupGestures(for view: MTKView, coordinator: Coordinator) {
        // 拖拽手势
        let panGesture = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
        coordinator.panGesture = panGesture
        
        // 捏合手势（缩放）
        let pinchGesture = UIPinchGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePinch(_:)))
        view.addGestureRecognizer(pinchGesture)
        coordinator.pinchGesture = pinchGesture
        
        // 旋转手势
        let rotationGesture = UIRotationGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleRotation(_:)))
        view.addGestureRecognizer(rotationGesture)
        coordinator.rotationGesture = rotationGesture
        
        // 允许多个手势同时识别
        panGesture.delegate = coordinator
        pinchGesture.delegate = coordinator
        rotationGesture.delegate = coordinator
    }

    func updateUIView(_ view: MTKView, context: UIViewRepresentableContext<MetalKitSceneView>) {
        updateView(context.coordinator)
    }

    private func updateView(_ coordinator: Coordinator) {
        guard let renderer = coordinator.renderer else { return }
        Task {
            do {
                try await renderer.load(modelIdentifier)
            } catch {
                print("Error loading model: \(error.localizedDescription)")
            }
        }
    }
}

extension MetalKitSceneView.Coordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let renderer = renderer else { return }
        guard let view = gesture.view else { return }
        
        let translation = gesture.translation(in: view)
        let scaleFactor: Float = 0.01  // 调整平移灵敏度
        
        switch gesture.state {
        case .began:
            lastPanOffset = renderer.panOffset
        case .changed:
            let deltaX = Float(translation.x) * scaleFactor
            let deltaY = -Float(translation.y) * scaleFactor  // 反转 Y 轴
            renderer.updatePan(offset: lastPanOffset + SIMD2<Float>(deltaX, deltaY))
        case .ended, .cancelled:
            // 保存最终位置
            lastPanOffset = renderer.panOffset
            gesture.setTranslation(.zero, in: view)
            renderer.resetGestureState()
        default:
            break
        }
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let renderer = renderer else { return }
        
        switch gesture.state {
        case .began:
            lastScale = renderer.scale
        case .changed:
            let newScale = lastScale * Float(gesture.scale)
            // 限制缩放范围
            let clampedScale = max(0.1, min(5.0, newScale))
            renderer.updateScale(clampedScale)
        case .ended, .cancelled:
            renderer.resetGestureState()
        default:
            break
        }
    }
    
    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let renderer = renderer else { return }
        
        switch gesture.state {
        case .began:
            lastRotation = renderer.gestureRotation
        case .changed:
            let deltaRotation = Angle(radians: Double(gesture.rotation))
            renderer.updateRotation(lastRotation + deltaRotation)
        case .ended, .cancelled:
            renderer.resetGestureState()
        default:
            break
        }
    }
}

#endif // os(iOS)
