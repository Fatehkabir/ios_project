import SwiftUI

// Decides which "world" to show:
//   splash  ->  (logged out) login / register   or   (logged in) the main tab bar
// This is how "prevent unauthorized users" works in the UI: the main app is only
// created when auth.currentUser is not nil.
struct RootView: View {
    @EnvironmentObject var auth: FirebaseAuthService
    @EnvironmentObject var data: EmergencyDataService

    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if auth.currentUser != nil {
                MainTabView()
                    .transition(.opacity)
            } else {
                AuthFlowView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .animation(.easeInOut(duration: 0.4), value: auth.currentUser?.uid)
        .onAppear {
            data.loadData()   // read EmergencyData.json once
            // Keep the splash visible briefly while Firebase restores any saved login.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                showSplash = false
            }
        }
    }
}

// Login screen with a way to push the Register screen.
struct AuthFlowView: View {
    var body: some View {
        NavigationStack {
            LoginView()
        }
    }
}
