import SwiftUI
import ServiceManagement
import Carbon

// 设置视图
struct SettingsView: View {
    @ObservedObject var monitor = ClipboardMonitor.shared
    @StateObject private var shortcutManager = ShortcutSettingsManager.shared
    
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 50
    
    var body: some View {
        TabView {
            GeneralSettingsView(
                launchAtLogin: $launchAtLogin,
                maxHistoryItems: $maxHistoryItems,
                monitor: monitor
            )
            .tabItem {
                Label("通用", systemImage: "gear")
            }
            
            ShortcutSettingsView()
            .tabItem {
                Label("快捷键", systemImage: "keyboard")
            }
            
            DataSettingsView(monitor: monitor)
            .tabItem {
                Label("数据", systemImage: "externaldrive")
            }
            
            AboutSettingsView()
            .tabItem {
                Label("关于", systemImage: "info.circle")
            }
        }
        .frame(width: 450, height: 280)
    }
}

// MARK: - 通用设置
struct GeneralSettingsView: View {
    @Binding var launchAtLogin: Bool
    @Binding var maxHistoryItems: Int
    var monitor: ClipboardMonitor
    
    var body: some View {
        Form {
            Section {
                Toggle("开机时自动启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(newValue)
                    }
                
                Picker("最大保存条数", selection: $maxHistoryItems) {
                    Text("20 条").tag(20)
                    Text("50 条").tag(50)
                    Text("100 条").tag(100)
                    Text("200 条").tag(200)
                    Text("500 条").tag(500)
                }
                .onChange(of: maxHistoryItems) { newValue in
                    monitor.maxItems = newValue
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("设置开机启动失败: \(error)")
        }
    }
}

// MARK: - 快捷键设置
struct ShortcutSettingsView: View {
    @ObservedObject var manager = ShortcutSettingsManager.shared
    @State private var isRecordingOpen = false
    @State private var isRecordingPaste = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("打开剪贴板历史")
                    Spacer()
                    ShortcutRecorderView(
                        shortcut: $manager.currentShortcut,
                        isRecording: $isRecordingOpen
                    )
                }
                
                if isRecordingOpen {
                    Text("按下新的快捷键组合...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("呼出快捷键")
            }
            
            Section {
                HStack {
                    Text("粘贴快捷键")
                    Spacer()
                    ShortcutRecorderView(
                        shortcut: $manager.pasteShortcut,
                        isRecording: $isRecordingPaste
                    )
                }
                
                if isRecordingPaste {
                    Text("按下新的快捷键组合...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("粘贴设置")
            } footer: {
                Text("自定义粘贴时模拟的快捷键，默认 ⌘V。如果你改过系统键位，可以在这里调整。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button("恢复所有默认设置") {
                    manager.resetToDefault()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - 快捷键录制视图
struct ShortcutRecorderView: View {
    @Binding var shortcut: KeyboardShortcut
    @Binding var isRecording: Bool
    
    var body: some View {
        Button(action: { isRecording.toggle() }) {
            Text(shortcut.displayString)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isRecording ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if isRecording {
                    if let newShortcut = KeyboardShortcut.from(event: event) {
                        shortcut = newShortcut
                        ShortcutSettingsManager.shared.updateShortcut(newShortcut)
                        isRecording = false
                    }
                    return nil
                }
                return event
            }
        }
    }
}

// MARK: - 数据设置
struct DataSettingsView: View {
    var monitor: ClipboardMonitor
    @State private var showClearAlert = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("当前记录数")
                    Spacer()
                    Text("\(monitor.items.count) 条")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("存储位置")
                    Spacer()
                    Text("UserDefaults")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button("清空所有历史记录", role: .destructive) {
                    showClearAlert = true
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .padding()
        .alert("确认清空", isPresented: $showClearAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                monitor.clearHistory()
            }
        } message: {
            Text("将删除所有剪贴板历史记录，此操作不可撤销。")
        }
    }
}

// MARK: - 关于
struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.linearGradient(
                    colors: [.purple, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            Text("剪贴板管理器")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("版本 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("一款简洁的 macOS 剪贴板历史管理工具")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Link("GitHub", destination: URL(string: "https://github.com")!)
                .font(.caption)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 快捷键模型
struct KeyboardShortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
    
    // 默认呼出快捷键: ⌘⇧V
    static let defaultOpenShortcut = KeyboardShortcut(keyCode: 9, modifiers: UInt32(cmdKey | shiftKey))
    // 默认粘贴快捷键: ⌘V
    static let defaultPasteShortcut = KeyboardShortcut(keyCode: 9, modifiers: UInt32(cmdKey))
    
    var displayString: String {
        var parts: [String] = []
        
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        
        parts.append(keyCodeToString(keyCode))
        
        return parts.joined()
    }
    
    private func keyCodeToString(_ code: UInt32) -> String {
        let keyMap: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 10: "§", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
            24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O",
            32: "U", 33: "[", 34: "I", 35: "P", 36: "↩", 37: "L", 38: "J", 39: "'",
            40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
            48: "⇥", 49: "Space", 50: "`", 51: "⌫"
        ]
        return keyMap[code] ?? "?"
    }
    
    static func from(event: NSEvent) -> KeyboardShortcut? {
        let keyCode = UInt32(event.keyCode)
        var modifiers: UInt32 = 0
        
        if event.modifierFlags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if event.modifierFlags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if event.modifierFlags.contains(.option) { modifiers |= UInt32(optionKey) }
        if event.modifierFlags.contains(.control) { modifiers |= UInt32(controlKey) }
        
        // 至少需要一个修饰键
        guard modifiers != 0 else { return nil }
        
        return KeyboardShortcut(keyCode: keyCode, modifiers: modifiers)
    }
    
    // 转换为 CGEventFlags
    var cgEventFlags: CGEventFlags {
        var flags: CGEventFlags = []
        if modifiers & UInt32(cmdKey) != 0 { flags.insert(.maskCommand) }
        if modifiers & UInt32(shiftKey) != 0 { flags.insert(.maskShift) }
        if modifiers & UInt32(optionKey) != 0 { flags.insert(.maskAlternate) }
        if modifiers & UInt32(controlKey) != 0 { flags.insert(.maskControl) }
        return flags
    }
}

// MARK: - 快捷键设置管理器
class ShortcutSettingsManager: ObservableObject {
    static let shared = ShortcutSettingsManager()
    
    @Published var currentShortcut: KeyboardShortcut {
        didSet { saveSettings() }
    }
    
    @Published var pasteShortcut: KeyboardShortcut {
        didSet { saveSettings() }
    }
    
    private let openShortcutKey = "KeyboardShortcut"
    private let pasteShortcutKey = "PasteShortcut"
    
    private init() {
        // 加载呼出快捷键
        if let data = UserDefaults.standard.data(forKey: openShortcutKey),
           let shortcut = try? JSONDecoder().decode(KeyboardShortcut.self, from: data) {
            currentShortcut = shortcut
        } else {
            currentShortcut = .defaultOpenShortcut
        }
        
        // 加载粘贴快捷键
        if let data = UserDefaults.standard.data(forKey: pasteShortcutKey),
           let shortcut = try? JSONDecoder().decode(KeyboardShortcut.self, from: data) {
            pasteShortcut = shortcut
        } else {
            pasteShortcut = .defaultPasteShortcut
        }
    }
    
    func updateShortcut(_ shortcut: KeyboardShortcut) {
        currentShortcut = shortcut
        // 重新注册快捷键
        KeyboardShortcutManager.shared.unregisterHotKey()
        KeyboardShortcutManager.shared.registerHotKey(
            keyCode: shortcut.keyCode,
            modifiers: shortcut.modifiers
        )
    }
    
    func resetToDefault() {
        currentShortcut = .defaultOpenShortcut
        pasteShortcut = .defaultPasteShortcut
        updateShortcut(.defaultOpenShortcut)
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(currentShortcut) {
            UserDefaults.standard.set(data, forKey: openShortcutKey)
        }
        if let data = try? JSONEncoder().encode(pasteShortcut) {
            UserDefaults.standard.set(data, forKey: pasteShortcutKey)
        }
    }
}

#Preview {
    SettingsView()
}
