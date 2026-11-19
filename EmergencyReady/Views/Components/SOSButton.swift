import SwiftUI

struct SOSButton: View {
    let number: String

    @State private var showingCallConfirm = false

    var body: some View {
        Button {
            triggerCall()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "phone.fill")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("EMERGENCY SOS")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        Spacer()
                        Text("DIAL \(number)")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                    }
                    Text("One-tap direct emergency phone call")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Theme.red, Color(hex: "#B91C1C") ?? Theme.red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(14)
            .shadow(color: Theme.red.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .accessibilityLabel("Emergency SOS Call \(number)")
    }

    private func triggerCall() {
        let cleanNumber = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(cleanNumber)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                print("Simulator or device cannot place phone calls: tel://\(cleanNumber)")
            }
        }
    }
}
