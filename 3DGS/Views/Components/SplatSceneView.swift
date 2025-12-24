//
//  SplatSceneView.swift
//  3DGS Scanner
//
//  Metal Splatter 渲染视图

import SwiftUI
import MetalKit
import Metal
import MetalSplatter
import simd

struct SplatSceneView: UIViewRepresentable {
    let plyURL: URL?

    class Coordinator: NSObject, MTKViewDelegate, UIGestureRecognizerDelegate {
        var renderer: SplatSceneRenderer?

        // 单指拖动 -> 旋转模型
        var lastRotationX: Float = 0
        var lastRotationY: Float = 0

        // 双指拖动 -> 平移模型
        var lastPanOffset: SIMD2<Float> = .zero

        // 双指捏合 -> 缩放
        var lastScale: Float = 1.0

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            renderer?.drawableSize = size
        }

        func draw(in view: MTKView) {
            renderer?.draw(in: view)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            // 允许双指捏合和双指拖动同时进行
            if gestureRecognizer is UIPinchGestureRecognizer && other is UIPanGestureRecognizer {
                return true
            }
            if gestureRecognizer is UIPanGestureRecognizer && other is UIPinchGestureRecognizer {
                return true
            }
            return false
        }

        // 单指拖动 -> 旋转模型（更直观）
        @objc func handleOneFingerPan(_ gesture: UIPanGestureRecognizer) {
            guard let renderer = renderer, let view = gesture.view else { return }
            let translation = gesture.translation(in: view)
            let sensitivity: Float = 0.008

            switch gesture.state {
            case .began:
                lastRotationX = renderer.rotationX
                lastRotationY = renderer.rotationY
            case .changed:
                // 水平拖动 -> 绕 Y 轴旋转
                renderer.rotationY = lastRotationY + Float(translation.x) * sensitivity
                // 垂直拖动 -> 绕 X 轴旋转
                renderer.rotationX = lastRotationX + Float(translation.y) * sensitivity
            case .ended, .cancelled:
                lastRotationX = renderer.rotationX
                lastRotationY = renderer.rotationY
            default: break
            }
        }

        // 双指拖动 -> 平移模型
        @objc func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
            guard let renderer = renderer, let view = gesture.view else { return }
            let translation = gesture.translation(in: view)
            let sensitivity: Float = 0.005

            switch gesture.state {
            case .began:
                lastPanOffset = renderer.panOffset
            case .changed:
                let deltaX = Float(translation.x) * sensitivity
                let deltaY = -Float(translation.y) * sensitivity
                renderer.panOffset = lastPanOffset + SIMD2<Float>(deltaX, deltaY)
            case .ended, .cancelled:
                lastPanOffset = renderer.panOffset
            default: break
            }
        }

        // 双指捏合 -> 缩放
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let renderer = renderer else { return }

            switch gesture.state {
            case .began:
                lastScale = renderer.scale
            case .changed:
                renderer.scale = max(0.3, min(4.0, lastScale * Float(gesture.scale)))
            case .ended, .cancelled:
                lastScale = renderer.scale
            default: break
            }
        }

        // 双击重置视图
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let renderer = renderer else { return }
            renderer.resetTransform()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()

        guard let device = MTLCreateSystemDefaultDevice() else {
            print("❌ Failed to create Metal device")
            return view
        }

        view.device = device
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.depthStencilPixelFormat = .depth32Float
        view.clearColor = MTLClearColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        view.delegate = context.coordinator
        view.enableSetNeedsDisplay = false
        view.isPaused = false

        if let renderer = SplatSceneRenderer(view) {
            context.coordinator.renderer = renderer
            // 初始化 drawableSize
            renderer.drawableSize = view.drawableSize

            if let url = plyURL {
                print("📂 Loading PLY from: \(url.path)")
                Task {
                    do {
                        try await renderer.loadModel(from: url)
                        print("✅ Model loaded successfully")
                    } catch {
                        print("❌ Failed to load model: \(error)")
                    }
                }
            }
        } else {
            print("❌ Failed to create renderer")
        }

        setupGestures(view, context.coordinator)
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        if let url = plyURL {
            Task {
                try? await context.coordinator.renderer?.loadModel(from: url)
            }
        }
    }

    private func setupGestures(_ view: MTKView, _ coordinator: Coordinator) {
        // 单指拖动 -> 旋转模型
        let oneFingerPan = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleOneFingerPan))
        oneFingerPan.minimumNumberOfTouches = 1
        oneFingerPan.maximumNumberOfTouches = 1
        oneFingerPan.delegate = coordinator
        view.addGestureRecognizer(oneFingerPan)

        // 双指拖动 -> 平移模型
        let twoFingerPan = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleTwoFingerPan))
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        twoFingerPan.delegate = coordinator
        view.addGestureRecognizer(twoFingerPan)

        // 双指捏合 -> 缩放
        let pinch = UIPinchGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePinch))
        pinch.delegate = coordinator
        view.addGestureRecognizer(pinch)

        // 双击重置视图
        let doubleTap = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
    }
}
