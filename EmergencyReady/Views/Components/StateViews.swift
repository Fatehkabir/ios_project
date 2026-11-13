import SwiftUI

// Shown while data is loading.
struct LoadingView: View {
    var text: String = "Loading..."

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(text)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// Shown when a list has nothing to display.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 46))
                .foregroundColor(Theme.orange)
            Text(title)
                .font(.headline)
                .foregroundColor(Theme.navy)
            Text(message)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.top, 6)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity)
    }
}

// Shown when something failed (for example the JSON file could not be read).
struct ErrorStateView: View {
    let message: String
    var retry: (() -> Void)? = nil

    var body: some View {
        EmptyStateView(icon: "exclamationmark.triangle.fill",
                       title: "Something went wrong",
                       message: message,
                       actionTitle: retry == nil ? nil : "Try Again",
                       action: retry)
    }
}

// Small red message box used on the login and register screens.
struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
            Text(message)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundColor(Theme.red)
        .padding(12)
        .background(Theme.red.opacity(0.1))
        .cornerRadius(12)
    }
}
