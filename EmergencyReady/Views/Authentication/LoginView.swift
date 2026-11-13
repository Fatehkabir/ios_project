import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: FirebaseAuthService

    // @State = data owned by THIS screen. When one changes, the screen redraws.
    @State private var email = ""
    @State private var password = ""
    @State private var validationMessage: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {

                // Logo and title
                VStack(spacing: 10) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 54))
                        .foregroundColor(Theme.orange)
                    Text("EmergencyReady")
                        .font(.largeTitle.bold())
                        .foregroundColor(Theme.navy)
                    Text("Log in to your safety guide")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.top, 50)

                // Form card. $email / $password pass a Binding to the fields.
                VStack(spacing: 16) {
                    ValidatedField(title: "Email",
                                   placeholder: "you@example.com",
                                   text: $email,
                                   keyboard: .emailAddress,
                                   capitalization: .never)

                    PasswordField(title: "Password",
                                  placeholder: "Your password",
                                  text: $password)

                    // Shows our own validation message first, otherwise Firebase's error.
                    if let message = validationMessage ?? auth.errorMessage {
                        ErrorBanner(message: message)
                    }

                    Button {
                        login()
                    } label: {
                        if auth.isWorking {
                            ProgressView().tint(.white)
                        } else {
                            Text("Log In")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(auth.isWorking)
                }
                .padding(20)
                .cardStyle()

                // NavigationLink: tapping pushes RegisterView onto the NavigationStack.
                NavigationLink {
                    RegisterView()
                } label: {
                    HStack(spacing: 4) {
                        Text("New here?")
                            .foregroundColor(Theme.textSecondary)
                        Text("Create an account")
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.orange)
                    }
                    .font(.subheadline)
                }
            }
            .padding(.horizontal, 20)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeInOut, value: validationMessage)
        .onAppear { auth.errorMessage = nil }
    }

    // Check the input first, only then call Firebase.
    private func login() {
        let cleanEmail = email.trimmingCharacters(in: .whitespaces)
        validationMessage = nil

        if !Validation.isValidEmail(cleanEmail) {
            validationMessage = "Please enter a valid email address."
        } else if password.isEmpty {
            validationMessage = "Please enter your password."
        } else {
            auth.login(email: cleanEmail, password: password)
        }
    }
}
