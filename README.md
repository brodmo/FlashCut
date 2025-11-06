# ⚡ FlashCut

**FlashCut** is a keyboard-focused app switcher for macOS. Organize your apps into groups and switch between them with customizable hotkeys.

It's a streamlined fork of [FlashSpace](https://github.com/wojciech-kulik/FlashSpace) that removes window management, app hiding, and other advanced features to focus purely on keyboard-driven app switching.

## 🎯 What It Does

- **Organize apps into groups** - Create groups like "Development", "Communication", "Design"
- **Switch with hotkeys** - Press a hotkey to jump to any app in a group
- **Cycle through apps** - Navigate between apps within the same group
- **Launch apps together** - Optionally start all apps in a group at once

**What FlashCut does NOT do:**
- ❌ Hide or show apps automatically
- ❌ Manage window positions or sizes
- ❌ Require Accessibility permissions
- ❌ Track "active workspace" state
- ❌ Assign apps to specific displays

If you need these features, check out the original [FlashSpace](https://github.com/wojciech-kulik/FlashSpace).

## ⚙️ Installation

**Requirements:** macOS 14.0 or later

### Download
*(Coming soon - check [Releases](https://github.com/brodmo/FlashSpace/releases))*

### Build From Source

```bash
# Install XcodeGen
brew install xcodegen

# Generate and open project
xcodegen generate
open FlashCut.xcodeproj
```

## 🚀 Quick Start

1. **Launch FlashCut** - The window appears automatically on first launch
2. **Create an app group** - Click the + button
3. **Add some apps** - Drag apps from your Applications folder
4. **Set a hotkey** - Click in the "Activate Shortcut" field and press your desired key combination
5. **Try it out** - Press your hotkey to activate apps in that group

### Example Setup

```
📁 Development
   • Visual Studio Code
   • Terminal
   • Safari
   Hotkey: ⌘⇧D

📁 Communication
   • Slack
   • Mail
   • Calendar
   Hotkey: ⌘⇧C
```

**Workflow:**
- Press `⌘⇧D` → Opens/switches to VS Code (or Terminal if it was last used)
- Press "Next App in Group" → Cycles to next Development app
- Press `⌘⇧C` → Switches to Slack
- Repeat!

## ⚙️ Settings

Access settings by pressing `⌘,` in the main window or clicking the gear icon.

### General
- **Launch at startup** - Start FlashCut when you log in
- **Check for updates automatically** - Get notified of new versions
- **Toggle FlashCut Window** - Hotkey to show/hide the main window
- **Configuration File** - Location of TOML config files (advanced users)

### App Groups
- **Group Cycling** - Hotkeys to switch between groups
  - Recent Group - Jump to previously active group
  - Previous/Next Group - Navigate through groups in order
  - Loop Groups - Wrap around when reaching the end

- **App Switching Within Group** - Cycle through apps in the current group
  - Switch to Next App in Group
  - Switch to Previous App in Group

### About
- Version info and links
- Based on [FlashSpace](https://github.com/wojciech-kulik/FlashSpace)

## 💡 Features

### Primary App
Set a "Primary App" for each group - this app will be activated first when you trigger the group hotkey. If unset, FlashCut activates the most recently used app from that group.

### Launch on Activation
Enable "Open apps on activation" to automatically launch all apps in a group if they're not running.

### Smart Cycling
When you press "Next/Previous App" hotkeys, FlashCut automatically figures out which group you're in based on the currently active app, then cycles within that group. No need to "activate" a group first.

## 🔧 Configuration Files

FlashCut stores settings in `~/.config/flashcut/` as TOML files:
- `settings.toml` - Hotkeys and preferences
- `appgroups.toml` - Your app groups and their members

You can edit these files manually if you want, but the app will overwrite formatting when you make changes in the UI. Restart FlashCut after manual edits.

## ❓ FAQ

**Q: Why doesn't FlashCut appear in the Dock?**
A: FlashCut hides its Dock icon when no windows are open to stay out of your way. Press your "Toggle FlashCut Window" hotkey (set in Settings → General) to bring it back, or search for FlashCut in Spotlight.

**Q: Do I need to grant Accessibility permissions?**
A: No! FlashCut doesn't require Accessibility permissions. It uses standard macOS APIs for app switching.

**Q: Can I run FlashCut and FlashSpace together?**
A: Technically yes, but not recommended - they may conflict on global hotkeys and it would be confusing.

**Q: What's the difference between FlashCut and FlashSpace?**
A: See [FlashSpace Comparison](docs/FLASHSPACE_COMPARISON.md) for a detailed breakdown.

**Q: How do I uninstall?**
A: Drag FlashCut.app to the Trash and delete `~/.config/flashcut/`

## 📚 Documentation

- [FlashSpace Comparison](docs/FLASHSPACE_COMPARISON.md) - Detailed comparison with original
- [Development Guide](docs/DEVELOPMENT.md) - Architecture and contributing
- [Transformation Summary](docs/TRANSFORMATION_SUMMARY.md) - Technical details of the fork

## 📝 License

See [LICENSE](LICENSE) file.

## 🙏 Credits

FlashCut is a fork of [FlashSpace](https://github.com/wojciech-kulik/FlashSpace) by [Wojciech Kulik](https://github.com/wojciech-kulik).

Maintained by [Moritz Brödel](https://github.com/brodmo).
