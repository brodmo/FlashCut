# FlashCut Development Guide

## 🏗️ Architecture

FlashCut is built with SwiftUI and follows a stateless architecture.

### Core Principles

1. **Stateless Design** - No tracking of "active workspace/group"
2. **App-Centric** - Current app determines cycling context
3. **Minimal Dependencies** - No Accessibility API required
4. **TOML Configuration** - Human-readable config files

### Project Structure

```
FlashSpace/
├── App/                    # App lifecycle, dependencies
│   ├── FlashCutApp.swift  # Main SwiftUI app
│   ├── AppDelegate.swift   # App lifecycle hooks
│   └── AppDependencies.swift
├── Features/
│   ├── AppGroups/          # App group management
│   │   ├── Models/
│   │   ├── AppGroupRepository.swift
│   │   └── AppGroupManager.swift
│   ├── AppManager/         # App cycling logic
│   ├── HotKeys/            # Global hotkey handling
│   ├── MainScreen/         # Main window UI
│   └── Settings/           # Settings UI
│       ├── General/
│       └── AppGroups/
├── Extensions/             # Swift extensions
└── Features/Config/        # TOML serialization
```

### Key Components

#### AppGroupRepository
Manages app group data and persistence via TOML files.

**Responsibilities:**
- Load/save app groups from `~/.config/flashcut/appgroups.toml`
- CRUD operations on groups and apps
- Publish changes via Combine

**Key Methods:**
- `addAppGroup(name:)` - Create new group
- `updateAppGroup(_:)` - Update existing group
- `addApp(to:app:)` - Add app to group
- `deleteApp(from:app:)` - Remove app from group

#### AppGroupManager
Handles app group activation and app launching.

**Responsibilities:**
- Activate groups (find and focus an app)
- Cycle between groups
- Launch apps when activating a group

**State:** Minimal - only tracks `lastActivatedAppGroup` for cycling

**Key Methods:**
- `activateAppGroup(_:setFocus:)` - Main activation logic
- `activateAppGroup(next:loop:)` - Cycle to next/previous group
- `findApp(in:)` - Find which app to activate (primary or most recent)

#### AppManager
Manages cycling between apps within the same group.

**Responsibilities:**
- Determine which group the current app belongs to
- Cycle to next/previous app in that group

**Stateless:** Uses current app to determine context

**Key Methods:**
- `nextAppGroupApp()` - Switch to next app in current group
- `previousAppGroupApp()` - Switch to previous app in current group
- `getCurrentAppIndex()` - Find current app's position in its group

#### HotKeysManager
Registers and manages global keyboard shortcuts.

**Responsibilities:**
- Register hotkeys with macOS
- Dispatch actions when hotkeys are pressed
- Refresh hotkeys when settings change

**Dependencies:**
- ShortcutRecorder framework
- AppGroupHotKeys (group-specific hotkeys)
- AppManager (cycling hotkeys)

### Settings Architecture

Settings use a repository pattern with observable objects:

```
SettingsRepository
├── GeneralSettings
└── AppGroupSettings

Each settings object:
- @Published properties
- Load from AppSettings struct (Codable)
- Save to AppSettings when changed
- Publish updates via Combine
```

Configuration is serialized to `~/.config/flashcut/settings.toml` using TOMLKit.

## 🛠️ Build Setup

### Prerequisites

- macOS 14.0+
- Xcode 15.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [SwiftLint](https://github.com/realm/SwiftLint) (optional)
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) (optional)

### Install Dependencies

```bash
brew install xcodegen swiftlint swiftformat
```

### Generate Project

FlashCut uses XcodeGen to generate the Xcode project from `project.yml`:

```bash
xcodegen generate
```

This creates `FlashCut.xcodeproj` from the configuration in `project.yml`.

### Build and Run

```bash
open FlashCut.xcodeproj
# Build and run in Xcode (⌘R)
```

Or via command line:

```bash
xcodebuild -project FlashCut.xcodeproj -scheme FlashCut build
```

## 📦 Dependencies

All dependencies are managed via Swift Package Manager:

- **[ShortcutRecorder](https://github.com/Kentzo/ShortcutRecorder)** - Global hotkey capture
- **[TOMLKit](https://github.com/LebJe/TOMLKit)** - TOML serialization
- **[Sparkle](https://github.com/sparkle-project/Sparkle)** - Auto-updates

No Accessibility frameworks or private APIs are used.

## 🔧 Configuration

### project.yml

Defines the Xcode project structure. Key sections:

```yaml
name: FlashCut
bundleIdPrefix: com.flashcut

targets:
  FlashCut:
    sources: [FlashSpace]  # Source directory
    settings:
      MARKETING_VERSION: 1.0.0
      INFOPLIST_KEY_CFBundleDisplayName: FlashCut
      SUFeedURL: https://brodmo.github.io/FlashCut/appcast.xml
```

After editing `project.yml`, regenerate with `xcodegen generate`.

### .swiftlint.yml

SwiftLint rules for code quality. Configured to ignore:
- Line length in some cases
- Force unwrapping where safe
- Generated files

### .swiftformat

SwiftFormat configuration for consistent code style.

## 🧪 Testing

Currently no automated tests (inherited from FlashSpace).

Manual testing checklist:
- [ ] Create app group
- [ ] Add apps to group
- [ ] Set group hotkey
- [ ] Activate group via hotkey
- [ ] Cycle apps within group
- [ ] Settings persist after restart
- [ ] Dock icon shows/hides correctly

## 🚀 Release Process

### Version Bump

1. Update `MARKETING_VERSION` in `project.yml`
2. Regenerate project: `xcodegen generate`
3. Commit changes

### Build Release

```bash
# Archive in Xcode
# Product → Archive
# Distribute App → Copy App
```

### Create Release

1. Tag version: `git tag v1.0.0`
2. Push tag: `git push --tags`
3. Create GitHub release with `.app` bundle
4. Update Sparkle appcast.xml

## 📝 Code Style

### Swift Conventions

- Use SwiftUI for all UI
- Prefer `@Published` over manual Combine publishers
- Keep view models minimal - push logic to repositories/managers
- Use `@StateObject` for owned dependencies
- Use `@ObservedObject` for injected dependencies

### Naming

- **Repositories**: Data layer, persistence, CRUD
- **Managers**: Business logic, coordination
- **ViewModels**: UI state, user interaction
- **Views**: Pure SwiftUI, minimal logic

### File Organization

- One type per file
- Group related files in folders
- Models in `/Models` subdirectories
- Keep feature folders self-contained

## 🐛 Debugging

### Common Issues

**Hotkeys not working:**
- Check System Settings → Privacy → Accessibility (should NOT be needed!)
- Restart FlashCut
- Check for conflicting global hotkeys

**Config not persisting:**
- Check `~/.config/flashcut/` exists and is writable
- Look for TOML syntax errors in config files

**App won't start:**
- Check Console.app for crash logs
- Verify code signing
- Try clean build (⇧⌘K then ⌘B)

### Logging

FlashCut uses a simple Logger:

```swift
Logger.log("Message here")
```

Logs appear in Xcode console or Console.app when running the app.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Guidelines

- Follow existing code style
- Keep changes focused and atomic
- Update documentation for new features
- Don't add dependencies without discussion
- Maintain the stateless architecture

### What to Contribute

**Wanted:**
- Bug fixes
- Performance improvements
- Documentation improvements
- UI/UX enhancements (while keeping it simple)
- TOML config file validation

**Not wanted:**
- Window management features
- App hiding/showing logic
- Display/monitor tracking
- Accessibility API usage
- Feature bloat

## 📚 Resources

- [Original FlashSpace](https://github.com/wojciech-kulik/FlashSpace)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [TOMLKit](https://github.com/LebJe/TOMLKit)
- [ShortcutRecorder](https://github.com/Kentzo/ShortcutRecorder)

## 🏛️ Architecture Decisions

### Why Stateless?

Traditional workspace managers track "active workspace" state. This creates complexity:
- State must be persisted and synced
- Edge cases when apps move between displays
- Ambiguity when apps are in multiple workspaces

FlashCut's stateless approach:
- Current app IS the context
- No state to get out of sync
- Simpler mental model
- Fewer bugs

### Why No Accessibility API?

Accessibility APIs are powerful but:
- Require user permission (friction)
- Often break between macOS versions
- Not needed for basic app switching

FlashCut uses standard `NSRunningApplication` API which is:
- Reliable
- No permissions required
- Sufficient for switching apps

### Why TOML?

Over JSON or plist:
- Human-readable
- Comments supported
- Strong typing
- Better for configuration files

Over YAML:
- Simpler syntax
- Better Swift library support
- Fewer edge cases

## 💭 Philosophy

FlashCut embraces the Unix philosophy:
- Do one thing well (app switching via hotkeys)
- Keep it simple
- Avoid feature creep
- Be maintainable

If a feature adds significant complexity, it probably doesn't belong in FlashCut.
