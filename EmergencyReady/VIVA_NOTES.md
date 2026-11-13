# EmergencyReady – Viva Notes

## Where each lab topic is used
| Topic | File(s) | What to say |
|---|---|---|
| @State | `LoginView` (email, password), `ChecklistView` (newItemTitle), `SearchView` (query), `MainTabView` (selectedTab) | Data owned by one screen. Changing it makes SwiftUI redraw that screen. |
| @Binding | `FavoriteButton`, `ValidatedField`, `PasswordField`, `ContactFormView(isPresented:)`, `HomeView(selectedTab:)` | A child borrows a value owned by its parent. `$name` creates the Binding. Writing through it changes the parent's @State. |
| @EnvironmentObject | all screens | The 3 services are created once in `EmergencyReadyApp` and shared with every screen without passing them by hand. |
| NavigationStack / NavigationLink | `MainTabView` (one stack per tab), `HomeView`, `CategoryView`, `GuideListView` | NavigationLink pushes a screen on the stack, the back button pops it. |
| Arrays + ForEach | `CategoryView`, `GuideDetailView` (steps), `ChecklistView`, `SafetyTipsView` (loop inside a loop) | ForEach builds one view per array item. Items need an `id` (Identifiable). |
| JSON | `EmergencyData.json`, `EmergencyDataService.loadData()` | Bundle.main.url -> Data -> JSONDecoder().decode(EmergencyData.self). Property names must match JSON keys. |
| Firebase Auth | `FirebaseAuthService` | createUser / signIn / signOut. A state listener updates `currentUser`; `RootView` shows login or the app. |
| Firestore CRUD | `FirestoreService` | Create: setData. Read: addSnapshotListener. Update: updateData. Delete: delete(). |
| Animations | see list below | |
| Images | `IconBadge`, `GuideDetailView` | Image from Assets if the name exists, otherwise an SF Symbol. |
| onAppear | `RootView`, `CategoryView`, `MainTabView`, `SearchView` | Runs code when a screen appears. |

## Animations in the app
- `SplashView`: spring scale + fade (`withAnimation`)
- `CategoryView`: cards fade/slide in one after another (`.animation(... .delay(index))`)
- `FavoriteButton`: heart grows with a spring (`scaleEffect` + `.animation(value:)`)
- `ChecklistView`: check mark spring, progress bar easing, rows animate on add/delete
- `HomeView` / `SafetyTipsView`: random tip scale+fade transition

## Likely viva questions
1. **Why `Codable` and `Identifiable`?** Codable lets JSONDecoder fill the struct; Identifiable gives `id` so ForEach can tell items apart.
2. **@State vs @Binding?** @State owns the value; @Binding is a two-way reference to someone else's @State.
3. **Why a separate FirestoreService?** Keeps database code out of views; views just read `@Published` arrays.
4. **What is `@Published`?** When the value changes, every view observing the object redraws.
5. **How do you stop users reading other people's data?** Data is stored under `users/{uid}`, and the Firestore rules allow access only when `request.auth.uid == userId`.
6. **Why does the checklist update instantly?** `setItemCompleted` changes the local array first, and Firestore's snapshot listener confirms it.
7. **Why can't the call button be tested on the simulator?** The simulator has no phone hardware, so `tel://` cannot open.
8. **What happens if the JSON is broken?** `loadData()` catches the DecodingError and sets `errorMessage`; views show `ErrorStateView` instead of crashing.
9. **How do default checklist items appear only once?** A `checklistSeeded` flag on `users/{uid}`; defaults use fixed ids.

## Small changes a teacher might ask (and where)
| Request | Change |
|---|---|
| Change the main colour | `Theme.swift` > `orange` hex |
| Add a 7th category | Add a category + guide entries in `EmergencyData.json` (no Swift change) |
| Make category grid 3 columns | `CategoryView` > add a third `GridItem` |
| Add "Relationship" suggestion | `ContactFormView` > `relationshipSuggestions` array |
| Require 8-character passwords | `RegisterView.register()` (`password.count < 8`) and the message |
| Show completed items first | `ChecklistView`: sort `firestore.checklistItems` by `isCompleted` |
| Add a "Medical" tip | Add an entry to `tips` in `EmergencyData.json` |
| Change splash duration | `RootView` > `.now() + 1.4` |
| Change the heart animation | `FavoriteButton` > `.animation(...)` / `scaleEffect` |
| Search only by title | `EmergencyDataService.search` > remove the keywords/description conditions |
