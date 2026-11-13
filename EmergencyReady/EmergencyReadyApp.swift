import SwiftUI
import FirebaseCore

// The entry point of the app.
// IMPORTANT: this replaces the AppDelegate version from Phase 1. Calling
// FirebaseApp.configure() inside init() is simpler and guarantees Firebase is ready
// BEFORE any of our services (which use Firebase) are created.
@main
struct EmergencyReadyApp: App {

    // @StateObject = SwiftUI creates each object once and keeps it alive for the whole app.
    @StateObject private var authService: FirebaseAuthService
    @StateObject private var dataService: EmergencyDataService
    @StateObject private var firestoreService: FirestoreService

    init() {
        FirebaseApp.configure()   // reads GoogleService-Info.plist
        _authService = StateObject(wrappedValue: FirebaseAuthService())
        _dataService = StateObject(wrappedValue: EmergencyDataService())
        _firestoreService = StateObject(wrappedValue: FirestoreService())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                // Every screen below RootView can read these with @EnvironmentObject.
                .environmentObject(authService)
                .environmentObject(dataService)
                .environmentObject(firestoreService)
        }
    }
}
