#!/bin/bash

# 版本号管理脚本
# 使用方法: ./scripts/bump_version.sh [major|minor|patch] [build_number]

set -e

PUBSPEC_FILE="pubspec.yaml"

if [ ! -f "$PUBSPEC_FILE" ]; then
    echo "❌ 找不到pubspec.yaml文件"
    exit 1
fi

# 获取当前版本
CURRENT_VERSION=$(grep "^version:" $PUBSPEC_FILE | sed 's/version: //')
CURRENT_VERSION_NAME=$(echo $CURRENT_VERSION | cut -d'+' -f1)
CURRENT_BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)

echo "📋 当前版本: $CURRENT_VERSION"
echo "   版本名: $CURRENT_VERSION_NAME"
echo "   构建号: $CURRENT_BUILD_NUMBER"

# 解析版本号
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION_NAME"
MAJOR=${VERSION_PARTS[0]}
MINOR=${VERSION_PARTS[1]}
PATCH=${VERSION_PARTS[2]}

# 获取更新类型
UPDATE_TYPE=${1:-patch}
NEW_BUILD_NUMBER=${2:-$((CURRENT_BUILD_NUMBER + 1))}

# 计算新版本号
case $UPDATE_TYPE in
    major)
        NEW_MAJOR=$((MAJOR + 1))
        NEW_MINOR=0
        NEW_PATCH=0
        ;;
    minor)
        NEW_MAJOR=$MAJOR
        NEW_MINOR=$((MINOR + 1))
        NEW_PATCH=0
        ;;
    patch)
        NEW_MAJOR=$MAJOR
        NEW_MINOR=$MINOR
        NEW_PATCH=$((PATCH + 1))
        ;;
    *)
        echo "❌ 无效的更新类型: $UPDATE_TYPE"
        echo "使用方法: ./scripts/bump_version.sh [major|minor|patch] [build_number]"
        exit 1
        ;;
esac

NEW_VERSION_NAME="$NEW_MAJOR.$NEW_MINOR.$NEW_PATCH"
NEW_VERSION="$NEW_VERSION_NAME+$NEW_BUILD_NUMBER"

echo ""
echo "🚀 更新版本:"
echo "   $UPDATE_TYPE 更新: $CURRENT_VERSION_NAME → $NEW_VERSION_NAME"
echo "   构建号: $CURRENT_BUILD_NUMBER → $NEW_BUILD_NUMBER"
echo "   完整版本: $NEW_VERSION"

# 确认更新
read -p "确认更新版本? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 取消更新"
    exit 1
fi

# 更新pubspec.yaml
sed -i.bak "s/version: $CURRENT_VERSION/version: $NEW_VERSION/" $PUBSPEC_FILE
rm -f $PUBSPEC_FILE.bak

echo "✅ 版本已更新到 $NEW_VERSION"
echo "📝 请记得更新CHANGELOG.md并提交代码"
