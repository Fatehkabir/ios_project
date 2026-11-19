import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var auth: FirebaseAuthService
    @EnvironmentObject var firestore: FirestoreService

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            // Tab 1: Home (Alerts, SOS, Tips, Categories)
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            // Tab 2: Guides (All categories, procedures & offline search)
            NavigationStack {
                CategoryView()
            }
            .tabItem { Label("Guides", systemImage: "book.fill") }
            .tag(1)

            // Tab 3: Contacts (Helpline 999/1090 & Personal Emergency Contacts)
            NavigationStack {
                ContactListView()
            }
            .tabItem { Label("Contacts", systemImage: "phone.circle.fill") }
            .tag(2)

            // Tab 4: Checklist (Preparedness Supplies offline in UserDefaults)
            NavigationStack {
                ChecklistView()
            }
            .tabItem { Label("Checklist", systemImage: "checklist") }
            .tag(3)
        }
        .tint(Theme.orange)
        .onAppear {
            if let userId = auth.userId {
                firestore.startListening(userId: userId)
            }
        }
        .onDisappear {
            firestore.stopListening()
        }
        .alert(
            "Notice",
            isPresented: Binding(
                get: { firestore.errorMessage != nil },
                set: { isShowing in if !isShowing { firestore.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(firestore.errorMessage ?? "")
        }
    }
}
