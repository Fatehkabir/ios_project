import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var auth: FirebaseAuthService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedRegion = "Dhaka"
    @State private var selectedEmergencyNumber = "999"
    @State private var validationMessage: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                VStack(spacing: 8) {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.orange)
                    Text("Create Account")
                        .font(.title2.bold())
                        .foregroundColor(Theme.navy)
                    Text("Select your region to receive local disaster alerts")
                        .font(.footnote)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                VStack(spacing: 16) {
                    ValidatedField(
                        title: "Email Address",
                        placeholder: "user@example.com",
                        text: $email,
                        keyboard: .emailAddress,
                        capitalization: .never
                    )

                    PasswordField(
                        title: "Password (min 6 characters)",
                        placeholder: "Choose a secure password",
                        text: $password
                    )

                    PasswordField(
                        title: "Confirm Password",
                        placeholder: "Repeat your password",
                        text: $confirmPassword
                    )

                    // Region Selector
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Region (for Local Alerts)")
                            .font(.caption.bold())
                            .foregroundColor(Theme.navy)

                        Picker("Select Region", selection: $selectedRegion) {
                            ForEach(AppRegions.list, id: \.self) { region in
                                Text(region).tag(region)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Theme.background)
                        .cornerRadius(8)
                    }

                    // Emergency Number Selector
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Default Emergency Call Number")
                            .font(.caption.bold())
                            .foregroundColor(Theme.navy)

                        Picker("Emergency Helpline", selection: $selectedEmergencyNumber) {
                            Text("999 (National Emergency)").tag("999")
                            Text("1090 (Disaster Advisory)").tag("1090")
                            Text("16163 (Fire Service)").tag("16163")
                            Text("112 (Standard Emergency)").tag("112")
                            Text("911 (Emergency)").tag("911")
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Theme.background)
                        .cornerRadius(8)
                    }

                    if let message = validationMessage ?? auth.errorMessage {
                        ErrorBanner(message: message)
                    }

                    Button {
                        register()
                    } label: {
                        if auth.isWorking {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(auth.isWorking)
                }
                .padding(20)
                .cardStyle()

                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(Theme.textSecondary)
                        Text("Log In")
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.orange)
                    }
                    .font(.subheadline)
                }
            }
            .padding(.horizontal, 20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
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
            validationMessage = "Passwords do not match."
        } else {
            auth.register(
                email: cleanEmail,
                password: password,
                region: selectedRegion,
                emergencyNumber: selectedEmergencyNumber
            )
        }
    }
}
