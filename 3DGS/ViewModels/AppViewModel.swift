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
    private var uploadTimer: Timer?
    private var pollingTimers: [String: Timer] = [:]
    private let apiService = APIService.shared
    @Published var errorMessage: String?
    @Published var isServerOnline = false
    
    // MARK: - Initialization
    init() {
        loadMockData()
        checkServerHealth()
        resumePollingForProcessingModels()
    }

    // MARK: - Server Health
    func checkServerHealth() {
        Task {
            do {
                let isOnline = try await apiService.checkHealth()
                await MainActor.run {
                    self.isServerOnline = isOnline
                }
            } catch {
                await MainActor.run {
                    self.isServerOnline = false
                }
            }
        }
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
        uploadProgress = UploadProgress(fileName: fileName, progress: 0, stage: "准备上传...")
    }

    // MARK: - Video Upload
    func uploadVideo(url: URL) {
        let fileName = url.lastPathComponent
        uploadProgress = UploadProgress(fileName: fileName, progress: 0, stage: "正在上传...")

        Task {
            do {
                let response = try await apiService.uploadVideo(videoURL: url, fastMode: true)

                await MainActor.run {
                    self.uploadProgress = nil

                    let newModel = Model3D(
                        id: UUID().uuidString,
                        taskId: response.taskId,
                        name: fileName.replacingOccurrences(of: ".mp4", with: "")
                            .replacingOccurrences(of: ".mov", with: ""),
                        thumbnail: "sample_thumbnail",
                        type: "视频",
                        timestamp: Date(),
                        status: .queued,
                        plyPath: nil,
                        stage: "排队中",
                        errorMessage: nil
                    )
                    self.models.insert(newModel, at: 0)
                    self.saveModelsToStorage()
                    self.startPolling(for: response.taskId)
                }
            } catch {
                await MainActor.run {
                    self.uploadProgress = nil
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Images Upload
    func uploadImages(urls: [URL]) {
        let fileName = "连拍_\(urls.count)张"
        uploadProgress = UploadProgress(fileName: fileName, progress: 0, stage: "正在上传...")

        Task {
            do {
                let response = try await apiService.uploadImages(imageURLs: urls)

                await MainActor.run {
                    self.uploadProgress = nil

                    let newModel = Model3D(
                        id: UUID().uuidString,
                        taskId: response.taskId,
                        name: fileName,
                        thumbnail: "sample_thumbnail",
                        type: "连拍",
                        timestamp: Date(),
                        status: .queued,
                        plyPath: nil,
                        stage: "排队中",
                        errorMessage: nil
                    )
                    self.models.insert(newModel, at: 0)
                    self.saveModelsToStorage()
                    self.startPolling(for: response.taskId)
                }
            } catch {
                await MainActor.run {
                    self.uploadProgress = nil
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func cancelUpload() {
        uploadTimer?.invalidate()
        uploadProgress = nil
    }

    // MARK: - Model Selection
    func selectModel(_ model: Model3D) {
        if model.status == .completed {
            selectedModel = model
        }
    }

    // MARK: - Delete Model
    func deleteModel(_ model: Model3D) {
        Task {
            try? await apiService.deleteTask(taskId: model.taskId)
        }
        stopPolling(for: model.taskId)
        models.removeAll { $0.id == model.id }

        // Delete local PLY file if exists
        if let plyPath = model.plyPath {
            try? FileManager.default.removeItem(atPath: plyPath)
        }
        saveModelsToStorage()
    }

    // MARK: - Polling
    private func startPolling(for taskId: String) {
        let timer = Timer.scheduledTimer(withTimeInterval: APIConfig.pollingInterval, repeats: true) { [weak self] _ in
            self?.checkTaskStatus(taskId: taskId)
        }
        pollingTimers[taskId] = timer
    }

    private func stopPolling(for taskId: String) {
        pollingTimers[taskId]?.invalidate()
        pollingTimers.removeValue(forKey: taskId)
    }

    private func resumePollingForProcessingModels() {
        for model in models where model.status == .processing || model.status == .queued {
            startPolling(for: model.taskId)
        }
    }

    private func checkTaskStatus(taskId: String) {
        Task {
            do {
                let status = try await apiService.getTaskStatus(taskId: taskId)

                await MainActor.run {
                    self.updateModelStatus(taskId: taskId, status: status)
                }
            } catch {
                print("轮询任务状态失败: \(error)")
            }
        }
    }

    private func updateModelStatus(taskId: String, status: TaskStatus) {
        guard let index = models.firstIndex(where: { $0.taskId == taskId }) else { return }

        models[index].stage = status.message

        if status.isCompleted {
            models[index].status = .completed
            stopPolling(for: taskId)
            downloadModel(for: taskId)
        } else if status.isFailed {
            models[index].status = .failed
            models[index].errorMessage = status.error
            stopPolling(for: taskId)
        } else {
            models[index].status = .processing
        }

        saveModelsToStorage()
    }

    // MARK: - Download Model
    private func downloadModel(for taskId: String) {
        Task {
            do {
                let localURL = try await apiService.downloadModel(taskId: taskId)

                await MainActor.run {
                    if let index = self.models.firstIndex(where: { $0.taskId == taskId }) {
                        self.models[index].plyPath = localURL.path
                        self.saveModelsToStorage()
                    }
                }
            } catch {
                print("下载模型失败: \(error)")
            }
        }
    }
    
    private func loadMockData() {
        // 从本地存储加载模型列表
        loadModelsFromStorage()
    }

    // MARK: - Local Storage
    private var modelsStorageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("models.json")
    }

    private func loadModelsFromStorage() {
        guard FileManager.default.fileExists(atPath: modelsStorageURL.path) else {
            models = []
            return
        }

        do {
            let data = try Data(contentsOf: modelsStorageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            var loadedModels = try decoder.decode([Model3D].self, from: data)

            // 验证已完成模型的 PLY 文件是否存在
            loadedModels = loadedModels.filter { model in
                if model.status == .completed, let plyPath = model.plyPath {
                    let exists = FileManager.default.fileExists(atPath: plyPath)
                    if !exists {
                        print("⚠️ PLY file missing, removing model: \(model.name)")
                    }
                    return exists
                }
                return true // 保留未完成的模型
            }

            models = loadedModels
            saveModelsToStorage() // 保存清理后的列表
        } catch {
            print("加载模型列表失败: \(error)")
            models = []
        }
    }

    private func saveModelsToStorage() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(models)
            try data.write(to: modelsStorageURL)
        } catch {
            print("保存模型列表失败: \(error)")
        }
    }
}

// MARK: - Models
struct Model3D: Identifiable, Codable {
    let id: String
    var taskId: String
    var name: String
    var thumbnail: String
    var type: String
    var timestamp: Date
    var status: ModelStatus
    var plyPath: String?
    var stage: String?
    var errorMessage: String?
}

enum ModelStatus: String, Codable {
    case uploading
    case queued
    case processing
    case completed
    case failed
}

struct UploadProgress {
    var fileName: String
    var progress: Int
    var stage: String
}