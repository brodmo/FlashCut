# FlashCut vs FlashSpace: What's Different?

FlashCut is a streamlined fork of [FlashSpace](https://github.com/wojciech-kulik/FlashSpace) that focuses exclusively on keyboard shortcuts and app switching. If you're familiar with FlashSpace, here's what changed.

## 🎯 Core Philosophy Change

**FlashSpace**: Full-featured workspace manager with window management, app hiding, multi-display support
**FlashCut**: Minimal keyboard-focused app switcher

## ❌ Features Removed

### Major Features
- **Window Management** - No window positioning, resizing, or Picture-in-Picture
- **App Hiding** - Apps stay visible; groups just help you switch between them
- **Multi-Display Support** - No display-specific workspace assignments
- **Accessibility API** - No longer required or used
- **Directional Navigation** - No up/down/left/right window focus
- **Menu Bar Extra** - Removed the menu bar icon
- **Profiles** - No workspace profiles or profile switching

### Removed Settings
- Window management options (PiP, snap to grid, etc.)
- Display-specific settings
- Auto-activation behaviors
- Profile management
- Acknowledgements section

## ✅ What Stayed

### Core Features
- ✓ **App Groups** - Organize apps into keyboard-accessible groups
- ✓ **Group Hotkeys** - Assign shortcuts to activate groups
- ✓ **App Cycling** - Switch between apps within a group
- ✓ **Group Cycling** - Move between groups
- ✓ **Launch on Activation** - Optionally launch apps when activating a group
- ✓ **Primary App** - Set which app to activate first in a group

### Technical
- ✓ **TOML Configuration** - Config files work the same way
- ✓ **Auto-updates** via Sparkle
- ✓ **Native SwiftUI** interface
- ✓ **Stateless Design** - No tracking of "active workspace"

## 📝 Terminology Changes

| FlashSpace | FlashCut |
|------------|----------|
| Workspace | App Group |
| Focus Manager | App Manager |
| Focus Next App | Switch to Next App in Group |
| Assigned to workspace | Added to group |

## 🎨 UI Simplifications

**Settings Structure (Before)**:
- General
- Menu Bar
- Focus Manager
- Workspaces
- Configuration File
- Acknowledgements
- About

**Settings Structure (Now)**:
- General (includes config file location)
- App Groups (includes all hotkeys)
- About

## 🔧 Configuration Changes

### Config File Location
Same: `~/.config/flashcut/`

### Format
- ✅ TOML (same as before)
- ❌ JSON/YAML (removed)

### Breaking Changes
- Config directory changed from `flashspace/` to `flashcut/`
- Some field names changed (but TOML decoder handles old format)
- Removed fields: window management, display assignments, profiles

## 💡 Use Cases

### FlashSpace is Better For:
- Complex multi-monitor setups
- Window positioning and management
- Picture-in-Picture workflows
- Advanced workspace automation

### FlashCut is Better For:
- Simple keyboard-focused workflows
- Minimal system footprint
- Quick app switching
- Learning curve (fewer features = simpler)

## 🚀 Migration Guide

### If Migrating from FlashSpace:

1. **Export your workspace structure**
   - FlashSpace workspaces → FlashCut app groups (same concept)
   - Apps assigned to workspaces carry over

2. **Reconfigure hotkeys**
   - Group activation hotkeys work the same
   - App cycling hotkeys moved to "App Groups" settings

3. **Understand behavioral changes**
   - Activating a group no longer hides other apps
   - No automatic window positioning
   - First launch shows dock icon (no longer background-only)

4. **Clean up config**
   - Remove window management settings (will be ignored)
   - Remove display-specific assignments
   - Remove profile configurations

### Can I Run Both?

Technically yes, but not recommended:
- Both use global hotkeys (conflicts possible)
- Both manage app groups (could be confusing)
- Better to pick one based on your needs

## 📊 Code Stats

| Metric | FlashSpace | FlashCut | Change |
|--------|------------|----------|--------|
| Lines of Code | ~10,600 | ~2,500 | -76% |
| Features | 15+ | 5 core | -67% |
| Settings Panels | 7 | 3 | -57% |
| Dependencies | Same | Same | No change |

## 🤔 Should You Switch?

### Stick with FlashSpace if you:
- Use window management features
- Have multi-monitor setups with display-specific workspaces
- Rely on app hiding
- Use Picture-in-Picture mode

### Try FlashCut if you:
- Only use keyboard shortcuts and app switching
- Want a simpler, more focused tool
- Don't need window management
- Prefer minimal features over comprehensive ones

## 📚 Learn More

- [FlashCut README](../README.md) - Full FlashCut documentation
- [FlashSpace Original](https://github.com/wojciech-kulik/FlashSpace) - Original project
- [Architecture](./TRANSFORMATION_SUMMARY.md) - Technical details of the fork

---

**TL;DR**: FlashCut removed all window management, multi-display, and app hiding features from FlashSpace. It's now just keyboard shortcuts for switching between app groups. If that's all you need, FlashCut is simpler. If you use the advanced features, stick with FlashSpace.
