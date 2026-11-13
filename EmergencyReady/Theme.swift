import SwiftUI

// Central place for colours and shared styles so every screen looks the same.
// Change a colour here and the whole app updates.
enum Theme {
    static let navy = Color(hex: "#0B1F3A")          // main dark colour
    static let navyLight = Color(hex: "#1B3358")
    static let orange = Color(hex: "#F26B21")        // main accent
    static let red = Color(hex: "#D62828")           // used sparingly (warnings, delete)
    static let green = Color(hex: "#2E9E5B")         // "do" / completed
    static let background = Color(hex: "#F4F6FA")    // screen background
    static let card = Color.white
    static let textSecondary = Color(hex: "#5B6678")

    static let cornerRadius: CGFloat = 16
}

// Lets us write Color(hex: "#F26B21") instead of three decimal numbers.
extension Color {
    init(hex: String) {
        // Remove "#" and read the remaining text as a hexadecimal number.
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

// Big orange button used for the main action on a screen.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.orange)
            .cornerRadius(Theme.cornerRadius)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// A white rounded card with a soft shadow. Use: .cardStyle()
extension View {
    func cardStyle() -> some View {
        self
            .background(Theme.card)
            .cornerRadius(Theme.cornerRadius)
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}
