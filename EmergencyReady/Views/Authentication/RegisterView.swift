import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var auth: FirebaseAuthService

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var validationMessage: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {

                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.orange)
                    Text("Create your account")
                        .font(.title.bold())
                        .foregroundColor(Theme.navy)
                    Text("Your contacts, checklist and favorites are saved to your account.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                VStack(spacing: 16) {
                    ValidatedField(title: "Email",
                                   placeholder: "you@example.com",
                                   text: $email,
                                   keyboard: .emailAddress,
                                   capitalization: .never)

                    PasswordField(title: "Password",
                                  placeholder: "At least 6 characters",
                                  text: $password)

                    PasswordField(title: "Confirm Password",
                                  placeholder: "Type the password again",
                                  text: $confirmPassword)

                    if let message = validationMessage ?? auth.errorMessage {
                        ErrorBanner(message: message)
                    }

                    Button {
                        register()
                    } label: {
                        if auth.isWorking {
                            ProgressView().tint(.white)
                        } else {
                            Text("Register")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(auth.isWorking)
                }
                .padding(20)
                .cardStyle()
            }
            .padding(.horizontal, 20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut, value: validationMessage)
        .onAppear { auth.errorMessage = nil }
    }

    private func register() {
        let cleanEmail = email.trimmingCharacters(in: .whitespaces)
        validationMessage = nil

        if !Validation.isValidEmail(cleanEmail) {
            validationMessage = "Please enter a valid email address."
        } else if password.count < 6 {
            validationMessage = "Password must be at least 6 characters."
        } else if password != confirmPassword {
            validationMessage = "The two passwords do not match."
        } else {
            // On success Firebase logs the new user in automatically,
            // and RootView switches to the main app by itself.
            auth.register(email: cleanEmail, password: password)
        }
    }
}
