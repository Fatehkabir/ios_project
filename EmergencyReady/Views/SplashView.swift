import SwiftUI

// Optional splash screen shown for about a second when the app opens.
struct SplashView: View {
    @State private var isAnimated = false

    var body: some View {
        ZStack {
            Theme.navy.ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 72))
                    .foregroundColor(Theme.orange)
                    // Animation: grows from small to normal size.
                    .scaleEffect(isAnimated ? 1.0 : 0.5)

                Text("EmergencyReady")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Text("Personal Emergency & Safety Guide")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))
            }
            .opacity(isAnimated ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                isAnimated = true
            }
        }
    }
}
