# EmergencyReady – Setup Steps (what YOU do in Xcode)

Written code is NOT compiled or tested yet (no Mac/Xcode in the workspace where it was written).
Your first build is the first real test. If Xcode shows errors, send me the exact text.

## 1. Project settings (you did most of this in Phase 1)
- Xcode project named `EmergencyReady`, Interface = SwiftUI, Language = Swift.
- Target > General > **Minimum Deployments: iOS 16.0** (the code uses NavigationStack, iOS 16+).
- Swift packages added from `https://github.com/firebase/firebase-ios-sdk`:
  **FirebaseAuth** and **FirebaseFirestore** only.
- `GoogleService-Info.plist` is in the project and ticked for the EmergencyReady target.

## 2. Add the source files
1. In Xcode's left panel **delete `ContentView.swift`** (Move to Trash). Nothing uses it any more.
2. **Delete the default `EmergencyReadyApp.swift`** too (Move to Trash).
3. Drag these from the downloaded `EmergencyReady` folder into the Xcode project navigator,
   next to where `GoogleService-Info.plist` is:
   - `EmergencyReadyApp.swift`
   - `Theme.swift`
   - folders `Models`, `Services`, `Views`
   - `Resources/EmergencyData.json`
4. In the dialog tick **Copy items if needed**, choose **Create groups**, and tick the
   **EmergencyReady target**. (Do NOT drag `Firebase/firestore.rules` or the .md files in.)
5. Check the JSON is bundled: Target > **Build Phases > Copy Bundle Resources** must list
   `EmergencyData.json`. If not, click **+** and add it.

NOTE: `EmergencyReadyApp.swift` now calls `FirebaseApp.configure()` inside `init()`.
It replaces the AppDelegate version from Phase 1, so do not keep both.

## 3. Firebase Console
1. **Authentication > Sign-in method > Email/Password > Enable.**
2. **Firestore Database > Create database** (any region).
3. **Firestore Database > Rules**: delete everything, paste the full contents of
   `Firebase/firestore.rules`, click **Publish**.
   (Without this step Firestore blocks every read/write and the app shows "Permission denied".)

## 4. Run
Press **Cmd+R** with an iPhone simulator (iOS 16 or newer) selected.

## 5. Test checklist (tick each one)
- [ ] App opens: splash, then Login screen.
- [ ] Register with a new email + 6-character password. You land on Home.
- [ ] Home shows a tip, categories scroll sideways, "Show a random tip" changes the tip.
- [ ] Search: type "burn" -> "Minor Burns"; type "zzz" -> "No results found".
- [ ] Guides tab: 6 categories -> open one -> open a guide -> numbered steps, Do/Avoid, source link.
- [ ] Tap the heart on a guide (it bounces). Favorites tab shows it. Swipe left to remove.
- [ ] Contacts: add a contact (try empty name / "abc" phone to see validation), edit by tapping it,
      delete by swiping left. The green call button shows a "cannot place call" message on the simulator;
      it works on a real iPhone.
- [ ] Checklist: 8 default items, tap to tick/untick, counts and progress bar change, add a custom
      item, swipe to delete.
- [ ] Log out (Home > person icon > Log Out), log in again: contacts, checklist and favorites are still there.
- [ ] Firebase Console > Firestore: you should see `users/<your uid>/contacts`, `favorites`, `checklistItems`.
- [ ] Turn on Airplane mode: the app still opens (data is cached) and shows the error alert only when a write cannot reach the server.

## Optional: your own images
The app shows SF Symbol icons by default. To use pictures, add images to `Assets.xcassets` with
the names written in `EmergencyData.json` (`category-fire`, `guide-fire-escape`, ...).
The app picks them up automatically, no code change needed.
Only use images you made or that are licensed for reuse.

## Common problems
| Symptom | Fix |
|---|---|
| Crash on launch, "could not find GoogleService-Info.plist" / "No Firebase App" | Plist missing from the target (Section 1) |
| "EmergencyData.json was not found" on Home | Not in Copy Bundle Resources (Section 2.5) |
| Alert: "Permission denied" | Rules not published (Section 3.3) or not logged in |
| Register says email/password sign-in disabled | Enable Email/Password (Section 3.1) |
| `Cannot find 'FirebaseApp' / 'Firestore' in scope` | Package products not added to the target (Section 1) |
| Blank icon somewhere | SF Symbol not available on that iOS version; use iOS 16+ |
