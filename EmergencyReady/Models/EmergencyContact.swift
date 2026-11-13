import Foundation

// A personal emergency contact. Stored in Firestore at:
// users/{uid}/contacts/{contactId}
// This model does NOT import Firebase: we convert to / from a plain
// dictionary so the model stays simple.
struct EmergencyContact: Identifiable, Equatable {
    var id: String
    var name: String
    var phone: String
    var relationship: String
    var createdAt: Double          // seconds since 1970, used for ordering

    // Used when creating a brand-new contact.
    init(id: String = UUID().uuidString,
         name: String,
         phone: String,
         relationship: String,
         createdAt: Double = Date().timeIntervalSince1970) {
        self.id = id
        self.name = name
        self.phone = phone
        self.relationship = relationship
        self.createdAt = createdAt
    }

    // Used when reading a Firestore document (returns nil if a field is missing).
    init?(id: String, data: [String: Any]) {
        guard let name = data["name"] as? String,
              let phone = data["phone"] as? String,
              let relationship = data["relationship"] as? String else {
            return nil
        }
        self.id = id
        self.name = name
        self.phone = phone
        self.relationship = relationship
        self.createdAt = data["createdAt"] as? Double ?? 0
    }

    // The dictionary that is written to Firestore.
    var dictionary: [String: Any] {
        [
            "name": name,
            "phone": phone,
            "relationship": relationship,
            "createdAt": createdAt
        ]
    }
}
