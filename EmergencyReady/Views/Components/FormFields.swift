import SwiftUI

// Reusable text field with a title and an optional error message.
// `text` is a @Binding: the typed text is stored in the PARENT screen's @State.
struct ValidatedField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var errorMessage: String? = nil
    var keyboard: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.navy)

            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled()
                .padding(12)
                .background(Theme.background)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(errorMessage == nil ? Color.gray.opacity(0.25) : Theme.red, lineWidth: 1)
                )

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(Theme.red)
            }
        }
    }
}

// Password field with a show/hide eye button.
struct PasswordField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var errorMessage: String? = nil

    // This @State belongs to the field itself (nobody else needs to know it).
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.navy)

            HStack {
                Group {
                    if isVisible {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .foregroundColor(Theme.textSecondary)
                }
                .accessibilityLabel(isVisible ? "Hide password" : "Show password")
            }
            .padding(12)
            .background(Theme.background)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(errorMessage == nil ? Color.gray.opacity(0.25) : Theme.red, lineWidth: 1)
            )

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(Theme.red)
            }
        }
    }
}
