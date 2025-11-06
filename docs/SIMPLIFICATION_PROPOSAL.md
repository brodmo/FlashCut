# FlashCut Architecture Simplification Proposal

**Context:** FlashCut is much simpler than FlashSpace, but still uses FlashSpace's enterprise-level architecture. This proposal outlines opportunities to simplify while maintaining code quality.

## Current Architecture Complexity

### Statistics
- **Total Swift files:** ~64
- **Settings infrastructure:** 287 lines across 7 files (for ~10 settings!)
- **Manager classes:** 3 separate managers (AppGroupManager, AppManager, AppGroupHotKeys)
- **Repository pattern:** Full CRUD repository for simple TOML files
- **DI Container:** Singleton dependency injection container

### Complexity Score (Current)

| Component | Lines | Complexity | Necessary? |
|-----------|-------|------------|------------|
| Settings (logic only) | 287 | ⚠️ HIGH | Could be 1/3 the size |
| AppGroupHotKeys | 77 | ⚠️ MEDIUM | Just wraps AppGroupManager |
| AppGroupRepository | 139 | ⚠️ MEDIUM | Wraps config serialization |
| AppDependencies | 58 | ⚠️ LOW | Simple app DI might be overkill |
| AppManager + AppGroupManager | 241 | ✅ OK | Could potentially merge |

## Proposed Simplifications

### 1. Consolidate Settings Infrastructure

**Current:** 7 files, 287 lines
- GeneralSettings.swift (48 lines)
- AppManagerSettings.swift (46 lines)
- AppGroupSettings.swift (54 lines)
- SettingsRepository.swift (73 lines)
- AppSettings.swift (33 lines)
- SettingsProtocol.swift (15 lines)
- Publisher.swift (18 lines)

**Proposal:** Merge into 1-2 files, ~100 lines total

```swift
// Single AppSettings.swift file

final class AppSettings: ObservableObject {
    // General
    @Published var showFlashCutHotkey: AppHotKey?
    @Published var checkForUpdatesAutomatically = false

    // App Manager
    @Published var switchToNextAppInGroup: AppHotKey?
    @Published var switchToPreviousAppInGroup: AppHotKey?

    // App Groups
    @Published var loopAppGroups = true
    @Published var switchToRecentAppGroup: AppHotKey?
    @Published var switchToPreviousAppGroup: AppHotKey?
    @Published var switchToNextAppGroup: AppHotKey?

    private var cancellables = Set<AnyCancellable>()

    init() {
        load()
        observeChanges()
    }

    private func observeChanges() {
        // Auto-save on any change
        Publishers.MergeMany(
            $showFlashCutHotkey,
            $switchToNextAppInGroup,
            // ... all publishers
        ).debounce(for: 0.5, scheduler: DispatchQueue.main)
         .sink { [weak self] in self?.save() }
         .store(in: &cancellables)
    }

    private func load() {
        guard let data = try? ConfigSerializer.deserialize(
            AppSettingsData.self,
            filename: "settings"
        ) else { return }

        // Map data to @Published properties
    }

    private func save() {
        let data = AppSettingsData(/* map from @Published */)
        try? ConfigSerializer.serialize(filename: "settings", data)
        AppDependencies.shared.hotKeysManager.refresh()
    }
}

// Separate Codable struct for persistence
struct AppSettingsData: Codable {
    // Same properties as above
}
```

**Benefits:**
- 287 lines → ~100 lines (65% reduction)
- Single source of truth
- No complex protocol/coordinator pattern
- Easier to understand and maintain
- Still properly structured

**Risks:** Low - Just consolidation, no logic changes

---

### 2. Merge AppGroupHotKeys into HotKeysManager

**Current:** Separate 77-line class that just wraps calls to AppGroupManager

**Proposal:** Move `getHotKeys()` logic directly into HotKeysManager

```swift
// HotKeysManager.swift
func enableAll() {
    allHotKeys.removeAll()

    // App Groups - inline the logic
    for appGroup in appGroupRepository.appGroups {
        if let shortcut = appGroup.activateShortcut?.toShortcut() {
            let action = ShortcutAction(shortcut: shortcut) { [weak self] _ in
                guard let self else { return false }
                if let updated = appGroupRepository.findAppGroup(with: appGroup.id) {
                    appGroupManager.activateAppGroup(updated, setFocus: true)
                }
                return true
            }
            hotKeysMonitor.addAction(action, forKeyEvent: .down)
        }
    }

    // Cycle hotkeys
    if let shortcut = appGroupSettings.switchToNextAppGroup?.toShortcut() {
        let action = ShortcutAction(shortcut: shortcut) { [weak self] _ in
            self?.appGroupManager.activateAppGroup(next: true, loop: appGroupSettings.loopAppGroups)
            return true
        }
        hotKeysMonitor.addAction(action, forKeyEvent: .down)
    }
    // ... similar for other cycle hotkeys

    // App Manager hotkeys (similar pattern)
    // General hotkeys (already inline)
}
```

**Benefits:**
- Removes unnecessary abstraction layer
- 77 lines of wrapper code eliminated
- Simpler dependency graph
- Easier to understand hotkey registration

**Risks:** Low - Just moving code, no logic changes

---

### 3. Simplify or Remove AppGroupRepository

**Current:** 139-line repository pattern wrapping config serialization

**Option A - Simplify:** Remove abstraction, use ConfigSerializer directly

```swift
final class AppGroupManager: ObservableObject {
    @Published private(set) var appGroups: [AppGroup] = []

    init() {
        loadAppGroups()
    }

    private func loadAppGroups() {
        if let config = try? ConfigSerializer.deserialize(
            AppGroupsConfig.self,
            filename: "appgroups"
        ) {
            appGroups = config.appGroups
        }
    }

    private func saveAppGroups() {
        let config = AppGroupsConfig(appGroups: appGroups)
        try? ConfigSerializer.serialize(filename: "appgroups", config)
    }

    func addAppGroup(_ appGroup: AppGroup) {
        appGroups.append(appGroup)
        saveAppGroups()
    }

    // ... other CRUD methods
}
```

**Option B - Keep it:** Repository pattern provides clean separation

**Recommendation:** Keep repository - it's actually reasonable for this use case. The other simplifications provide more value.

---

### 4. Consider Merging AppManager into AppGroupManager

**Current:** Two separate managers (241 lines total)
- AppGroupManager: Handles group activation (161 lines)
- AppManager: Handles app cycling within groups (80 lines)

**Analysis:**
- Both work with app groups
- AppManager already depends on AppGroupManager and AppGroupRepository
- Closely related functionality

**Proposal:** Merge into single AppGroupManager

```swift
final class AppGroupManager: ObservableObject {
    // Existing app group activation logic...

    // MARK: - App Cycling (from AppManager)

    var currentApp: NSRunningApplication? {
        NSWorkspace.shared.frontmostApplication
    }

    func nextAppInGroup() {
        guard let (index, apps) = getCurrentAppIndex() else { return }
        // ... existing logic from AppManager
    }

    func previousAppInGroup() {
        guard let (index, apps) = getCurrentAppIndex() else { return }
        // ... existing logic from AppManager
    }

    private func getCurrentAppIndex() -> (Int, [MacApp])? {
        // ... existing logic from AppManager
    }
}
```

**Benefits:**
- Single manager for all app/group operations
- Simpler mental model
- Fewer dependencies to wire up
- Still ~240 lines (reasonable for single class)

**Risks:** Low - Just consolidation

---

### 5. Simplify or Remove AppDependencies

**Current:** 58-line singleton DI container

**Proposal:** Keep it - it's actually quite clean and makes testing possible. For a desktop app with no real DI framework, this is reasonable.

**Recommendation:** No change needed.

---

## Simplified Architecture Summary

### Proposed Changes

| Change | Lines Saved | Risk | Value |
|--------|-------------|------|-------|
| 1. Consolidate Settings | ~187 lines | Low | High |
| 2. Merge AppGroupHotKeys | ~77 lines | Low | Medium |
| 3. Keep AppGroupRepository | 0 | - | - |
| 4. Merge AppManager | ~20 lines* | Low | Medium |
| 5. Keep AppDependencies | 0 | - | - |

**Total:** ~284 lines removed (overhead reduction)

*Removing class overhead, not actual logic

### Before vs After

**Before:**
```
Features/
  AppGroups/
    AppGroupManager.swift (161 lines)
    AppGroupRepository.swift (139 lines)
    AppGroupHotKeys.swift (77 lines)
  AppManager/
    AppManager.swift (80 lines)
  Settings/
    SettingsRepository.swift (73 lines)
    General/GeneralSettings.swift (48 lines)
    AppGroups/AppGroupSettings.swift (54 lines)
    AppGroups/AppManagerSettings.swift (46 lines)
    _Models/AppSettings.swift (33 lines)
    _Models/SettingsProtocol.swift (15 lines)
    _Extensions/Publisher.swift (18 lines)
```

**After:**
```
Features/
  AppGroups/
    AppGroupManager.swift (~260 lines - includes app cycling)
    AppGroupRepository.swift (139 lines - unchanged)
  Settings/
    AppSettings.swift (~100 lines - all settings logic)
```

**File reduction:** 11 files → 3 files

---

## Implementation Plan

### Phase 1: Settings Consolidation (Highest Value)
1. Create new consolidated AppSettings.swift
2. Update all views to use new settings class
3. Test thoroughly
4. Delete old settings files
5. Commit: "refactor: consolidate settings into single class"

**Estimated effort:** 2-3 hours
**Risk:** Low - mechanical refactoring

### Phase 2: Merge AppGroupHotKeys (Medium Value)
1. Move hotkey creation logic into HotKeysManager
2. Delete AppGroupHotKeys.swift
3. Update AppDependencies
4. Test hotkeys
5. Commit: "refactor: inline app group hotkey logic"

**Estimated effort:** 1 hour
**Risk:** Low - just moving code

### Phase 3: Merge AppManager (Nice to Have)
1. Move app cycling methods into AppGroupManager
2. Delete AppManager.swift
3. Update references
4. Test cycling
5. Commit: "refactor: merge app cycling into AppGroupManager"

**Estimated effort:** 1 hour
**Risk:** Low

---

## Recommendations

### Do These:
1. ✅ **Consolidate Settings** - Highest value, removes most complexity
2. ✅ **Merge AppGroupHotKeys** - Good simplification, minimal risk
3. ✅ **Merge AppManager** - Cleaner architecture

### Don't Do These:
1. ❌ **Remove AppGroupRepository** - Actually provides value
2. ❌ **Remove AppDependencies** - Makes testing possible, reasonable overhead

### Result:
- **~284 lines removed**
- **11 files → 3 files**
- **Much simpler architecture**
- **Same functionality**
- **Still maintainable and testable**

---

## Alternative: Keep Current Architecture

**Arguments for keeping it:**
- Already works well
- Follows good practices
- Easy to test
- Room for growth if needed

**Arguments against:**
- Over-engineered for simple app
- More files to navigate
- Higher cognitive load
- Legacy from FlashSpace

**Verdict:** Simplification recommended - FlashCut's scope is clear and limited, so simpler is better.

---

## Questions for User

1. Do you want to pursue these simplifications?
2. Should we do all 3 phases or just settings consolidation?
3. Any concerns about the proposed changes?
4. Want to keep the current architecture instead?
