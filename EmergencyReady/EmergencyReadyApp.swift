import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct EmergencyReadyApp: App {

    init() {
        FirebaseApp.configure()

        // Enable local offline disk persistence for Firestore
        let settings = Firestore.firestore().settings
        settings.cacheSettings = PersistentCacheSettings()
        Firestore.firestore().settings = settings
    }

    // Single source of truth services injected into the SwiftUI hierarchy
    @StateObject private var authService = FirebaseAuthService()
    @StateObject private var dataService = EmergencyDataService()
    @StateObject private var firestoreService = FirestoreService()
    @StateObject private var disasterService = DisasterAlertService()
    @StateObject private var checklistService = ChecklistService()
    @StateObject private var meshService = MeshSOSService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(dataService)
                .environmentObject(firestoreService)
                .environmentObject(disasterService)
                .environmentObject(checklistService)
                .environmentObject(meshService)
        }
    }
}
