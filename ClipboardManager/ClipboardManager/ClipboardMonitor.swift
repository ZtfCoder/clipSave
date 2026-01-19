import Foundation
import AppKit
import Combine

// 剪贴板监听器
class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()
    
    @Published var items: [ClipboardItem] = []
    @Published var maxItems: Int = 50
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard = NSPasteboard.general
    private let storageKey = "ClipboardHistory"
    
    private init() {
        loadHistory()
        startMonitoring()
    }
    
    // 开始监听剪贴板
    func startMonitoring() {
        lastChangeCount = pasteboard.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    // 停止监听
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    // 检查剪贴板变化
    private func checkClipboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        if let item = readClipboardContent() {
            addItem(item)
        }
    }
    
    // 读取剪贴板内容
    private func readClipboardContent() -> ClipboardItem? {
        // 优先检查文件
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           !urls.isEmpty {
            let paths = urls.compactMap { $0.path }
            if !paths.isEmpty {
                return ClipboardItem(filePaths: paths)
            }
        }
        
        // 检查图片
        if let image = NSImage(pasteboard: pasteboard),
           let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            // 限制图片大小 (最大2MB)
            if pngData.count < 2 * 1024 * 1024 {
                return ClipboardItem(imageData: pngData)
            }
        }
        
        // 检查文本
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            return ClipboardItem(text: text)
        }
        
        return nil
    }
    
    // 添加项目
    private func addItem(_ item: ClipboardItem) {
        // 检查是否重复
        if let existingIndex = items.firstIndex(where: { $0 == item }) {
            items.remove(at: existingIndex)
        }
        
        items.insert(item, at: 0)
        
        // 限制数量
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        
        saveHistory()
    }
    
    // 复制项目到剪贴板
    func copyToClipboard(_ item: ClipboardItem) {
        pasteboard.clearContents()
        
        switch item.contentType {
        case .text:
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let data = item.imageData, let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
            }
        case .file:
            if let paths = item.filePaths {
                let urls = paths.compactMap { URL(fileURLWithPath: $0) }
                pasteboard.writeObjects(urls as [NSURL])
            }
        }
        
        // 更新changeCount避免重复添加
        lastChangeCount = pasteboard.changeCount
    }
    
    // 删除项目
    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    // 清空历史
    func clearHistory() {
        items.removeAll()
        saveHistory()
    }
    
    // 保存历史到本地
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    // 加载历史
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let savedItems = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = savedItems
        }
    }
    
    // 搜索
    func search(_ query: String) -> [ClipboardItem] {
        guard !query.isEmpty else { return items }
        
        return items.filter { item in
            switch item.contentType {
            case .text:
                return item.textContent?.localizedCaseInsensitiveContains(query) ?? false
            case .file:
                return item.filePaths?.contains { $0.localizedCaseInsensitiveContains(query) } ?? false
            case .image:
                return false
            }
        }
    }
}

// 粘贴板助手：处理自动激活应用和粘贴
class PasteboardHelper {
    static let shared = PasteboardHelper()
    
    // 记录上一个活跃的应用程序
    private var lastActiveApp: NSRunningApplication?
    
    private init() {}
    
    // 开始监听应用切换
    func startListening() {
        // 初始记录当前非本App的应用
        if let current = NSWorkspace.shared.frontmostApplication,
           current.bundleIdentifier != Bundle.main.bundleIdentifier {
            lastActiveApp = current
        }
        
        // 监听应用停用通知
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidDeactivate(_:)),
            name: NSWorkspace.didDeactivateApplicationNotification,
            object: nil
        )
    }
    
    @objc private func appDidDeactivate(_ notification: Notification) {
        // 当一个应用失活时，记录它（如果不是我自己）
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
           app.bundleIdentifier != Bundle.main.bundleIdentifier {
            lastActiveApp = app
        }
    }
    
    // 执行粘贴流程
    func paste(item: ClipboardItem) {
        // 1. 将内容复制到剪贴板
        ClipboardMonitor.shared.copyToClipboard(item)
        
        // 2. 隐藏当前应用，让焦点回到上一个应用
        // 注意：这比 activate 上一个应用更可靠，因为系统可以自动处理窗口层级
        DispatchQueue.main.async {
            NSApp.hide(nil)
            
            // 3. 显式尝试激活上一个应用（双重保险）
            if let app = self.lastActiveApp {
                app.activate(options: [.activateIgnoringOtherApps])
            }
            
            // 4. 等待应用完全激活后模拟按键
            // 增加延时到 0.25 秒，确保 App 已经准备好接收按键
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.simulateCommandV()
            }
        }
    }
    
    private func simulateCommandV() {
        let src = CGEventSource(stateID: .hidSystemState)
        let vKeyCode: CGKeyCode = 9 // V键
        
        // 创建 Command + V 按下事件
        if let keyDown = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }
        
        // 创建 Command + V 释放事件
        if let keyUp = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
