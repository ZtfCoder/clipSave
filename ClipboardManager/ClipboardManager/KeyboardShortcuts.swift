import Foundation
import AppKit
import Carbon

// 全局快捷键管理
class KeyboardShortcutManager: ObservableObject {
    static let shared = KeyboardShortcutManager()
    
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    
    var onShortcutPressed: (() -> Void)?
    
    private init() {}
    
    // 注册全局快捷键（使用保存的设置）
    func registerHotKey() {
        let shortcut = ShortcutSettingsManager.shared.currentShortcut
        registerHotKey(keyCode: shortcut.keyCode, modifiers: shortcut.modifiers)
    }
    
    // 注册指定的快捷键
    func registerHotKey(keyCode: UInt32, modifiers: UInt32) {
        // 先注销已有的
        unregisterHotKey()
        
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
            KeyboardShortcutManager.shared.onShortcutPressed?()
            return noErr
        }
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            nil,
            &eventHandler
        )
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x434C4950) // "CLIP"
        hotKeyID.id = 1
        
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
    
    // 注销快捷键
    func unregisterHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    deinit {
        unregisterHotKey()
    }
}
