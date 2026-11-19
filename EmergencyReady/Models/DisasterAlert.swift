import Foundation

struct DisasterAlert: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var description: String
    var region: String
    var categoryId: String
    var severity: String       // "Minor", "Moderate", "Severe", "Extreme"
    var isActive: Bool
    var createdAt: Date
    var expiresAt: Date
    var createdBy: String

    var isExpired: Bool {
        Date() > expiresAt
    }
}

// Preset Regions
enum AppRegions {
    static let list = [
        "Dhaka",
        "Chattogram",
        "Sylhet",
        "Rajshahi",
        "Khulna",
        "Barishal",
        "Rangpur",
        "Mymensingh",
        "Cox's Bazar"
    ]
}

// National Emergency Contacts
struct NationalEmergencyService: Identifiable {
    let id = UUID()
    let name: String
    let number: String
    let description: String
    let iconName: String
}

enum EmergencyNumbers {
    static let nationalList: [NationalEmergencyService] = [
        NationalEmergencyService(name: "National Emergency Helpline", number: "999", description: "Police, Fire, Ambulance", iconName: "phone.fill"),
        NationalEmergencyService(name: "Disaster Early Warning", number: "1090", description: "Flood, Cyclone & Disaster Advisory", iconName: "exclamationmark.triangle.fill"),
        NationalEmergencyService(name: "Fire Service & Rescue", number: "16163", description: "Fire emergencies & rescue service", iconName: "flame.fill"),
        NationalEmergencyService(name: "Government Information Helpline", number: "333", description: "Govt info, relief and disaster support", iconName: "info.circle.fill")
    ]
}
