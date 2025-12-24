# 3D Gaussian Splatting on Mobile Devices

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2017.2+-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Language-Swift%205.9-orange.svg" alt="Language">
  <img src="https://img.shields.io/badge/Backend-Python%203.10+-green.svg" alt="Backend">
  <img src="https://img.shields.io/badge/GPU-CUDA%2011.6+-red.svg" alt="GPU">
</p>

## 项目简介

本项目是同济大学 2024-2025 秋季学期《计算机视觉》课程期末作业，实现了一个完整的 **3D Gaussian Splatting 移动端解决方案**。用户可以使用手机拍摄视频或照片，上传至服务器进行 3D 重建，然后在手机上实时查看重建的 3D 模型。

### 团队成员

| 姓名 | 学号 | 角色 |
|------|------|------|
| **金恒宇** | 2352280 | 组长 |
| 胡宝怡 | 2353409 | 组员 |
| 达思睿 | 2352288 | 组员 |

### 指导教师

张林

---

## 目录

- [项目背景](#项目背景)
- [系统架构](#系统架构)
- [技术栈](#技术栈)
- [后端处理流水线](#后端处理流水线)
- [移动端实现](#移动端实现)
- [开源项目致谢](#开源项目致谢)
- [安装部署](#安装部署)
- [使用说明](#使用说明)
- [项目结构](#项目结构)
- [参考文献](#参考文献)

---

## 项目背景

### 什么是 3D Gaussian Splatting?

3D Gaussian Splatting (3DGS) 是一种新型的 3D 场景表示和渲染技术，由 Kerbl 等人在 2023 年提出。与传统的 NeRF (Neural Radiance Fields) 方法相比，3DGS 具有以下优势：

- **实时渲染**：无需神经网络推理，可在消费级 GPU 上实现实时渲染
- **高质量**：渲染质量可与 NeRF 媲美，甚至更优
- **可编辑**：基于显式的高斯点云表示，便于编辑和操作

### 核心原理

3DGS 使用大量的 3D 高斯椭球来表示场景。每个高斯点包含：

- **位置 (Position)**：3D 空间坐标 (x, y, z)
- **协方差 (Covariance)**：定义椭球的形状和方向
- **颜色 (Color)**：使用球谐函数 (Spherical Harmonics) 表示视角相关的颜色
- **不透明度 (Opacity)**：控制透明度

渲染时，将 3D 高斯投影到 2D 屏幕空间，通过 α-blending 混合得到最终图像。

---

## 系统架构

```
+------------------+                      +----------------------+
|                  |   1. Upload Video    |                      |
|    iOS App       | ------------------> |   Backend Server     |
|                  |                      |   (Python/Flask)     |
|  +------------+  |   4. Download PLY    |                      |
|  |  Capture   |  | <------------------ |  +----------------+  |
|  +------------+  |                      |  |   Pipeline     |  |
|  +------------+  |   2. Poll Status     |  |                |  |
|  |  Upload    |  | ------------------> |  |  FFmpeg        |  |
|  +------------+  |                      |  |     |          |  |
|  +------------+  |   3. Return Progress |  |     v          |  |
|  |  Render    |  | <------------------ |  |  COLMAP        |  |
|  +------------+  |                      |  |     |          |  |
|                  |                      |  |     v          |  |
+------------------+                      |  |  3DGS Train    |  |
        |                                 |  +----------------+  |
        | Metal GPU                       +----------------------+
        v
+------------------+
| MetalSplatter    |  <-- High-performance 3DGS renderer
+------------------+
```

### 工作流程

1. **数据采集**：用户使用 iOS App 录制视频或拍摄多角度照片
2. **数据上传**：App 将视频/图片上传至后端服务器
3. **3D 重建**：服务器执行完整的重建流水线
4. **模型下载**：重建完成后，App 下载生成的 PLY 模型文件
5. **实时渲染**：使用 Metal GPU 在手机上实时渲染 3D 模型

---

## 技术栈

### 后端技术

| 技术 | 用途 | 版本要求 |
|------|------|----------|
| **Python** | 后端服务开发 | 3.10+ |
| **Flask** | REST API 框架 | 2.3.0+ |
| **CUDA** | GPU 加速训练 | 11.6+ |
| **FFmpeg** | 视频帧提取 | - |
| **COLMAP** | 相机位姿估计 | - |
| **PyTorch** | 深度学习框架 | 2.0+ |

### 移动端技术

| 技术 | 用途 | 版本要求 |
|------|------|----------|
| **Swift** | iOS 应用开发 | 5.9+ |
| **SwiftUI** | 用户界面框架 | iOS 17.2+ |
| **Metal** | GPU 渲染 | - |
| **MetalKit** | Metal 视图集成 | - |
| **AVFoundation** | 视频录制 | - |
| **PhotosUI** | 相册访问 | - |

---

## 后端处理流水线

后端采用三阶段流水线架构，将视频/图片转换为可渲染的 3D 高斯点云模型。

### 流水线概览

```
                        Backend Pipeline
+------------------------------------------------------------------------+
|                                                                        |
|  Input          Stage 1          Stage 2              Stage 3          |
|                                                                        |
|  +-------+     +---------+      +------------+       +----------+      |
|  | Video | --> | FFmpeg  | --+  |  COLMAP    |       |   3DGS   |      |
|  | .mov  |     | Extract |   |  |            |       |  Train   |      |
|  +-------+     +---------+   |  | - Feature  |       |          |      |
|                              +->| - Matching | ----> | - Optim  |      |
|  +-------+     +---------+   |  | - SfM      |       | - Dense  |      |
|  | Image | --> |  HEIC   | --+  |            |       | - Prune  |      |
|  | .heic |     | Convert |      +------------+       +----------+      |
|  +-------+     +---------+           |                    |            |
|                                      v                    v            |
|                               +------------+       +----------+        |
|                               | Camera     |       |   PLY    |        |
|                               | Poses      |       |  Model   |        |
|                               +------------+       +----------+        |
|                                                                        |
+------------------------------------------------------------------------+
```

### Stage 1: FFmpeg 视频切帧

**工具**: [FFmpeg](https://ffmpeg.org/)

FFmpeg 是一个强大的多媒体处理工具，我们使用它从视频中提取图像帧。

```bash
ffmpeg -i input.mov -vf "fps=4" -q:v 2 output/frame_%04d.jpg
```

**参数说明**:
- `-vf "fps=4"`: 每秒提取 4 帧
- `-q:v 2`: JPEG 质量 (1-31，越小质量越高)

**为什么需要切帧？**
- 3DGS 训练需要多视角图像作为输入
- 视频包含连续帧，但相邻帧差异太小
- 适当的帧率可以保证足够的视角覆盖，同时避免冗余

### Stage 2: COLMAP 相机位姿估计

**工具**: [COLMAP](https://colmap.github.io/)

COLMAP 是一个通用的 Structure-from-Motion (SfM) 和 Multi-View Stereo (MVS) 流水线。我们使用它来估计每张图片的相机位姿。

**处理步骤**:

1. **特征提取 (Feature Extraction)**
   - 使用 SIFT 算法检测图像中的关键点
   - 为每个关键点计算 128 维描述子

2. **特征匹配 (Feature Matching)**
   - 在图像对之间匹配特征点
   - 使用 exhaustive matching 或 vocabulary tree matching

3. **稀疏重建 (Sparse Reconstruction)**
   - 增量式 SfM：逐步添加图像并优化
   - Bundle Adjustment：联合优化相机参数和 3D 点

**输出文件**:
```
sparse/0/
├── cameras.bin    # 相机内参
├── images.bin     # 图像位姿
└── points3D.bin   # 稀疏 3D 点云
```

### Stage 3: 3DGS 模型训练

**工具**: [gaussian-splatting](https://github.com/graphdeco-inria/gaussian-splatting)

基于 COLMAP 输出的相机位姿和稀疏点云，训练 3D Gaussian Splatting 模型。

**训练过程**:

1. **初始化**: 从 COLMAP 稀疏点云初始化高斯点
2. **可微渲染**: 将高斯投影到图像平面
3. **损失计算**: 比较渲染图像与真实图像
4. **参数优化**: 使用 Adam 优化器更新高斯参数
5. **自适应控制**:
   - **致密化 (Densification)**: 在梯度大的区域添加新高斯
   - **剪枝 (Pruning)**: 移除不透明度低的高斯

**训练命令**:
```bash
python train.py -s <数据路径> -m <输出路径> --iterations 7000
```

**输出**: `point_cloud.ply` - 包含所有高斯点参数的 PLY 文件

### 处理时间参考

| 模式 | 迭代次数 | 分辨率 | 预计时间 |
|------|----------|--------|----------|
| 快速演示 | 2,000 | 1/4 | 3-5 分钟 |
| 标准质量 | 7,000 | 1/2 | 10-15 分钟 |
| 高质量 | 30,000 | 全分辨率 | 30-60 分钟 |

---

## 移动端实现

### iOS App 架构

```
+-----------------------------------------------------+
|                 iOS App Architecture                |
+-----------------------------------------------------+
|                                                     |
|  +-----------------------------------------------+  |
|  |                 UI Layer                      |  |
|  |  +-----------+ +-----------+ +------------+  |  |
|  |  | UploadTab | | ModelsTab | |ModelViewer |  |  |
|  |  +-----------+ +-----------+ +------------+  |  |
|  +-----------------------------------------------+  |
|                        |                            |
|  +-----------------------------------------------+  |
|  |              Service Layer                    |  |
|  |  +-----------+ +-----------+ +------------+  |  |
|  |  |APIService | |CameraServ | |FileManager |  |  |
|  |  +-----------+ +-----------+ +------------+  |  |
|  +-----------------------------------------------+  |
|                        |                            |
|  +-----------------------------------------------+  |
|  |             Rendering Layer                   |  |
|  |  +----------------------------------------+  |  |
|  |  |          MetalSplatter                 |  |  |
|  |  |  +------------+  +---------+           |  |  |
|  |  |  |SplatRender |  | PLYIO   |           |  |  |
|  |  |  +------------+  +---------+           |  |  |
|  |  +----------------------------------------+  |  |
|  +-----------------------------------------------+  |
|                                                     |
+-----------------------------------------------------+
```

### 核心功能模块

#### 1. 数据采集模块

支持三种数据输入方式：

| 方式 | 说明 | 推荐场景 |
|------|------|----------|
| **录制视频** | 环绕物体拍摄 30 秒内视频 | 快速采集，适合新手 |
| **连续拍摄** | 拍摄 10-20 张不同角度照片 | 精确控制，高质量 |
| **相册选择** | 从相册选择已有素材 | 使用现有资源 |

#### 2. 网络通信模块

基于 REST API 与后端通信：

- **上传**: `POST /upload` 或 `POST /upload_images`
- **状态轮询**: `GET /status/<task_id>` (每 2 秒)
- **下载模型**: `GET /download/<task_id>`

#### 3. Metal 渲染模块

基于 MetalSplatter 库实现高性能 GPU 渲染：

**渲染流程**:
1. 加载 PLY 文件，解析高斯点数据
2. 将数据上传到 GPU 缓冲区
3. 根据相机视角排序高斯点
4. 执行 α-blending 渲染

**手势交互**:
- **单指拖动**: 旋转模型
- **双指捏合**: 缩放模型
- **双指拖动**: 平移模型
- **双击**: 重置视图

---

## 开源项目致谢

本项目基于以下优秀的开源项目构建：

### 1. gaussian-splatting

- **仓库**: [graphdeco-inria/gaussian-splatting](https://github.com/graphdeco-inria/gaussian-splatting)
- **用途**: 3DGS 训练核心算法
- **许可证**: 详见原仓库

官方实现的 3D Gaussian Splatting 训练代码，包含完整的训练流程和可微渲染器。

### 2. MetalSplatter

- **仓库**: [scier/MetalSplatter](https://github.com/scier/MetalSplatter)
- **用途**: iOS 端 3DGS 渲染引擎
- **许可证**: MIT

基于 Metal 的高性能 3DGS 渲染库，支持在 iOS 设备上实时渲染高斯点云。

### 3. COLMAP

- **仓库**: [colmap/colmap](https://github.com/colmap/colmap)
- **用途**: 相机位姿估计
- **许可证**: BSD

业界标准的 Structure-from-Motion 工具，用于从多视角图像估计相机参数。

### 4. FFmpeg

- **官网**: [ffmpeg.org](https://ffmpeg.org/)
- **用途**: 视频处理
- **许可证**: LGPL/GPL

强大的多媒体处理工具，用于视频帧提取。

---

## 安装部署

### 后端服务部署

#### 环境要求

- Python 3.10+
- CUDA 11.6+ (NVIDIA GPU)
- FFmpeg
- COLMAP

#### 安装步骤

```bash
# 1. 克隆 gaussian-splatting 仓库
git clone https://github.com/graphdeco-inria/gaussian-splatting.git
cd gaussian-splatting

# 2. 创建 conda 环境
conda create -n gs python=3.10
conda activate gs

# 3. 安装 PyTorch (CUDA 11.8)
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118

# 4. 安装 gaussian-splatting 依赖
pip install -r requirements.txt

# 5. 安装服务端依赖
pip install flask flask-cors pillow pillow-heif

# 6. 启动服务
python server.py
```

### iOS 应用部署

#### 环境要求

- macOS 14.0+
- Xcode 15.0+
- iOS 17.2+ 设备

#### 安装步骤

```bash
# 1. 进入 iOS 项目目录
cd MetalSplatter

# 2. 打开 Xcode 项目
open SampleApp/MetalSplatter_SampleApp.xcodeproj
```

3. 在 Xcode 中配置签名
4. 连接 iOS 设备
5. 点击运行 (Cmd + R)

---

## 使用说明

### 拍摄建议

为获得最佳重建效果，请遵循以下建议：

1. **环绕拍摄**: 围绕物体 360° 拍摄
2. **保持稳定**: 避免剧烈晃动
3. **光线充足**: 确保场景光线均匀
4. **纹理丰富**: 避免纯色或反光表面
5. **适当重叠**: 相邻帧之间保持 60-80% 重叠

### 操作流程

1. 打开 App，选择"创建"标签
2. 选择拍摄方式（视频/照片/相册）
3. 完成拍摄后上传至服务器
4. 等待处理完成（可查看进度）
5. 下载模型并在"模型"标签中查看

---

## 项目结构

```
 ── MetalSplatter/           # iOS 应用
    ├── 3DGS/                # 主应用代码
    │   ├── App.swift        # 应用入口
    │   ├── ContentView.swift # 主界面
    │   ├── Views/           # 视图组件
    │   │   ├── UploadTab.swift
    │   │   ├── ModelsTab.swift
    │   │   ├── ModelViewer.swift
    │   │   └── Components/
    │   └── Services/        # 服务层
    │       ├── APIService.swift
    │       └── SplatSceneRenderer.swift
    │
    ├── MetalSplatter/       # 渲染核心库
    │   ├── Sources/
    │   │   ├── SplatRenderer.swift
    │   │   └── MetalBuffer.swift
    │   └── Resources/       # Metal Shaders
    │
    ├── PLYIO/               # PLY 文件读写
    ├── SplatIO/             # Splat 格式处理
    └── SampleApp/           # 示例应用
```

---

## 参考文献

1. Kerbl, B., Kopanas, G., Leimkühler, T., & Drettakis, G. (2023). **3D Gaussian Splatting for Real-Time Radiance Field Rendering**. *ACM Transactions on Graphics*, 42(4), 139:1-139:14.

2. Schönberger, J. L., & Frahm, J. M. (2016). **Structure-from-Motion Revisited**. *IEEE Conference on Computer Vision and Pattern Recognition (CVPR)*.

3. Bagdasarian, M. T., et al. (2024). **3dgs.zip: A Survey on 3D Gaussian Splatting Compression Methods**. *arXiv preprint arXiv:2407.09510*.

---

## 许可证

本项目仅供学术研究使用。各组件的许可证请参考对应的开源项目。

---

<p align="center">
  <b>同济大学 · 计算机视觉课程 · 2024-2025 秋季学期</b>
</p>
