# Flutter V2Ray Android

[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.html)
[![Platform](https://img.shields.io/badge/platform-Android-green.svg)](https://www.android.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)

Flutter V2Ray Android 是一个基于 Flutter 框架的高性能、跨平台代理客户端，使用 V2Ray 核心实现，支持多种代理协议和高级功能。该项目专注于提供安全、高效、易用的代理服务体验。

## 📋 项目状态

**当前项目完成度：100%**

- ✅ 项目初始化与基础设施：100% 完成
- ✅ 数据模型与存储设计：100% 完成
- ✅ 核心功能实现：100% 完成
- ✅ 用户界面开发：100% 完成
- ✅ 测试与优化：100% 完成

## 🌟 主要特性

- **多协议支持**：支持 VMess、VLESS、Shadowsocks、Trojan 等多种代理协议
- **服务器管理**：直观的服务器配置管理，支持添加、编辑、删除、分享和复制功能
- **订阅管理**：支持订阅导入、自动更新和管理功能
- **路由规则**：灵活的路由规则配置，支持全局代理、绕过大陆地址和自定义规则
- **流量统计**：实时流量监控和图表展示
- **深色模式**：完整的深色模式支持
- **多语言支持**：支持中文、英文等多种语言
- **高级功能**：支持 TLS、WebSocket、mKCP 等传输方式，DNS 自定义和 Mux 多路复用

## 🏗️ 架构设计

该项目采用现代化的架构设计，确保代码的可维护性、可测试性和可扩展性。

### 架构模式

项目采用 **MVVM (Model-View-ViewModel)** 架构模式，实现了以下优势：

- **关注点分离**：清晰地分离 UI、业务逻辑和数据处理
- **可测试性**：ViewModel 可以独立于 UI 进行测试
- **状态管理**：便于管理和维护应用状态
- **数据绑定**：简化 View 和数据之间的交互
- **代码复用**：提高代码的可复用性

### 模块化设计

项目分为以下主要层次：

#### 核心层
- `lib/core/ffi`: 提供与V2Ray核心的FFI交互
- `lib/core/vpn`: VPN服务接口与实现
- `lib/core/v2ray`: V2Ray服务接口与实现

#### 服务层
- `lib/services/connection`: 连接管理服务
- `lib/services/servers`: 服务器配置管理
- `lib/services/settings`: 应用设置管理
- `lib/services/storage`: 本地存储服务
- `lib/services/sub`: 订阅管理服务
- `lib/services/config`: 配置生成服务

#### 数据模型
- `lib/models/servers`: 服务器配置相关模型
- `lib/models/settings`: 应用设置相关模型
- `lib/models/stats`: 流量统计相关模型
- `lib/models/sub`: 订阅相关模型

#### 用户界面
- `lib/views/home`: 主页界面
- `lib/views/servers`: 服务器管理界面
- `lib/views/settings`: 设置界面
- `lib/views/logs`: 日志界面
- `lib/views/subscriptions`: 订阅管理界面

#### Android原生代码
- `android/app/src/main/kotlin`: Kotlin编写的原生层
- `android/app/src/main/cpp`: C++编写的JNI桥接层

## 🔐 安全架构

### 安全设计原则

本项目高度重视安全性，实现了多层次的安全保护：

1. **数据安全**：
   - 敏感配置使用强加密存储
   - 内存保护机制防止敏感数据泄露
   - 安全的数据生命周期管理

2. **通信安全**：
   - 强制使用 TLS 1.3 或更高版本
   - 实现证书验证和公钥固定
   - 防止中间人攻击的机制

3. **访问控制**：
   - 应用级别访问控制
   - 生物识别认证支持
   - 敏感操作二次确认

4. **代码安全**：
   - 防逆向工程措施
   - 防篡改保护
   - 混淆和加固技术

### 威胁防护

应用实现了对以下威胁的防护：

- 网络嗅探与中间人攻击
- 应用逆向工程
- 恶意代理配置注入
- 流量分析与指纹识别
- 本地数据泄露

## 🌐 跨平台设计

虽然当前版本专注于 Android 平台，但项目设计时已考虑跨平台支持，为未来扩展到 iOS 和桌面平台奠定基础：

### 平台代码隔离

- **平台抽象接口**：定义统一的接口，隔离平台特定实现
- **条件导入**：使用 Dart 条件导入特性实现平台特定代码的编译时选择
- **平台通道**：设计统一的通道接口处理原生通信

### 响应式UI设计

- **自适应布局**：基于约束的自适应布局设计
- **平台特定组件**：根据平台自动选择合适的UI组件
- **屏幕尺寸响应**：支持不同尺寸和方向的屏幕布局

## 🚀 性能优化

项目实现了全面的性能优化策略：

1. **内存优化**：
   - 合理的资源管理和释放
   - 避免内存泄漏的设计模式
   - 大型数据集的惰性加载

2. **启动性能**：
   - 延迟初始化非关键组件
   - 优化资源加载顺序
   - 预加载关键数据

3. **UI渲染优化**：
   - 使用 `const` 构造函数
   - 避免不必要的重建
   - 实现高效的列表视图

4. **网络性能**：
   - 连接池管理
   - 网络请求合并与缓存
   - 数据压缩与优化传输

## 📊 测试覆盖

项目实现了全面的测试策略，确保代码质量和稳定性：

### 单元测试

已完成的单元测试覆盖以下关键组件：
- 配置生成器：测试各种协议类型的配置生成
- 连接服务：测试连接管理流程
- 服务器服务：测试服务器配置的CRUD操作
- 订阅服务：测试订阅管理和更新功能

### 集成测试

已完成的集成测试覆盖以下界面：
- 主页面：测试状态显示、连接按钮和导航
- 服务器列表：测试服务器管理功能
- 订阅管理页面：测试订阅列表、添加、编辑和更新功能
- 设置页面：测试各项设置的修改和保存功能

## 📱 安装与使用

### 系统要求

- Android 5.0 (API level 21) 或更高版本
- 至少 100MB 可用存储空间
- 网络连接

### 安装步骤

1. 从 [Releases](https://github.com/yourusername/flutter-v2ray-android/releases) 页面下载最新版本的 APK 文件
2. 在 Android 设备上允许安装来自未知来源的应用
3. 打开下载的 APK 文件并安装应用

### 基本使用

1. **添加服务器**：
   - 手动添加：点击服务器列表右上角的"+"按钮
   - 导入配置：在主页点击"导入"按钮，从剪贴板或二维码导入
   - 添加订阅：在"订阅"页面添加订阅地址

2. **连接服务器**：
   - 在服务器列表中选择服务器
   - 在主页点击连接按钮
   - 首次连接需要授予 VPN 权限

3. **自定义设置**：
   - 在"设置"页面可以配置应用行为
   - 调整路由规则、DNS 设置和代理端口
   - 配置界面主题和语言偏好

## 🧪 测试指南

### 运行单元测试

1. 确保已安装所有依赖：
   ```bash
   flutter pub get
   ```

2. 运行所有单元测试：
   ```bash
   flutter test
   ```

3. 运行特定的测试文件：
   ```bash
   flutter test test/config_generator_test.dart
   ```

4. 运行带覆盖率的测试：
   ```bash
   flutter test --coverage
   ```

5. 查看测试覆盖率报告（需要安装 lcov）：
   ```bash
   genhtml coverage/lcov.info -o coverage/html
   ```

### 运行集成测试

1. 确保已连接设备或模拟器：
   ```bash
   flutter devices
   ```

2. 运行所有集成测试：
   ```bash
   flutter test integration_test
   ```

3. 运行特定的集成测试：
   ```bash
   flutter test integration_test/home_screen_test.dart
   ```

### 手动测试要点

1. **基本功能测试**：
   - 服务器添加、编辑、删除功能
   - 订阅导入、更新功能
   - 连接和断开连接
   - 设置修改和保存

2. **性能测试**：
   - 大量服务器配置下的启动性能
   - 长时间运行的稳定性
   - 电池消耗测试
   - 内存占用监控

3. **网络环境测试**：
   - WiFi 环境下的连接性能
   - 移动数据环境下的连接性能
   - 网络切换时的稳定性测试
   - 弱网环境下的恢复能力

4. **兼容性测试**：
   - 不同 Android 版本的兼容性
   - 不同屏幕尺寸的适配性
   - 横屏和竖屏模式切换

## 🔨 编译指南

### 完整编译流程

1. **环境准备**：
   ```bash
   # 安装 Flutter
   git clone https://github.com/flutter/flutter.git
   export PATH="$PATH:`pwd`/flutter/bin"
   flutter doctor
   
   # 安装 Android SDK 和 NDK
   sdkmanager "platforms;android-30" "build-tools;30.0.3" "ndk;21.4.7075529"
   ```

2. **克隆项目**：
   ```bash
   git clone https://github.com/yourusername/flutter-v2ray-android.git
   cd flutter-v2ray-android
   ```

3. **编译 V2Ray 核心库**（详见下一节）

4. **安装项目依赖**：
   ```bash
   flutter pub get
   ```

5. **生成必要的文件**：
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

6. **构建 APK**：
   ```bash
   # 调试版本
   flutter build apk --debug
   
   # 发布版本
   flutter build apk --release
   
   # 特定架构版本
   flutter build apk --release --target-platform=android-arm64
   ```

7. **构建 App Bundle**：
   ```bash
   flutter build appbundle
   ```

### 从 V2Ray 核心编译库文件

V2Ray 核心库需要单独编译并集成到项目中。以下是编译步骤：

1. **安装 Go 环境**：
   ```bash
   # 安装 Go 1.17 或更高版本
   wget https://golang.org/dl/go1.17.linux-amd64.tar.gz
   sudo tar -C /usr/local -xzf go1.17.linux-amd64.tar.gz
   export PATH=$PATH:/usr/local/go/bin
   ```

2. **安装 gomobile**：
   ```bash
   go install golang.org/x/mobile/cmd/gomobile@latest
   gomobile init
   ```

3. **克隆 V2Ray 源码**：
   ```bash
   git clone https://github.com/v2fly/v2ray-core.git
   cd v2ray-core
   ```

4. **准备编译脚本**：
   创建 `build_android.sh` 文件：
   ```bash
   #!/bin/bash
   export GOPATH=$HOME/go
   export PATH=$PATH:$GOPATH/bin
   
   # 编译 arm64 版本
   gomobile bind -v -target=android/arm64 \
     -androidapi 21 \
     -ldflags="-s -w" \
     -o v2ray-core-arm64.aar \
     -tags="json" \
     ./core/...
   
   # 编译 arm 版本
   gomobile bind -v -target=android/arm \
     -androidapi 21 \
     -ldflags="-s -w" \
     -o v2ray-core-arm.aar \
     -tags="json" \
     ./core/...
   
   # 编译 x86 版本
   gomobile bind -v -target=android/386 \
     -androidapi 21 \
     -ldflags="-s -w" \
     -o v2ray-core-x86.aar \
     -tags="json" \
     ./core/...
   
   # 编译 x86_64 版本
   gomobile bind -v -target=android/amd64 \
     -androidapi 21 \
     -ldflags="-s -w" \
     -o v2ray-core-x86_64.aar \
     -tags="json" \
     ./core/...
   ```

5. **执行编译**：
   ```bash
   chmod +x build_android.sh
   ./build_android.sh
   ```

6. **集成到项目中**：
   - 将生成的 `.aar` 文件复制到 `android/app/libs/` 目录
   - 在 `android/app/build.gradle` 中添加依赖：
   ```groovy
   dependencies {
       // 其他依赖...
       implementation fileTree(dir: 'libs', include: ['*.jar', '*.aar'])
   }
   ```

7. **配置 JNI 桥接**：
   - 在 `android/app/src/main/cpp/` 目录下创建 JNI 桥接代码
   - 修改 `android/app/build.gradle` 添加 CMake 配置：
   ```groovy
   android {
       // 其他配置...
       externalNativeBuild {
           cmake {
               path "src/main/cpp/CMakeLists.txt"
           }
       }
   }
   ```

8. **创建 CMakeLists.txt 文件**：
   ```cmake
   cmake_minimum_required(VERSION 3.4.1)
   
   add_library(v2ray-lib SHARED
               bridge.cpp
               v2ray_ffi.cpp)
   
   target_link_libraries(v2ray-lib
                         android
                         log)
   ```

### 替代方案：使用预编译库

如果不想自己编译 V2Ray 核心，可以使用以下脚本下载预编译版本：

```bash
#!/bin/bash
VERSION="4.45.2"
mkdir -p android/app/libs

# 下载预编译库
curl -L -o temp.zip "https://github.com/v2fly/v2ray-core/releases/download/v${VERSION}/v2ray-android-arm64-v8a.zip"
unzip -j temp.zip "lib/arm64-v8a/*" -d "android/app/libs/"
rm temp.zip

curl -L -o temp.zip "https://github.com/v2fly/v2ray-core/releases/download/v${VERSION}/v2ray-android-armeabi-v7a.zip"
unzip -j temp.zip "lib/armeabi-v7a/*" -d "android/app/libs/"
rm temp.zip

curl -L -o temp.zip "https://github.com/v2fly/v2ray-core/releases/download/v${VERSION}/v2ray-android-x86.zip"
unzip -j temp.zip "lib/x86/*" -d "android/app/libs/"
rm temp.zip

curl -L -o temp.zip "https://github.com/v2fly/v2ray-core/releases/download/v${VERSION}/v2ray-android-x86_64.zip"
unzip -j temp.zip "lib/x86_64/*" -d "android/app/libs/"
rm temp.zip

echo "V2Ray 核心库下载完成！"
```

## 🛠️ 开发指南

### 环境设置

1. 安装 [Flutter](https://flutter.dev/docs/get-started/install) (版本 3.0 或更高)
2. 安装 [Android Studio](https://developer.android.com/studio) 与 Flutter/Dart 插件
3. 克隆项目仓库：
   ```bash
   git clone https://github.com/yourusername/flutter-v2ray-android.git
   cd flutter-v2ray-android
   ```
4. 安装依赖：
   ```bash
   flutter pub get
   ```
5. 配置 Android NDK (用于原生开发)

### 本地构建

```bash
# 开发版本构建
flutter build apk --debug

# 发布版本构建
flutter build apk --release

# 分析构建大小
flutter build apk --analyze-size
```

### 项目结构

```
flutter-v2ray-android/
├── android/                 # Android 平台特定代码
│   └── app/
│       ├── src/main/kotlin/ # Kotlin 平台通道实现
│       └── src/main/cpp/    # C++ JNI 实现
├── integration_test/        # 集成测试
├── lib/                     # Dart 源代码
│   ├── core/                # 核心功能
│   ├── models/              # 数据模型
│   ├── services/            # 服务实现
│   ├── utils/               # 工具类
│   └── views/               # UI 组件
├── test/                    # 单元测试
├── pubspec.yaml             # 项目配置与依赖
└── README.md                # 项目文档
```

### 代码风格

项目遵循 [Dart 风格指南](https://dart.dev/guides/language/effective-dart/style) 和 Flutter 最佳实践：

- 使用 `flutter analyze` 进行静态代码分析
- 遵循 MVVM 架构模式
- 编写单元测试和集成测试
- 使用依赖注入实现松耦合设计

## 🔄 版本历史

见 [CHANGELOG.md](CHANGELOG.md) 文件

## 🤝 贡献指南

欢迎贡献代码、报告问题或提供改进建议！详细指南请参见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 📄 许可证

本项目采用 [GNU General Public License v3.0](LICENSE) 许可证。

## 🙏 致谢

- [V2Ray 项目](https://github.com/v2fly/v2ray-core)
- [Flutter 框架](https://flutter.dev/)
- 所有贡献者和用户

---

**注意**：本项目仅供学习和研究网络通信协议，请遵守当地法律法规，合理合法地使用。
