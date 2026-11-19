import Foundation

struct EmergencyContact: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var phone: String
    var relationship: String
    var createdAt: Double          // seconds since 1970, used for ordering

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
        self.createdAt = data["createdAt"] as? Double ?? Date().timeIntervalSince1970
    }

    var dictionary: [String: Any] {
        [
            "name": name,
            "phone": phone,
            "relationship": relationship,
            "createdAt": createdAt
        ]
    }
}
