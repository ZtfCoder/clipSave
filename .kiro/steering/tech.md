# Tech Stack

## Language & Frameworks
- Swift 5.0
- SwiftUI for all UI components
- AppKit for system integration (NSPasteboard, NSStatusItem, NSPopover, NSPanel)
- Carbon API for global hotkey registration (RegisterEventHotKey)
- ServiceManagement for launch-at-login

## Build System
- Xcode project (ClipboardManager.xcodeproj)
- No external dependencies or package managers

## Key APIs
- `NSPasteboard.general` - clipboard access
- `CGEvent` - simulating keyboard input for paste
- `NSWorkspace` - app switching and notifications
- `UserDefaults` + `Codable` - data persistence

## Build Commands

```bash
# Build from command line
cd ClipboardManager
xcodebuild -project ClipboardManager.xcodeproj -scheme ClipboardManager -configuration Debug build

# Build release + DMG
./build.sh

# Open in Xcode
open ClipboardManager.xcodeproj
```

## Code Signing
- Development builds use ad-hoc signing (`CODE_SIGN_IDENTITY="-"`)
- No notarization configured
