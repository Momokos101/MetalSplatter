//
//  APIService.swift
//  3DGS Scanner
//
//  网络请求服务 - 对接后端 API
//

import Foundation
import UIKit

// MARK: - API Configuration
struct APIConfig {
    static let baseURL = "http://192.168.5.6:5000"
    static let maxFileSize = 500 * 1024 * 1024 // 500MB
    static let pollingInterval: TimeInterval = 2.0
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(String)
    case fileTooLarge
    case insufficientImages
    case taskNotFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .invalidResponse:
            return "服务器响应无效"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .fileTooLarge:
            return "文件大小超过500MB限制"
        case .insufficientImages:
            return "至少需要3张图片"
        case .taskNotFound:
            return "任务不存在"
        }
    }
}

// MARK: - API Response Models
struct UploadResponse: Codable {
    let message: String
    let taskId: String
    let filename: String?
    let type: String?
    let imageCount: Int?

    enum CodingKeys: String, CodingKey {
        case message
        case taskId = "task_id"
        case filename
        case type
        case imageCount = "image_count"
    }
}

struct TaskStatus: Codable {
    let status: String
    let stage: String?
    let progress: Int
    let message: String
    let filename: String?
    let createdAt: String?
    let updatedAt: String?
    let resultPath: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case status, stage, progress, message, filename
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case resultPath = "result_path"
        case error
    }

    var isCompleted: Bool { status == "done" }
    var isFailed: Bool { status == "error" }
    var isProcessing: Bool { status == "processing" || status == "queued" }
}

struct HealthResponse: Codable {
    let status: String
    let message: String
}

// MARK: - API Service
class APIService {
    static let shared = APIService()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 600
        self.session = URLSession(configuration: config)
    }

    // MARK: - Health Check
    func checkHealth() async throws -> Bool {
        guard let url = URL(string: "\(APIConfig.baseURL)/health") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return false
        }

        let healthResponse = try JSONDecoder().decode(HealthResponse.self, from: data)
        return healthResponse.status == "ok"
    }

    // MARK: - Upload Video
    func uploadVideo(
        videoURL: URL,
        iterations: Int = 7000,
        resolution: Int = 2,
        fastMode: Bool = true,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> UploadResponse {
        guard let url = URL(string: "\(APIConfig.baseURL)/upload") else {
            throw APIError.invalidURL
        }

        // Check file size
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: videoURL.path)
        let fileSize = fileAttributes[.size] as? Int ?? 0
        if fileSize > APIConfig.maxFileSize {
            throw APIError.fileTooLarge
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add video file
        let videoData = try Data(contentsOf: videoURL)
        let filename = videoURL.lastPathComponent
        let mimeType = getMimeType(for: videoURL)

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(videoData)
        body.append("\r\n")

        // Add iterations parameter
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"iterations\"\r\n\r\n")
        body.append("\(iterations)\r\n")

        // Add resolution parameter
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"resolution\"\r\n\r\n")
        body.append("\(resolution)\r\n")

        // Add fast mode parameter
        if fastMode {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"fast\"\r\n\r\n")
            body.append("true\r\n")
        }

        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode != 200 && httpResponse.statusCode != 202 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                throw APIError.serverError(errorMessage)
            }
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }

        return try JSONDecoder().decode(UploadResponse.self, from: data)
    }

    // MARK: - Upload Images
    func uploadImages(
        imageURLs: [URL],
        iterations: Int = 7000,
        resolution: Int = 2
    ) async throws -> UploadResponse {
        guard imageURLs.count >= 3 else {
            throw APIError.insufficientImages
        }

        guard let url = URL(string: "\(APIConfig.baseURL)/upload_images") else {
            throw APIError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add image files
        for imageURL in imageURLs {
            let imageData = try Data(contentsOf: imageURL)
            let filename = imageURL.lastPathComponent
            let mimeType = getMimeType(for: imageURL)

            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(mimeType)\r\n\r\n")
            body.append(imageData)
            body.append("\r\n")
        }

        // Add iterations parameter
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"iterations\"\r\n\r\n")
        body.append("\(iterations)\r\n")

        // Add resolution parameter
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"resolution\"\r\n\r\n")
        body.append("\(resolution)\r\n")

        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode != 200 && httpResponse.statusCode != 202 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                throw APIError.serverError(errorMessage)
            }
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }

        return try JSONDecoder().decode(UploadResponse.self, from: data)
    }

    // MARK: - Get Task Status
    func getTaskStatus(taskId: String) async throws -> TaskStatus {
        guard let url = URL(string: "\(APIConfig.baseURL)/status/\(taskId)") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 404 {
            throw APIError.taskNotFound
        }

        if httpResponse.statusCode != 200 {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }

        return try JSONDecoder().decode(TaskStatus.self, from: data)
    }

    // MARK: - Download Model
    func downloadModel(taskId: String) async throws -> URL {
        guard let url = URL(string: "\(APIConfig.baseURL)/download/\(taskId)") else {
            throw APIError.invalidURL
        }

        let (tempURL, response) = try await session.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 404 {
            throw APIError.taskNotFound
        }

        if httpResponse.statusCode != 200 {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }

        // Move to documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let modelsDirectory = documentsPath.appendingPathComponent("Models", isDirectory: true)

        // Create models directory if needed
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)

        let destinationURL = modelsDirectory.appendingPathComponent("\(taskId).ply")

        // Remove existing file if exists
        try? FileManager.default.removeItem(at: destinationURL)

        // Move downloaded file
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)

        return destinationURL
    }

    // MARK: - Delete Task
    func deleteTask(taskId: String) async throws {
        guard let url = URL(string: "\(APIConfig.baseURL)/task/\(taskId)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
    }

    // MARK: - Get All Tasks
    func getAllTasks() async throws -> [String: TaskStatus] {
        guard let url = URL(string: "\(APIConfig.baseURL)/tasks") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode([String: TaskStatus].self, from: data)
    }

    // MARK: - Helper Methods
    private func getMimeType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "avi": return "video/x-msvideo"
        case "mkv": return "video/x-matroska"
        case "m4v": return "video/x-m4v"
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "heic", "heif": return "image/heic"
        case "bmp": return "image/bmp"
        default: return "application/octet-stream"
        }
    }
}

// MARK: - Data Extension
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
