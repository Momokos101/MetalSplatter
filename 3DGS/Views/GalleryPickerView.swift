//
//  GalleryPickerView.swift
//  3DGS Scanner
//
//  相册选择器 - 支持选择视频或多张图片
//

import SwiftUI
import PhotosUI

struct GalleryPickerView: View {
    @Binding var isPresented: Bool
    let onVideoSelected: (URL) -> Void
    let onImagesSelected: ([URL]) -> Void

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoading = false
    @State private var selectionMode: SelectionMode = .video

    enum SelectionMode {
        case video
        case images
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Selection mode picker
                Picker("选择类型", selection: $selectionMode) {
                    Text("视频").tag(SelectionMode.video)
                    Text("图片").tag(SelectionMode.images)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if selectionMode == .video {
                    videoPickerSection
                } else {
                    imagesPickerSection
                }

                Spacer()

                if isLoading {
                    ProgressView("正在处理...")
                        .padding()
                }
            }
            .padding(.top)
            .navigationTitle("从相册选择")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
        }
    }

    // MARK: - Video Picker Section
    private var videoPickerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("选择一个视频文件")
                .font(.headline)

            Text("支持 MP4, MOV, AVI, MKV 格式")
                .font(.caption)
                .foregroundColor(.secondary)

            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 1,
                matching: .videos
            ) {
                Text("选择视频")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .onChange(of: selectedItems) { _, newItems in
                handleVideoSelection(newItems)
            }
        }
        .padding()
    }

    // MARK: - Selection Handlers
    private func handleVideoSelection(_ items: [PhotosPickerItem]) {
        guard let item = items.first else { return }
        isLoading = true

        Task {
            if let url = await loadVideo(from: item) {
                await MainActor.run {
                    isLoading = false
                    onVideoSelected(url)
                    isPresented = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    // MARK: - Images Picker Section
    private var imagesPickerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(.purple)

            Text("选择多张图片")
                .font(.headline)

            Text("至少选择 3 张，支持 JPG, PNG, HEIC")
                .font(.caption)
                .foregroundColor(.secondary)

            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 50,
                matching: .images
            ) {
                Text("选择图片")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.purple)
                    .cornerRadius(12)
            }
            .onChange(of: selectedItems) { _, newItems in
                handleImagesSelection(newItems)
            }
        }
        .padding()
    }

    // MARK: - Selection Handlers
    private func handleImagesSelection(_ items: [PhotosPickerItem]) {
        guard items.count >= 3 else { return }
        isLoading = true

        Task {
            var urls: [URL] = []
            for item in items {
                if let url = await loadImage(from: item) {
                    urls.append(url)
                }
            }

            await MainActor.run {
                isLoading = false
                if urls.count >= 3 {
                    onImagesSelected(urls)
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - File Loading Extensions
extension GalleryPickerView {
    private func loadVideo(from item: PhotosPickerItem) async -> URL? {
        do {
            guard let movie = try await item.loadTransferable(type: VideoTransferable.self) else {
                return nil
            }
            return movie.url
        } catch {
            print("加载视频失败: \(error)")
            return nil
        }
    }

    private func loadImage(from item: PhotosPickerItem) async -> URL? {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                return nil
            }

            let tempDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Temp", isDirectory: true)
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            let fileName = "\(UUID().uuidString).jpg"
            let fileURL = tempDir.appendingPathComponent(fileName)
            try data.write(to: fileURL)

            return fileURL
        } catch {
            print("加载图片失败: \(error)")
            return nil
        }
    }
}

// MARK: - Video Transferable
struct VideoTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let tempDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Temp", isDirectory: true)
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            let fileName = "\(UUID().uuidString).mov"
            let destURL = tempDir.appendingPathComponent(fileName)
            try FileManager.default.copyItem(at: received.file, to: destURL)

            return Self(url: destURL)
        }
    }
}

#Preview {
    GalleryPickerView(
        isPresented: .constant(true),
        onVideoSelected: { _ in },
        onImagesSelected: { _ in }
    )
}