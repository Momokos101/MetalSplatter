//
//  AppViewModel.swift
//  3DGS Scanner
//
//  主视图模型 - 管理应用状态
//

import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var models: [Model3D] = []
    @Published var uploadProgress: UploadProgress?
    @Published var showVideoRecording = false
    @Published var showPhotoCapture = false
    @Published var showGallery = false
    @Published var selectedModel: Model3D?
    @Published var animationTrigger = false
    
    // MARK: - Private Properties
    private var uploadTimer: Timer?  // ✅ 添加：存储Timer引用，便于取消
    
    // MARK: - Initialization
    init() {
        loadMockData()
    }
    
    // MARK: - Animation
    func startAnimation() {
        animationTrigger.toggle()
    }
    
    // MARK: - Upload Actions
    func startVideoRecording() {
        showVideoRecording = true
    }
    
    func startPhotoCapture() {
        showPhotoCapture = true
    }
    
    func startGallerySelection() {
        showGallery = true
    }
    
    func handleUpload(fileName: String) {
        uploadProgress = UploadProgress(fileName: fileName, progress: 0)
        simulateUpload()
    }
    
    func cancelUpload() {
        uploadTimer?.invalidate()  // ✅ 添加：取消Timer
        uploadProgress = nil
    }
    
    // MARK: - Model Selection
    func selectModel(_ model: Model3D) {
        if model.status == .completed {
            selectedModel = model
        }
    }
    
    // MARK: - Private Methods
    private func simulateUpload() {
        guard uploadProgress != nil else { return }
        
        uploadTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, var currentProgress = self.uploadProgress else {
                timer.invalidate()
                return
            }
            
            currentProgress.progress += 2
            
            if currentProgress.progress >= 100 {
                currentProgress.progress = 100
                timer.invalidate()
                
                // 添加新模型
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    let newModel = Model3D(
                        id: UUID().uuidString,
                        name: currentProgress.fileName.replacingOccurrences(of: ".mp4", with: ""),
                        thumbnail: "sample_thumbnail",
                        type: "视频",
                        timestamp: Date(),
                        status: .processing
                    )
                    self.models.insert(newModel, at: 0)
                    self.uploadProgress = nil
                    
                    // 模拟处理完成
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if let index = self.models.firstIndex(where: { $0.id == newModel.id }) {
                            self.models[index].status = .completed
                        }
                    }
                }
            } else {
                self.uploadProgress = currentProgress
            }
        }
    }
    
    private func loadMockData() {
        models = [
            Model3D(
                id: "1",
                name: "客厅场景",
                thumbnail: "sample_thumbnail",
                type: "视频",
                timestamp: Date().addingTimeInterval(-3600),
                status: .completed
            ),
            Model3D(
                id: "2",
                name: "雕塑模型",
                thumbnail: "sample_thumbnail",
                type: "连拍",
                timestamp: Date().addingTimeInterval(-7200),
                status: .completed
            ),
            Model3D(
                id: "3",
                name: "建筑外观",
                thumbnail: "sample_thumbnail",
                type: "视频",
                timestamp: Date().addingTimeInterval(-86400),
                status: .processing
            )
        ]
    }
}

// MARK: - Models
struct Model3D: Identifiable {
    let id: String
    var name: String
    var thumbnail: String
    var type: String
    var timestamp: Date
    var status: ModelStatus
}

enum ModelStatus {
    case processing
    case completed
    case failed
}

struct UploadProgress {
    var fileName: String
    var progress: Int
}