# 樟木林 Toolbox 🌲

> 专为西南大学学生打造的校园生活助手

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-SDK-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Private-red.svg)](LICENSE)

一个功能丰富的西南大学学生工具箱应用，集成了课表查询、成绩管理、生活服务等多项实用功能，为学生校园生活提供便利。

## ✨ 主要特性

### 📚 学习管理
- **课程表查询** - 实时查看课程安排，支持周次选择
- **成绩查询** - 便捷查看考试成绩和成绩单打印
- **考试安排** - 查看考试时间和地点安排
- **空教室查询** - 寻找合适的自习场所

### 🏠 生活服务
- **宿舍水电费** - 查询和管理宿舍水电费用
- **校历查询** - 获取学校最新动态和重要日期
- **待办事项** - 个人任务管理和提醒功能
- **天气信息** - 实时天气数据展示

### 🎨 个性化体验
- **自定义主题** - 多种主题样式可选
- **深色模式** - 支持浅色/深色/跟随系统模式
- **个性化配置** - 灵活的功能开关和显示设置

### 🔧 技术特色
- **跨平台支持** - iOS、Android、Web、Desktop 全平台
- **现代化架构** - 基于 Flutter 3.8+ 和 Material Design 3
- **状态管理** - 使用 Riverpod 进行高效状态管理
- **缓存优化** - 智能图片缓存和数据缓存策略

## 🚀 快速开始

### 环境要求

- Flutter SDK >= 3.8.1
- Dart SDK >= 3.2.0
- Android Studio / VS Code
- iOS开发需要 Xcode (仅限 macOS)

### 安装步骤

1. **克隆项目**
   ```bash
   git clone [项目地址]
   cd camphor_forest
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **生成代码**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **运行应用**
   ```bash
   # Android/iOS
   flutter run
   
   # Web
   flutter run -d chrome
   
   # Desktop
   flutter run -d windows/macos/linux
   ```

### 构建发布版本

```bash
# Android APK
flutter build apk --release

# iOS IPA (需要 macOS)
flutter build ios --release

# Web
flutter build web --release

# Desktop
flutter build windows/macos/linux --release
```

## 📱 功能模块

### 🏠 首页 (Index)
- 个人信息展示
- 课表简览
- 待办事项快览
- 费用查询入口
- 成绩信息概览
- 天气信息

### 📅 课程表 (ClassTable)
- 课程表网格显示
- 周次选择器
- 课程详情查看
- 课程时间提醒

### 🎓 生活服务 (LifeService)
- 成绩查询和成绩单
- 空教室查询
- 考试安排查询
- 宿舍水电费管理
- 校历查看

### ⚙️ 设置 (Settings)
- 个人资料管理
- 主题和外观设置
- 功能开关配置
- 关于和反馈

## 🏗️ 项目架构

```
lib/
├── core/                  # 核心模块
│   ├── config/           # 配置管理
│   ├── constants/        # 常量定义
│   ├── models/           # 数据模型
│   ├── network/          # 网络请求
│   ├── providers/        # 状态管理
│   ├── services/         # 业务服务
│   ├── utils/            # 工具类
│   └── widgets/          # 通用组件
├── pages/                # 页面模块
│   ├── index/            # 首页
│   ├── classtable/       # 课程表
│   ├── lifeService/      # 生活服务
│   ├── login/            # 登录
│   └── settings/         # 设置
├── l10n/                 # 国际化
├── utils/                # 工具类
├── widgets/              # 共用组件
├── app.dart              # 应用入口
└── main.dart             # 主函数
```

## 🔧 主要依赖

### 核心框架
- `flutter`: Flutter SDK
- `flutter_riverpod`: 状态管理
- `go_router`: 路由管理

### UI 组件
- `flutter_platform_widgets`: 平台自适应组件
- `flutter_svg`: SVG 图片支持
- `cupertino_icons`: iOS 风格图标
- `font_awesome_flutter`: FontAwesome 图标

### 网络和数据
- `dio`: HTTP 客户端
- `shared_preferences`: 本地存储
- `flutter_secure_storage`: 安全存储
- `cached_network_image`: 网络图片缓存

### 功能增强
- `image_picker`: 图片选择
- `image_cropper`: 图片裁剪
- `url_launcher`: URL 启动
- `permission_handler`: 权限管理
- `package_info_plus`: 应用信息
- `device_info_plus`: 设备信息

## 🎯 开发指南

### 代码规范
- 遵循 Dart 官方代码规范
- 使用 `flutter_lints` 进行代码检查
- 组件命名采用 PascalCase
- 文件命名采用 snake_case

### 状态管理
项目使用 Riverpod 进行状态管理：
```dart
// Provider 定义
final counterProvider = StateProvider<int>((ref) => 0);

// 在 Widget 中使用
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('Count: $count');
  }
}
```

### 主题系统
支持动态主题切换：
```dart
// 获取当前主题
final theme = ref.watch(selectedCustomThemeProvider);

// 切换主题模式
ref.read(themeModeProvider.notifier).state = 'dark';
```

## 🔐 隐私和安全

- 敏感数据使用 `flutter_secure_storage` 加密存储
- 网络请求支持 HTTPS
- 用户数据仅用于应用功能，不会泄露给第三方
- 支持数据导出和删除

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📝 更新日志

### v1.0.0 (当前版本)
- ✨ 初始版本发布
- 📚 完整的课程表功能
- 🎓 生活服务模块
- 🎨 自定义主题系统
- 📱 跨平台支持

---

**免责声明**: 本应用仅为学习和便利目的开发，不承担因使用本应用而产生的任何责任。请遵守学校相关规定。
