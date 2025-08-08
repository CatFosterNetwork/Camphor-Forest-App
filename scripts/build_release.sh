#!/bin/bash

# 樟木林Toolbox Release构建脚本
# 使用方法: ./scripts/build_release.sh [android|ios|all]

set -e

echo "🚀 开始构建樟木林Toolbox Release版本..."

# 检查Flutter环境
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter未安装或未在PATH中"
    exit 1
fi

# 清理项目
echo "🧹 清理项目..."
flutter clean
flutter pub get

# 检查依赖
echo "🔍 检查依赖..."
flutter doctor

# 获取构建目标
TARGET=${1:-all}

build_android() {
    echo "🤖 构建Android Release版本..."
    
    # 构建APK
    flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64,android-x64
    
    # 构建AAB (Google Play)
    flutter build appbundle --release
    
    echo "✅ Android构建完成!"
    echo "📦 APK文件位置: build/app/outputs/flutter-apk/"
    echo "📦 AAB文件位置: build/app/outputs/bundle/release/"
}

build_ios() {
    echo "🍎 构建iOS Release版本..."
    
    # 检查是否在macOS上
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "❌ iOS构建需要在macOS上进行"
        exit 1
    fi
    
    # 构建iOS
    flutter build ios --release --no-codesign
    
    echo "✅ iOS构建完成!"
    echo "📦 iOS构建位置: build/ios/iphoneos/"
    echo "ℹ️  请使用Xcode进行签名和发布"
}

# 执行构建
case $TARGET in
    android)
        build_android
        ;;
    ios)
        build_ios
        ;;
    all)
        build_android
        if [[ "$OSTYPE" == "darwin"* ]]; then
            build_ios
        else
            echo "⚠️  跳过iOS构建（需要macOS环境）"
        fi
        ;;
    *)
        echo "❌ 无效的构建目标: $TARGET"
        echo "使用方法: ./scripts/build_release.sh [android|ios|all]"
        exit 1
        ;;
esac

echo "🎉 构建完成!"
