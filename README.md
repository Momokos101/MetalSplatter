# MetalSplatter

一个使用 Metal 在 iOS 平台上渲染 3D Gaussian Splats 的 Swift 库。

本项目基于 [3D Gaussian Splatting for Real-Time Radiance Field Rendering](https://repo-sam.inria.fr/fungraph/3d-gaussian-splatting/) 论文中描述的技术，可以加载 PLY 或 .splat 格式的 3D 高斯点云文件并在 iOS 设备上进行实时渲染。

## 项目架构

项目采用模块化设计，主要分为以下几个部分：

### 核心库模块

#### 1. **MetalSplatter** - 核心渲染库
负责使用 Metal 渲染 3D Gaussian Splats 的核心功能。

**文件结构：**
- `Sources/SplatRenderer.swift` - 主要的渲染器类，负责管理渲染管线、GPU 资源分配和渲染循环
- `Sources/MetalBuffer.swift` - Metal 缓冲区管理工具类
- `Resources/` - Metal Shader 文件
  - `SplatProcessing.metal` - Splat 数据处理着色器
  - `SplatProcessing.h` - Shader 头文件
  - `SingleStageRenderPath.metal` - 单阶段渲染路径
  - `MultiStageRenderPath.metal` - 多阶段渲染路径
  - `ShaderCommon.h` - 通用 Shader 定义

#### 2. **PLYIO** - PLY 文件读写库
独立的 PLY 文件格式读写库，支持二进制和 ASCII 格式。

**主要文件：**
- `PLYReader.swift` - PLY 文件读取器
- `PLYWriter.swift` - PLY 文件写入器
- `PLYHeader.swift` - PLY 文件头解析
- `PLYElement.swift` - PLY 元素数据结构
- 其他辅助文件处理数据类型转换和字节序处理

#### 3. **SplatIO** - Splat 文件格式处理
基于 PLYIO 的薄层，专门用于处理 Gaussian Splat 格式的文件。

**主要文件：**
- `SplatSceneReader.swift` - Splat 场景读取器接口
- `SplatPLYSceneReader.swift` - PLY 格式的 Splat 读取器
- `DotSplatSceneReader.swift` - .splat 格式的读取器
- `SplatSceneWriter.swift` - Splat 场景写入器
- `SplatScenePoint.swift` - Splat 点数据结构
- `SplatFileFormat.swift` - 文件格式定义

#### 4. **SampleBoxRenderer** - 调试渲染器
用于调试和测试的简单渲染器，渲染一个彩色立方体，可以替代 MetalSplatter 来验证集成是否正确。

**文件：**
- `SampleBoxRenderer.swift` - 立方体渲染器实现
- `Resources/Shaders.metal` - 立方体渲染着色器

#### 5. **SplatConverter** - 文件格式转换工具
命令行工具，用于在不同格式之间转换 Splat 文件。

**文件：**
- `SplatConverter.swift` - 转换工具主程序

### 示例应用 (SampleApp)

iOS 示例应用，展示如何使用 MetalSplatter 库。

#### App/ - 应用入口和配置
- `SampleApp.swift` - 应用主入口，定义 WindowGroup 和导航结构
- `Constants.swift` - 全局常量配置
  - `maxSimultaneousRenders` - 最大同时渲染数
  - `fovy` - 视野角度
  - `rotationAxis` - 旋转轴配置
  - `modelCenterZ` - 模型中心 Z 坐标

#### Scene/ - 场景渲染相关
- `ContentView.swift` - 主视图，包含文件选择界面和导航逻辑
  - 提供文件选择器（支持 .ply 和 .splat 格式）
  - 管理导航栈，将选中的模型传递给渲染视图
  
- `MetalKitSceneView.swift` - SwiftUI 视图包装器
  - 将 MTKView 集成到 SwiftUI
  - 管理手势识别器（拖拽、缩放、旋转）
  - 协调渲染器和视图更新
  
- `MetalKitSceneRenderer.swift` - Metal 渲染器实现
  - 实现 `MTKViewDelegate` 协议
  - 管理渲染循环和 GPU 资源
  - 处理模型加载和渲染
  - 管理手势控制状态（平移、缩放、旋转）

#### Model/ - 模型管理
- `ModelIdentifier.swift` - 模型标识符枚举
  - `gaussianSplat(URL)` - Gaussian Splat 文件
  - `sampleBox` - 示例立方体
  
- `ModelRenderer.swift` - 渲染器协议定义
  - 定义统一的渲染接口，支持多种渲染器实现
  
- `SplatRenderer+ModelRenderer.swift` - MetalSplatter 渲染器的协议实现
- `SampleBoxRenderer+ModelRenderer.swift` - 示例渲染器的协议实现

#### Util/ - 工具类
- `MatrixMathUtil.swift` - 矩阵数学工具函数
  - `matrix4x4_rotation` - 旋转矩阵计算
  - `matrix4x4_translation` - 平移矩阵计算
  - `matrix_perspective_right_hand` - 透视投影矩阵计算

## 功能特性

### 手势控制
应用支持以下手势操作：
- **拖拽** - 单指拖动平移模型
- **缩放** - 双指捏合缩放模型（范围：0.1x - 5.0x）
- **旋转** - 双指旋转模型（绕 Y 轴）

### 文件格式支持
- PLY 格式（二进制和 ASCII）
- .splat 格式（DotSplat 格式）

## 如何运行

### 前置要求
- Xcode 15.0 或更高版本
- iOS 17.2 或更高版本
- 支持 Metal 的 iOS 设备或模拟器

### 运行步骤

1. **克隆仓库**
   ```bash
   git clone <repository-url>
   cd MetalSplatter
   ```

2. **打开项目**
   - 打开 `SampleApp/MetalSplatter_SampleApp.xcodeproj`

3. **配置签名**
   - 在 Xcode 中选择项目文件
   - 选择 "MetalSplatter SampleApp" target
   - 进入 "Signing & Capabilities" 标签
   - 勾选 "Automatically manage signing"
   - 选择你的开发团队（如果没有，点击 "Add Account..." 添加 Apple ID）

4. **选择运行目标**
   - 在 Xcode 顶部选择目标设备（iPhone 或 iPad）
   - 确保 Scheme 设置为 "MetalSplatter SampleApp"

5. **运行应用**
   - 按 `Cmd + R` 或点击运行按钮
   - 应用将在设备或模拟器上启动

6. **加载模型**
   - 点击 "Read Scene File" 按钮
   - 选择 .ply 或 .splat 格式的文件
   - 模型将加载并显示在屏幕上

### 性能优化建议

- **使用 Release 模式**：在 Debug 模式下加载大文件会慢一个数量级以上
- **断开调试器**：在 Xcode 中停止应用，然后从主屏幕直接运行应用可以获得更好的帧率
- **准备测试文件**：确保你有有效的 .ply 或 .splat 文件用于测试

### 获取测试文件

你可以通过以下方式获取测试用的 Gaussian Splat 文件：

- 使用 [Luma AI 的 iPhone 应用](https://apps.apple.com/us/app/luma-ai/id1615849914) 捕获场景并导出为 .splat 格式
- 使用 [Nerfstudio](https://docs.nerf.studio/nerfology/methods/splat.html) 训练自己的 Splat
- 使用[原始论文提供的场景数据](https://repo-sam.inria.fr/fungraph/3d-gaussian-splatting/)

## 项目结构

```
MetalSplatter/
├── MetalSplatter/          # 核心渲染库
│   ├── Sources/
│   └── Resources/
├── PLYIO/                  # PLY 文件读写库
│   ├── Sources/
│   └── Tests/
├── SplatIO/                # Splat 文件格式处理
│   ├── Sources/
│   └── Tests/
├── SampleBoxRenderer/      # 调试渲染器
│   ├── Sources/
│   └── Resources/
├── SplatConverter/         # 文件转换工具
│   └── Sources/
└── SampleApp/             # iOS 示例应用
    ├── App/
    ├── Scene/
    ├── Model/
    ├── Util/
    └── MetalSplatter_SampleApp.xcodeproj/
```

## 依赖关系

- **MetalSplatter** 依赖 **PLYIO** 和 **SplatIO**
- **SplatIO** 依赖 **PLYIO**
- **SampleApp** 依赖 **MetalSplatter**、**SplatIO**、**PLYIO** 和 **SampleBoxRenderer**

## 许可证

请查看 LICENSE 文件了解许可证详情。

## 相关资源

- [3D Gaussian Splatting 论文](https://repo-sam.inria.fr/fungraph/3d-gaussian-splatting/)
- [RadianceFields.com](https://radiancefields.com) - 3DGS 和 NeRF 相关新闻和文章
- [Awesome 3D Gaussian Splatting Resources](https://github.com/MrNeRF/awesome-3D-gaussian-splatting) - 3DGS 资源集合
