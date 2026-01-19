# Project Structure

```
ClipboardManager/
├── ClipboardManager.xcodeproj/    # Xcode project
├── ClipboardManager/              # Source code
│   ├── ClipboardManagerApp.swift  # App entry, AppDelegate, FloatingPanelController
│   ├── ClipboardMonitor.swift     # Clipboard polling, PasteboardHelper
│   ├── ClipboardItem.swift        # Data model (Codable)
│   ├── MenuBarView.swift          # Menu bar popover UI
│   ├── ClipboardHistoryView.swift # History list component
│   ├── SettingsView.swift         # Settings tabs, ShortcutSettingsManager
│   ├── KeyboardShortcuts.swift    # Global hotkey via Carbon API
│   ├── Assets.xcassets/           # App icons
│   ├── Info.plist                 # App configuration
│   └── ClipboardManager.entitlements
├── IconGenerator/                 # HTML tool for icon generation
├── build.sh                       # Release build + DMG script
└── README.md
```

## Architecture Patterns

### Singletons
- `ClipboardMonitor.shared` - clipboard state and history
- `KeyboardShortcutManager.shared` - hotkey registration
- `ShortcutSettingsManager.shared` - shortcut preferences
- `FloatingPanelController.shared` - floating window
- `SettingsWindowController.shared` - settings window
- `PasteboardHelper.shared` - paste automation

### State Management
- `@ObservedObject` with shared singletons
- `@AppStorage` for UserDefaults-backed preferences
- `@Published` properties for reactive updates

### UI Components
- Views are SwiftUI structs with `#Preview` macros
- Row components handle hover state locally
- Controllers manage NSWindow/NSPanel lifecycle
