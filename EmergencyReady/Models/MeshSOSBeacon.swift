import Foundation

/// Represents a peer-to-peer SOS emergency beacon broadcast by a nearby device
struct MeshSOSBeacon: Identifiable, Codable, Equatable {
    let id: String
    let senderName: String
    let region: String
    let emergencyStatus: String // e.g. "Trapped / Need Help", "Medical Emergency", "Safe but Stranded", "Need Drinking Water"
    let note: String
    let timestamp: Date

    var timeAgoString: String {
        let seconds = Int(Date().timeIntervalSince(timestamp))
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            return "\(seconds / 60)m ago"
        } else {
            return "\(seconds / 3600)h ago"
        }
    }
}
