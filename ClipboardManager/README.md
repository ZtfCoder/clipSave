# 📋 剪贴板管理器

一款 macOS 原生剪贴板历史管理工具，使用 SwiftUI 开发。

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ 功能特性

- 🔄 自动保存最近 50 条复制内容（可调整）
- 📝 支持文本、图片、文件三种类型
- 🔍 快速搜索历史记录
- ⌨️ 全局快捷键 `⌘⇧V` 快速调出
- 📌 菜单栏常驻，随时访问
- 💾 数据本地持久化存储
- 🚀 开机自启动（可选）

## 📦 安装

### 方式一：源码编译

1. 克隆项目
```bash
git clone <repo-url>
cd ClipboardManager
```

2. 用 Xcode 打开项目
```bash
open ClipboardManager.xcodeproj
```

3. 选择 `Product` → `Build` (⌘B) 编译

4. 运行 `Product` → `Run` (⌘R)

### 方式二：直接下载

从 Releases 页面下载 `ClipboardManager.app`，拖入应用程序文件夹即可。

## 🚀 使用方法

### 基本操作

| 操作 | 说明 |
|------|------|
| 点击菜单栏图标 | 打开剪贴板历史 |
| `⌘⇧V` | 全局快捷键打开 |
| 单击条目 | 复制到剪贴板 |
| 双击条目 | 复制并关闭窗口 |
| 搜索框输入 | 过滤历史记录 |

### 首次运行

1. 运行后会在菜单栏出现 📋 图标
2. 系统可能提示授予「辅助功能」权限（用于全局快捷键）
   - 打开「系统设置」→「隐私与安全性」→「辅助功能」
   - 找到「ClipboardManager」并开启
3. 复制任何内容，即可在历史中看到

### 设置

点击菜单栏图标后，使用 `⌘,` 打开设置，可配置：

- 开机自启动
- 最大保存条数（20/50/100/200）
- 清空历史记录

## 🛠 技术实现

```
ClipboardManager/
├── ClipboardManagerApp.swift   # 应用入口 + AppDelegate
├── ClipboardMonitor.swift      # NSPasteboard 监听核心
├── ClipboardItem.swift         # 数据模型
├── MenuBarView.swift           # 菜单栏弹出视图
├── ClipboardHistoryView.swift  # 历史列表
├── SettingsView.swift          # 设置页面
└── KeyboardShortcuts.swift     # 全局快捷键 (Carbon API)
```

### 核心技术

- **剪贴板监听**：Timer 轮询 `NSPasteboard.changeCount`
- **数据存储**：`UserDefaults` + `Codable` 序列化
- **全局快捷键**：Carbon `RegisterEventHotKey` API
- **菜单栏**：`NSStatusItem` + `NSPopover`

## 📋 系统要求

- macOS 13.0 (Ventura) 或更高版本
- 约 5MB 磁盘空间

## 📄 License

MIT License
