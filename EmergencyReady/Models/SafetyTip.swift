import Foundation

// A short safety tip shown on the Home screen and in the Safety Tips screen.
struct SafetyTip: Codable, Identifiable {
    let id: String
    let categoryId: String   // lets us group / filter tips by category
    let text: String
    let iconName: String     // SF Symbol name
}
