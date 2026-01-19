#!/bin/bash

# 剪贴板管理器 - DMG 构建脚本
# 用法: ./build.sh

set -e

APP_NAME="ClipboardManager"
SCHEME="ClipboardManager"
BUILD_DIR="build"
DMG_NAME="${APP_NAME}.dmg"
VOLUME_NAME="剪贴板管理器"

echo "🔨 开始构建 ${APP_NAME}..."

# 清理旧构建
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# 构建 Release 版本
echo "📦 编译 Release 版本..."
xcodebuild -project "${APP_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
    archive \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# 导出 App
echo "📤 导出应用..."
xcodebuild -exportArchive \
    -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
    -exportPath "${BUILD_DIR}/Export" \
    -exportOptionsPlist "ExportOptions.plist" 2>/dev/null || {
    # 如果没有 ExportOptions.plist，直接从 archive 复制
    echo "⚠️  无签名导出，直接复制..."
    cp -R "${BUILD_DIR}/${APP_NAME}.xcarchive/Products/Applications/${APP_NAME}.app" "${BUILD_DIR}/"
}

# 确保 App 存在
if [ ! -d "${BUILD_DIR}/${APP_NAME}.app" ]; then
    cp -R "${BUILD_DIR}/Export/${APP_NAME}.app" "${BUILD_DIR}/" 2>/dev/null || \
    cp -R "${BUILD_DIR}/${APP_NAME}.xcarchive/Products/Applications/${APP_NAME}.app" "${BUILD_DIR}/"
fi

echo "✅ 应用构建完成: ${BUILD_DIR}/${APP_NAME}.app"

# 创建 DMG
echo "💿 创建 DMG..."

DMG_TEMP="${BUILD_DIR}/temp.dmg"
DMG_FINAL="${BUILD_DIR}/${DMG_NAME}"

# 创建临时 DMG
hdiutil create -srcfolder "${BUILD_DIR}/${APP_NAME}.app" \
    -volname "${VOLUME_NAME}" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    "${DMG_TEMP}"

# 挂载 DMG
MOUNT_DIR=$(hdiutil attach -readwrite -noverify "${DMG_TEMP}" | grep "/Volumes/" | awk '{print $3}')
echo "📂 挂载到: ${MOUNT_DIR}"

# 创建 Applications 快捷方式
ln -sf /Applications "${MOUNT_DIR}/Applications"

# 设置 DMG 窗口样式 (AppleScript)
echo "🎨 设置 DMG 样式..."
osascript <<EOF
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {400, 200, 900, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set position of item "${APP_NAME}.app" of container window to {120, 140}
        set position of item "Applications" of container window to {380, 140}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# 卸载
sync
hdiutil detach "${MOUNT_DIR}"

# 压缩 DMG
hdiutil convert "${DMG_TEMP}" -format UDZO -imagekey zlib-level=9 -o "${DMG_FINAL}"
rm -f "${DMG_TEMP}"

echo ""
echo "✅ 构建完成!"
echo "📍 DMG 位置: ${BUILD_DIR}/${DMG_NAME}"
echo "📍 App 位置: ${BUILD_DIR}/${APP_NAME}.app"

# 显示文件大小
ls -lh "${DMG_FINAL}"
