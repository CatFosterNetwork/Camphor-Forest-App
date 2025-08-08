@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM 樟木林Toolbox Release构建脚本 (Windows)
REM 使用方法: scripts\build_release.bat [android|ios|all]

echo 🚀 开始构建樟木林Toolbox Release版本...

REM 检查Flutter环境
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter未安装或未在PATH中
    exit /b 1
)

REM 清理项目
echo 🧹 清理项目...
flutter clean
flutter pub get

REM 检查依赖
echo 🔍 检查依赖...
flutter doctor

REM 获取构建目标
set TARGET=%1
if "%TARGET%"=="" set TARGET=android

if "%TARGET%"=="android" goto build_android
if "%TARGET%"=="all" goto build_android
goto invalid_target

:build_android
echo 🤖 构建Android Release版本...

REM 构建APK
flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64,android-x64

REM 构建AAB (Google Play)
flutter build appbundle --release

echo ✅ Android构建完成!
echo 📦 APK文件位置: build\app\outputs\flutter-apk\
echo 📦 AAB文件位置: build\app\outputs\bundle\release\
goto end

:invalid_target
echo ❌ 无效的构建目标: %TARGET%
echo 使用方法: scripts\build_release.bat [android^|all]
echo ⚠️  iOS构建需要在macOS环境下进行
exit /b 1

:end
echo 🎉 构建完成!
