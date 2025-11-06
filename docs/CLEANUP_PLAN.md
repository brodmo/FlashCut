# FlashCut Cleanup Plan

## Menu Bar Infrastructure Removal

**Total LOC to remove: ~200 lines**

Files to remove:
- `MenuBarTitle.swift` (38 lines)
- `MenuBarSettings.swift` (56 lines)
- `MenuBarSettingsView.swift` (60 lines)
- References in AppDependencies
- References in SettingsRepository
- References in AppSettings
- "Menu Bar" tab from SettingsView
- MenuBarTitle usage in FlashSpaceMenuBar.swift

**Impact:** Menu bar will always show static "FlashCut" text, no customization

---

## Settings to Remove (User Confirmed)

### 1. Display Settings
**Remove from WorkspaceSettings:**
- `alternativeDisplays: String`
- Related UI in WorkspacesSettingsView (Alternative Displays section)

**LOC:** ~30 lines

### 2. Hidden Apps Settings
**Remove from WorkspaceSettings:**
- `restoreHiddenAppsOnSwitch: Bool`
- Related UI in WorkspacesSettingsView toggle

**LOC:** ~10 lines

---

## Settings Needing Clarification

### WorkspaceSettings

**Potentially Keep (seem useful):**
1. **`displayMode: DisplayMode`** (.static vs .dynamic)
   - Static: Manually assign workspaces to displays
   - Dynamic: Workspaces follow running apps
   - **Question:** Still relevant for FlashCut?

2. **`centerCursorOnWorkspaceChange: Bool`**
   - Centers cursor in focused app when activating group
   - **Question:** Keep this feature?

3. **`changeWorkspaceOnAppAssign: Bool`**
   - Auto-switch to group when assigning an app
   - **Question:** Keep this behavior option?

4. **`activeWorkspaceOnFocusChange: Bool`**
   - Auto-activate group when focusing an app in that group
   - **Question:** Keep this automatic behavior?

5. **`skipEmptyWorkspacesOnSwitch: Bool`**
   - Skip groups with no running apps when cycling
   - **Question:** Useful for FlashCut?

6. **Cycling Settings:**
   - `loopWorkspaces: Bool` - Loop back to first when reaching last
   - `loopWorkspacesOnAllDisplays: Bool` - Cycle through all displays
   - `switchWorkspaceOnCursorScreen: Bool` - Start cycle from cursor screen
   - **Question:** All still relevant?

**Potentially Remove (less clear utility):**
1. **`keepUnassignedAppsOnSwitch: Bool`**
   - "Keep unassigned apps visible when switching"
   - We don't hide apps anymore, so this may be obsolete
   - **Question:** Remove this?

---

## Other Settings to Review

### FocusManagerSettings
**Current settings:**
- `enableFocusManagement: Bool` - Master toggle
- `centerCursorOnFocusChange: Bool` - Center cursor when using focus hotkeys
- Focus hotkeys (next/prev app/window)
- `focusFrontmostWindow: Bool` - Was for directional focus, now unused?

**Question:** Remove `focusFrontmostWindow`? (Was only for directional focus)

### GeneralSettings
**Current settings:**
- `checkForUpdatesAutomatically: Bool` - Keep
- `showFlashSpace: AppHotKey` - Toggle FlashCut UI - Keep
- `showFloatingNotifications: Bool` - Toast notifications - Keep

**All seem relevant, keep as-is**

---

## Summary of Questions

**Priority 1 (Do after compilation works):**
1. Remove menu bar infrastructure? (~200 LOC)
2. Remove alternativeDisplays setting? (confirmed yes)
3. Remove restoreHiddenAppsOnSwitch setting? (confirmed yes)
4. Remove keepUnassignedAppsOnSwitch? (likely obsolete)
5. Remove focusFrontmostWindow? (was only for directional focus)

**Priority 2 (Clarify now if possible):**
1. Keep displayMode (static vs dynamic)?
2. Keep centerCursorOnWorkspaceChange?
3. Keep changeWorkspaceOnAppAssign?
4. Keep activeWorkspaceOnFocusChange?
5. Keep skipEmptyWorkspacesOnSwitch?
6. Keep all the cycling options (loop, all displays, cursor screen)?

---

## Recommendation

**Remove immediately (after compilation):**
- Menu bar infrastructure (~200 LOC)
- `alternativeDisplays` setting
- `restoreHiddenAppsOnSwitch` setting
- `keepUnassignedAppsOnSwitch` setting (obsolete without hiding)
- `focusFrontmostWindow` setting (obsolete without directional focus)

**Total cleanup: ~250 lines**

**Keep (seem useful for FlashCut):**
- Display mode (static vs dynamic assignment)
- All cursor centering options (useful for keyboard-first workflow)
- Auto-activation behaviors (changeWorkspaceOnAppAssign, activeWorkspaceOnFocusChange)
- All cycling options (loop, skip empty, cursor screen, all displays)

These seem aligned with FlashCut's focus on keyboard shortcuts and streamlined app switching.
