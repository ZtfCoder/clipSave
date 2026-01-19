import SwiftUI

@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

// 设置窗口控制器
class SettingsWindowController {
    static let shared = SettingsWindowController()
    
    private var window: NSWindow?
    
    func open() {
        if let window = window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        window = NSWindow(contentViewController: hostingController)
        window?.title = "设置"
        window?.styleMask = [.titled, .closable]
        window?.center()
        window?.setFrameAutosaveName("SettingsWindow")
        window?.makeKeyAndOrderFront(nil)
        
        NSApp.activate(ignoringOtherApps: true)
    }
}

// 悬浮窗口控制器 - 在鼠标位置显示
class FloatingPanelController {
    static let shared = FloatingPanelController()
    
    private var panel: NSPanel?
    private var eventMonitor: Any?
    private var previousApp: NSRunningApplication? // 记住之前的应用
    
    func toggle() {
        if let panel = panel, panel.isVisible {
            close()
        } else {
            show()
        }
    }
    
    func show() {
        // 先记住当前活跃的应用（在做任何事情之前）
        let currentApp = NSWorkspace.shared.frontmostApplication
        if currentApp?.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousApp = currentApp
        }
        
        close()
        
        let contentView = FloatingClipboardView(onClose: { [weak self] in
            self?.close()
        }, onPaste: { [weak self] in
            self?.pasteToPrevoiusApp()
        })
        let hostingController = NSHostingController(rootView: contentView)
        
        // 创建悬浮面板
        panel = NSPanel(contentViewController: hostingController)
        panel?.styleMask = [.nonactivatingPanel, .fullSizeContentView, .borderless]
        panel?.level = .floating
        panel?.isOpaque = false
        panel?.backgroundColor = .clear
        panel?.hasShadow = true
        panel?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel?.hidesOnDeactivate = false
        panel?.becomesKeyOnlyIfNeeded = true
        
        // 设置窗口大小
        let panelSize = NSSize(width: 340, height: 420)
        panel?.setContentSize(panelSize)
        
        // 获取鼠标位置并计算窗口位置
        let mouseLocation = NSEvent.mouseLocation
        var panelOrigin = mouseLocation
        
        // 确保窗口不超出屏幕边界
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            
            if mouseLocation.x + panelSize.width > screenFrame.maxX {
                panelOrigin.x = mouseLocation.x - panelSize.width
            }
            
            panelOrigin.y = mouseLocation.y - panelSize.height
            
            if panelOrigin.y < screenFrame.minY {
                panelOrigin.y = screenFrame.minY
            }
            
            if panelOrigin.y + panelSize.height > screenFrame.maxY {
                panelOrigin.y = screenFrame.maxY - panelSize.height
            }
        }
        
        panel?.setFrameOrigin(panelOrigin)
        panel?.orderFrontRegardless()
        
        // 监听点击外部关闭
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let panel = self?.panel {
                let screenClickLocation = NSEvent.mouseLocation
                if !panel.frame.contains(screenClickLocation) {
                    self?.close()
                }
            }
        }
    }
    
    func close() {
        panel?.close()
        panel = nil
        
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    // 粘贴到之前的应用
    func pasteToPrevoiusApp() {
        // 先关闭面板
        close()
        
        // 使用 PasteboardHelper 进行粘贴逻辑
        // 注意：这里我们不需要传递 ClipboardItem，因为逻辑假设已经在剪贴板里了
        // 或者我们可以重构 PasteboardHelper 可以支持“直接触发粘贴”
        
        // 由于 FloatingPanelController 也是“本应用”，我们同样需要隐藏并回退到上一个应用
        // PasteboardHelper 已经维护了 lastActiveApp，所以可以直接利用它的后半部分逻辑
        // 但由于 PasteboardHelper.paste(item) 会重新写入剪贴板（其实没坏处），直接用最简单
        
        // 这里稍微 hack 一下，直接利用 Helper 的激活和按键逻辑
        // 为了方便，我们读取当前剪贴板的最新 item 传进去，或者稍微修改 Helper
        
        // 简单方案：手动调用 Helper 的逻辑部分
        DispatchQueue.main.async {
            NSApp.hide(nil)
            
            // FloatingPanelController 自己维护了 previousApp，我们可以用那个，也可以用 Helper 的
            // 既然我们要统一，建议信任 Helper
            // 但为了保险，如果 Helper 没记录到（因为悬浮窗可能没触发 Deactivate 通知如果它是非激活面板），依然尝试 activate previousApp
            
            if let app = self.previousApp {
                app.activate(options: [.activateIgnoringOtherApps])
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                // 模拟 Cmd+V
                let src = CGEventSource(stateID: .hidSystemState)
                let vKeyCode: CGKeyCode = 9
                
                if let keyDown = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: true) {
                    keyDown.flags = .maskCommand
                    keyDown.post(tap: .cghidEventTap)
                }
                if let keyUp = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: false) {
                    keyUp.flags = .maskCommand
                    keyUp.post(tap: .cghidEventTap)
                }
            }
        }
    }
}

// 悬浮窗口的剪贴板视图
struct FloatingClipboardView: View {
    @ObservedObject var monitor = ClipboardMonitor.shared
    @State private var searchText = ""
    var onClose: () -> Void
    var onPaste: () -> Void
    
    var filteredItems: [ClipboardItem] {
        monitor.search(searchText)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏（可拖动）
            HStack {
                Image(systemName: "doc.on.clipboard.fill")
                    .foregroundColor(.accentColor)
                Text("剪贴板历史")
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 搜索框
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                TextField("搜索...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            // 列表
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "暂无记录" : "未找到匹配内容")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredItems) { item in
                            FloatingItemRow(item: item) {
                                monitor.copyToClipboard(item)
                                onPaste()
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            }
            
            Divider()
            
            // 底部工具栏
            HStack {
                Text("\(filteredItems.count) 条记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { SettingsWindowController.shared.open() }) {
                    Image(systemName: "gear")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 340, height: 420)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// 悬浮窗口的列表项
struct FloatingItemRow: View {
    let item: ClipboardItem
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            // 类型图标
            Group {
                switch item.contentType {
                case .text:
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                case .image:
                    if let image = item.nsImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 24, height: 24)
                            .cornerRadius(4)
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(.green)
                    }
                case .file:
                    Image(systemName: "folder.fill")
                        .foregroundColor(.orange)
                }
            }
            .frame(width: 24)
            
            // 内容
            Text(item.previewText)
                .font(.system(size: 12))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 时间
            Text(item.formattedTime)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isHovered ? Color.accentColor.opacity(0.15) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onTap()
        }
    }
}

// App Delegate 处理菜单栏
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var eventMonitor: Any?
    var menu: NSMenu?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupHotKey()
        setupRightClickMenu()
        
        // 隐藏Dock图标
        NSApp.setActivationPolicy(.accessory)
        
        // 检查辅助功能权限
        checkAccessibilityPermission()
        
        // 启动粘贴助手监听
        PasteboardHelper.shared.startListening()
    }
    
    // 检查辅助功能权限
    private func checkAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("需要辅助功能权限来实现自动粘贴功能")
        }
    }
    
    // 设置菜单栏图标
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "剪贴板管理器")
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // 创建弹出窗口（用于菜单栏点击）
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 380)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(rootView: MenuBarView())
        
        // 监听点击外部关闭 popover
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if self?.popover?.isShown == true {
                self?.popover?.performClose(nil)
            }
        }
    }
    
    // 设置右键菜单
    private func setupRightClickMenu() {
        menu = NSMenu()
        
        let settingsItem = NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu?.addItem(settingsItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        let clearItem = NSMenuItem(title: "清空历史", action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        menu?.addItem(clearItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
    }
    
    // 处理点击事件
    @objc func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // 右键显示菜单
            popover?.performClose(nil)
            if let menu = menu, let button = statusItem?.button {
                menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 5), in: button)
            }
        } else {
            // 左键显示弹窗
            togglePopover()
        }
    }
    
    // 设置全局快捷键
    private func setupHotKey() {
        KeyboardShortcutManager.shared.onShortcutPressed = {
            DispatchQueue.main.async {
                // 快捷键触发时，在鼠标位置显示悬浮窗口
                FloatingPanelController.shared.toggle()
            }
        }
        KeyboardShortcutManager.shared.registerHotKey()
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    // 打开设置
    @objc func openSettings() {
        popover?.performClose(nil)
        SettingsWindowController.shared.open()
    }
    
    // 清空历史
    @objc func clearHistory() {
        ClipboardMonitor.shared.clearHistory()
    }
    
    // 退出应用
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        KeyboardShortcutManager.shared.unregisterHotKey()
    }
}
