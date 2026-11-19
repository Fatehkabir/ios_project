import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var auth: FirebaseAuthService
    @Environment(\.dismiss) private var dismiss

    @State private var username: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var showingChangePasswordSection = false
    @State private var statusMessage: String? = nil
    @State private var isError: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Avatar / Profile Photo
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack {
                                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(Circle())
                                } else if !auth.profileImageBase64.isEmpty,
                                          let data = Data(base64Encoded: auth.profileImageBase64),
                                          let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 90, height: 90)
                                        .foregroundColor(Theme.navyLight)
                                }

                                Circle()
                                    .stroke(Theme.orange, lineWidth: 2.5)
                                    .frame(width: 94, height: 94)
                            }

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                HStack(spacing: 4) {
                                    Image(systemName: "camera.fill")
                                    Text("Change Photo")
                                }
                                .font(.caption.bold())
                                .foregroundColor(Theme.orange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Theme.orange.opacity(0.12))
                                .cornerRadius(20)
                            }
                            .onChange(of: selectedPhotoItem) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        // Compress image to ensure lightweight storage
                                        if let uiImage = UIImage(data: data),
                                           let compressedData = uiImage.jpegData(compressionQuality: 0.5) {
                                            selectedImageData = compressedData
                                        }
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // Section 2: Account Details (Username, Email)
                Section("Personal Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email Address")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        Text(auth.userEmail)
                            .font(.subheadline)
                            .foregroundColor(Theme.navy)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Username")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        TextField("Your name or alias", text: $username)
                            .font(.subheadline)
                    }

                    Button {
                        saveProfile()
                    } label: {
                        if auth.isWorking {
                            ProgressView().tint(Theme.orange)
                        } else {
                            Text("Update Profile")
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.orange)
                        }
                    }
                    .disabled(auth.isWorking || username.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                // Section 3: Change Password
                Section("Security") {
                    Toggle("Change Password", isOn: $showingChangePasswordSection)

                    if showingChangePasswordSection {
                        SecureField("New Password (min 6 characters)", text: $newPassword)
                        SecureField("Confirm New Password", text: $confirmPassword)

                        Button {
                            updatePassword()
                        } label: {
                            if auth.isWorking {
                                ProgressView().tint(Theme.red)
                            } else {
                                Text("Save New Password")
                                    .fontWeight(.semibold)
                                    .foregroundColor(Theme.red)
                            }
                        }
                        .disabled(auth.isWorking || newPassword.count < 6 || newPassword != confirmPassword)
                    }
                }

                // Feedback message
                if let message = statusMessage ?? auth.errorMessage ?? auth.successMessage {
                    Section {
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(isError ? Theme.red : Theme.green)
                    }
                }
            }
            .navigationTitle("User Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .onAppear {
                username = auth.username
            }
        }
    }

    private func saveProfile() {
        let cleanName = username.trimmingCharacters(in: .whitespaces)
        var photoBase64: String? = nil
        if let data = selectedImageData {
            photoBase64 = data.base64EncodedString()
        }

        auth.updateProfile(newUsername: cleanName, photoBase64: photoBase64) { success in
            isError = !success
            statusMessage = success ? "Profile updated successfully!" : auth.errorMessage
        }
    }

    private func updatePassword() {
        if newPassword.count < 6 {
            isError = true
            statusMessage = "Password must be at least 6 characters."
            return
        }
        if newPassword != confirmPassword {
            isError = true
            statusMessage = "Passwords do not match."
            return
        }

        auth.changePassword(newPassword: newPassword) { success in
            isError = !success
            statusMessage = success ? "Password changed successfully!" : auth.errorMessage
            if success {
                newPassword = ""
                confirmPassword = ""
                showingChangePasswordSection = false
            }
        }
    }
}
