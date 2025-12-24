//
//  SplatSceneRenderer.swift
//  3DGS Scanner
//
//  Metal Splatter 渲染器

import Metal
import MetalKit
import MetalSplatter
import simd

class SplatSceneRenderer: NSObject {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let metalKitView: MTKView

    var splatRenderer: SplatRenderer?
    var drawableSize: CGSize = .zero

    // 变换参数
    var panOffset: SIMD2<Float> = .zero
    var scale: Float = 1.0
    var rotationX: Float = 0  // 绕 X 轴旋转（上下）
    var rotationY: Float = 0  // 绕 Y 轴旋转（左右）

    private let inFlightSemaphore = DispatchSemaphore(value: 3)
    private var currentModelURL: URL?

    // 重置变换
    func resetTransform() {
        panOffset = .zero
        scale = 1.0
        rotationX = 0
        rotationY = 0
    }

    init?(_ view: MTKView) {
        guard let device = view.device,
              let queue = device.makeCommandQueue() else {
            return nil
        }

        self.device = device
        self.commandQueue = queue
        self.metalKitView = view

        view.colorPixelFormat = .bgra8Unorm_srgb
        view.depthStencilPixelFormat = .depth32Float
        view.sampleCount = 1
    }

    func loadModel(from url: URL) async throws {
        guard url != currentModelURL else { return }
        currentModelURL = url

        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ File does not exist at: \(url.path)")
            throw NSError(domain: "SplatRenderer", code: 1, userInfo: [NSLocalizedDescriptionKey: "File not found"])
        }

        // 检查文件大小
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            print("📊 PLY file size: \(size) bytes")
        }

        // 读取文件头部检查格式
        if let handle = FileHandle(forReadingAtPath: url.path) {
            let headerData = handle.readData(ofLength: 500)
            if let headerStr = String(data: headerData, encoding: .ascii) {
                print("📄 PLY Header preview:\n\(headerStr.prefix(400))")
            }
            handle.closeFile()
        }

        let renderer = try await SplatRenderer(
            device: device,
            colorFormat: metalKitView.colorPixelFormat,
            depthFormat: metalKitView.depthStencilPixelFormat,
            sampleCount: metalKitView.sampleCount,
            maxViewCount: 1,
            maxSimultaneousRenders: 3
        )

        try await renderer.read(from: url)
        self.splatRenderer = renderer
    }

    func draw(in view: MTKView) {
        guard let splatRenderer = splatRenderer else { return }
        guard let drawable = view.currentDrawable else { return }

        _ = inFlightSemaphore.wait(timeout: .distantFuture)

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            inFlightSemaphore.signal()
            return
        }

        let semaphore = inFlightSemaphore
        commandBuffer.addCompletedHandler { _ in
            semaphore.signal()
        }

        let viewport = makeViewport()

        do {
            try splatRenderer.render(
                viewports: [viewport],
                colorTexture: view.multisampleColorTexture ?? drawable.texture,
                colorStoreAction: view.multisampleColorTexture == nil ? .store : .multisampleResolve,
                depthTexture: view.depthStencilTexture,
                rasterizationRateMap: nil,
                renderTargetArrayLength: 0,
                to: commandBuffer
            )
        } catch {
            print("Render error: \(error)")
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func makeViewport() -> SplatRenderer.ViewportDescriptor {
        let aspect = Float(drawableSize.width / drawableSize.height)
        let fovy = Float(65.0 * .pi / 180.0)

        let projectionMatrix = matrix_perspective_right_hand(
            fovyRadians: fovy,
            aspectRatio: aspect,
            nearZ: 0.1,
            farZ: 100.0
        )

        // 绕 Y 轴旋转（左右拖动）
        let rotationMatrixY = matrix4x4_rotation(
            radians: rotationY,
            axis: SIMD3<Float>(0, 1, 0)
        )

        // 绕 X 轴旋转（上下拖动）
        let rotationMatrixX = matrix4x4_rotation(
            radians: rotationX,
            axis: SIMD3<Float>(1, 0, 0)
        )

        // 组合旋转：先绕 X 轴，再绕 Y 轴
        let rotationMatrix = rotationMatrixY * rotationMatrixX

        // 相机距离根据缩放调整
        let cameraDistance: Float = 3.0 / scale
        let translationMatrix = matrix4x4_translation(panOffset.x, panOffset.y, -cameraDistance)

        // 校准矩阵
        let calibration = matrix4x4_rotation(radians: .pi, axis: SIMD3<Float>(0, 0, 1))

        let viewport = MTLViewport(
            originX: 0, originY: 0,
            width: drawableSize.width, height: drawableSize.height,
            znear: 0, zfar: 1
        )

        return SplatRenderer.ViewportDescriptor(
            viewport: viewport,
            projectionMatrix: projectionMatrix,
            viewMatrix: translationMatrix * rotationMatrix * calibration,
            screenSize: SIMD2(x: Int(drawableSize.width), y: Int(drawableSize.height))
        )
    }
}
