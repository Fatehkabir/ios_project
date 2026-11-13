import SwiftUI

// The bottom tab bar. Each tab has its OWN NavigationStack, so going deep in one tab
// (Guides -> list -> detail) does not affect the other tabs.
struct MainTabView: View {
    @EnvironmentObject var auth: FirebaseAuthService
    @EnvironmentObject var firestore: FirestoreService

    // Which tab is selected (0 = Home ... 4 = Favorites).
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            NavigationStack {
                HomeView(selectedTab: $selectedTab)   // pass a Binding so Home can switch tabs
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            NavigationStack { CategoryView() }
                .tabItem { Label("Guides", systemImage: "book.fill") }
                .tag(1)

            NavigationStack { ContactListView() }
                .tabItem { Label("Contacts", systemImage: "person.2.fill") }
                .tag(2)

            NavigationStack { ChecklistView() }
                .tabItem { Label("Checklist", systemImage: "checklist") }
                .tag(3)

            NavigationStack { FavoritesView() }
                .tabItem { Label("Favorites", systemImage: "heart.fill") }
                .tag(4)
        }
        .tint(Theme.orange)
        // Start loading this user's Firestore data when the app appears...
        .onAppear {
            if let userId = auth.userId {
                firestore.startListening(userId: userId)
            }
        }
        // ...and stop (and clear it) when the user logs out.
        .onDisappear {
            firestore.stopListening()
        }
        // One alert for every Firestore error in the whole app.
        .alert("Something went wrong",
               isPresented: Binding(
                    get: { firestore.errorMessage != nil },
                    set: { isShowing in if !isShowing { firestore.errorMessage = nil } }
               )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(firestore.errorMessage ?? "")
        }
    }
}
