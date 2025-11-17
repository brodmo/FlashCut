# FlashCut Architecture Walkthrough

Let's trace through the actual flows to understand where complexity lives and identify simplification opportunities.

---

## The Components

### Core Data
- **AppGroup** - Model: name, apps[], targetApp, hotkey, openOnActivation
- **MacApp** - Model: name, bundleId, iconPath
- **AppHotKey** - Model: hotkey representation

### Managers (Business Logic)
- **AppGroupManager** - Activates app groups, tracks last/previous for cycling
- **AppManager** - Cycles through apps within current group
- **HotKeysManager** - Registers all hotkeys with system

### Data Access
- **AppGroupRepository** - Loads/saves app groups from TOML
- **SettingsRepository** - Loads/saves settings from TOML

### Coordinators
- **AppGroupHotKeys** - Creates hotkey tuples for app groups
- **3 Settings classes** - GeneralSettings, AppManagerSettings, AppGroupSettings

### Views
- **MainView/MainViewModel** - App groups list, CRUD operations
- **Settings views** - General, AppGroups, About

---

## Flow 1: User Presses App Group Hotkey

Let's trace: **User presses Cmd+1 to activate "Browsers" group**

```
1. User presses Cmd+1
   ↓
2. GlobalShortcutMonitor (ShortcutRecorder framework)
   - Captures system hotkey
   ↓
3. HotKeysManager.enableAll() had registered this hotkey
   - Calls action from AppGroupHotKeys.getActivateHotKey()
   ↓
4. AppGroupHotKeys.getActivateHotKey() action executes
   - Looks up fresh AppGroup from AppGroupRepository
   - Calls AppGroupManager.activateAppGroup(appGroup, setFocus: true)
   ↓
5. AppGroupManager.activateAppGroup()
   - Updates lastActivatedAppGroup (for cycling)
   - Opens apps if needed
   - Calls findApp() to determine which app to activate
   - Calls NSRunningApplication.activate()
   ↓
6. macOS brings app to front
```

**Analysis:**
- **AppGroupHotKeys** acts as a thin adapter between HotKeysManager and AppGroupManager
- It fetches fresh AppGroup and calls AppGroupManager
- This is an extra layer - HotKeysManager could call AppGroupManager directly

**Question:** Why does AppGroupHotKeys exist?

---

## Flow 2: User Cycles to Next App in Group

**User has Safari focused, presses hotkey to switch to Firefox (both in "Browsers" group)**

```
1. User presses cycle hotkey (e.g., Cmd+Tab equivalent)
   ↓
2. GlobalShortcutMonitor captures it
   ↓
3. HotKeysManager calls action from AppManager.getHotKeys()
   ↓
4. AppManager.cycleAppsInGroup()
   - Gets current app (Safari) via NSWorkspace.frontmostApplication
   - Finds app group containing Safari (stateless lookup)
   - Gets apps[] from that group
   - Finds next running app in the list
   - Calls NSRunningApplication.activate()
   ↓
5. macOS switches to Firefox
```

**Analysis:**
- AppManager is separate from AppGroupManager
- AppManager needs: current app, app groups list
- AppGroupManager already has: app groups, activation logic

**Question:** Why is AppManager separate when it's so closely related to app groups?

---

## Flow 3: User Changes a Setting

**User changes "Loop App Groups" toggle in settings**

```
1. User toggles switch in AppGroupsSettingsView
   ↓
2. SwiftUI binding updates AppGroupSettings.loopAppGroups
   ↓
3. AppGroupSettings @Published triggers publisher
   ↓
4. SettingsRepository observes all settings publishers
   - Calls AppGroupSettings.update() to copy to AppSettings struct
   - Serializes AppSettings to TOML via ConfigSerializer
   - Calls HotKeysManager.refresh() (hotkeys might have changed)
   ↓
5. HotKeysManager.refresh()
   - Calls disableAll()
   - Calls enableAll() to re-register all hotkeys
```

**Analysis:**
- 3 separate settings classes (GeneralSettings, AppManagerSettings, AppGroupSettings)
- Each has @Published properties
- SettingsRepository coordinates them all
- SettingsProtocol defines interface
- AppSettings is the Codable struct

**Flow for this ONE setting:**
```
SwiftUI → AppGroupSettings (@Published)
       → SettingsRepository (observes)
       → AppGroupSettings.update() (copies to struct)
       → ConfigSerializer.serialize() (saves TOML)
```

**Question:** Do we really need this many layers for ~10 settings?

---

## Flow 4: User Adds App to Group

**User drags Chrome into "Browsers" group**

```
1. User drops app in MainView
   ↓
2. MainViewModel.addApp() (or drag handler)
   ↓
3. FileChooser opens, user selects app
   ↓
4. MainViewModel creates MacApp from URL
   ↓
5. AppGroupRepository.addApp(to: groupId, app: macApp)
   - Modifies appGroups array
   - Calls saveAppGroups()
   - ConfigSerializer.serialize() saves to TOML
   - Sends notification via appGroupsSubject
   ↓
6. MainViewModel observes appGroupsSubject
   - Updates UI with new app list
```

**Analysis:**
- AppGroupRepository provides clean CRUD interface
- Repository pattern makes sense here - multiple callers need this
- ConfigSerializer is properly abstracted

**Verdict:** This flow is clean, no changes needed.

---

## Dependency Graph

Let me map who depends on whom:

```
HotKeysManager
├─ needs: GlobalShortcutMonitor (framework)
├─ needs: AppGroupHotKeys ← thin wrapper
│  ├─ needs: AppGroupManager
│  ├─ needs: AppGroupRepository
│  └─ needs: AppGroupSettings
├─ needs: AppManager ← separate manager
│  ├─ needs: AppGroupManager
│  ├─ needs: AppGroupRepository
│  └─ needs: AppManagerSettings
└─ needs: GeneralSettings

AppGroupManager
├─ needs: AppGroupRepository
└─ needs: AppGroupSettings (for loopAppGroups)

SettingsRepository
├─ contains: GeneralSettings
├─ contains: AppManagerSettings
├─ contains: AppGroupSettings
└─ needs: ConfigSerializer

AppGroupRepository
└─ needs: ConfigSerializer

MainViewModel
├─ needs: AppGroupManager
└─ needs: AppGroupRepository
```

---

## Simplification Analysis

### Finding 1: AppGroupHotKeys is a Thin Wrapper

**What it does:**
- Takes AppGroupManager, AppGroupRepository, AppGroupSettings
- Returns `[(AppHotKey, action)]` tuples
- Actions just call AppGroupManager methods

**Could be:**
```swift
// In HotKeysManager.enableAll()
for appGroup in appGroupRepository.appGroups {
    if let shortcut = appGroup.activateShortcut?.toShortcut() {
        let action = ShortcutAction(shortcut: shortcut) { _ in
            if let updated = appGroupRepository.findAppGroup(with: appGroup.id) {
                appGroupManager.activateAppGroup(updated, setFocus: true)
            }
            return true
        }
        hotKeysMonitor.addAction(action, forKeyEvent: .down)
    }
}
```

**Verdict:** AppGroupHotKeys could be removed, logic inlined into HotKeysManager.

---

### Finding 2: AppManager is Closely Related to AppGroupManager

**AppManager's entire purpose:**
- Cycle through apps in current app's group
- Uses AppGroupRepository to find the group
- Depends on AppGroupManager (though doesn't call it currently)

**Why separate?**
- Conceptually different? (groups vs apps within groups)
- Single responsibility?

**Could merge because:**
- Both work with app groups
- AppManager is only 80 lines
- AppGroupManager is 161 lines = 241 total (reasonable)
- They share dependencies
- User thinks of them as one feature

**Verdict:** Could merge, but there's a reasonable argument for keeping them separate.

---

### Finding 3: Settings Classes are Fragmented

**Current structure:**
```
GeneralSettings (48 lines)
  - showFlashCutHotkey
  - checkForUpdatesAutomatically

AppManagerSettings (46 lines)
  - (removed, settings consolidated)

AppGroupSettings (54 lines)
  - loopAppGroups
  - cycleAppsInGroup
  - lastAppGroup

SettingsRepository (73 lines)
  - Coordinates above 3
  - Observes all publishers
  - Saves to disk

SettingsProtocol (15 lines)
  - Common interface

AppSettings (33 lines)
  - Codable struct for TOML

Publisher extension (18 lines)
  - Helper for creating publishers
```

**Total: 287 lines for 8 settings values**

**Each setting class does:**
- Declares @Published properties
- Observes changes
- Implements SettingsProtocol (load/update)

**Could be:**
```swift
// Single Settings class
@MainActor
final class Settings: ObservableObject {
    // All settings as @Published
    @Published var showFlashCutHotkey: AppHotKey?
    @Published var checkForUpdates = false
    @Published var switchToNextAppInGroup: AppHotKey?
    // ... etc

    init() {
        load()
        observeChanges() // Auto-save on changes
    }

    private func load() { /* deserialize */ }
    private func save() { /* serialize */ }
    private func observeChanges() { /* watch all @Published */ }
}
```

**Why was it split?**
- Separation of concerns (General vs AppManager vs AppGroups)
- Different settings panels?

**But:**
- Settings panels could still access `Settings.shared.someProperty`
- All settings are saved to one TOML file anyway
- The split creates complexity without clear benefit

**Verdict:** Settings could definitely be consolidated.

---

## Simplification Opportunities (Ranked)

### 1. Settings Consolidation (High Value)
**Current:** 7 files, 287 lines
**Proposed:** 1-2 files, ~100 lines
**Savings:** ~187 lines, 6 fewer files
**Risk:** Low - mechanical refactoring
**Benefit:** Much simpler settings management

### 2. Remove AppGroupHotKeys (Medium Value)
**Current:** Separate 77-line class
**Proposed:** Inline into HotKeysManager
**Savings:** ~77 lines, 1 fewer file
**Risk:** Low - just moving code
**Benefit:** Fewer classes to understand

### 3. Merge AppManager (Low-Medium Value)
**Current:** Separate 80-line class
**Proposed:** Merge into AppGroupManager
**Savings:** ~20 lines overhead
**Risk:** Low
**Benefit:** Debatable - could argue both ways

---

## What Actually Adds Value?

Let's look at what's **truly necessary:**

### Necessary Complexity ✅
- **AppGroupRepository** - Multiple callers, clean CRUD, good abstraction
- **AppGroupManager** - Core business logic, stateful cycling, well-structured
- **ConfigSerializer** - TOML serialization, used everywhere
- **HotKeysManager** - Coordinates all hotkeys, necessary coordinator

### Questionable Complexity ⚠️
- **AppGroupHotKeys** - Just wraps AppGroupManager calls
- **Settings split** - 7 files for 8 values, complex observer pattern
- **AppManager separate** - Closely related to AppGroupManager

### Actually Good ✅
- **AppDependencies** - Clean DI, makes testing possible
- **Repository pattern** - Actually useful here
- **Manager separation** - Debatable but defensible

---

## My Honest Assessment

**Real simplifications worth doing:**

1. **Settings consolidation** - This is genuinely over-engineered. 287 lines for 8 values is excessive.

2. **AppGroupHotKeys removal** - It's just glue code with no real logic.

**Debatable:**

3. **AppManager merge** - I can see both sides:
   - **Pro keeping separate:** Clear boundaries, single responsibility
   - **Pro merging:** Closely related functionality, simpler overall

**Actually fine as-is:**

- AppGroupRepository - Good abstraction
- AppDependencies - Makes sense
- Manager classes - Reasonable

---

## The Real Question

What bothers you about the current architecture? Is it:

- **Too many files?** (Settings are the main culprit)
- **Too many layers?** (AppGroupHotKeys is unnecessary glue)
- **Hard to follow?** (Settings coordination is complex)
- **Something else?**

Tell me what feels off, and I can help identify if it's genuinely over-engineered or if it's actually serving a purpose.
