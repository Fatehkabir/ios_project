import Foundation

// One emergency category (Fire, Flood, ...). Loaded from EmergencyData.json.
// Codable   -> lets JSONDecoder turn JSON text into this struct.
// Identifiable -> gives every item an `id`, so ForEach / List can tell items apart.
struct EmergencyCategory: Codable, Identifiable {
    let id: String            // e.g. "fire"
    let title: String         // e.g. "Fire Emergency"
    let description: String   // short text shown on the card
    let iconName: String      // SF Symbol name, e.g. "flame.fill"
    let imageName: String     // optional image in Assets.xcassets (falls back to the icon)
    let colorHex: String      // accent colour of the card, e.g. "#E8501F"
}
