import Foundation

// One item of the emergency supplies checklist. Stored in Firestore at:
// users/{uid}/checklistItems/{itemId}
struct ChecklistItem: Identifiable, Equatable {
    var id: String
    var title: String
    var isCompleted: Bool
    var createdAt: Double          // used to keep the list in a stable order

    init(id: String = UUID().uuidString,
         title: String,
         isCompleted: Bool = false,
         createdAt: Double = Date().timeIntervalSince1970) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }

    init?(id: String, data: [String: Any]) {
        guard let title = data["title"] as? String else { return nil }
        self.id = id
        self.title = title
        self.isCompleted = data["isCompleted"] as? Bool ?? false
        self.createdAt = data["createdAt"] as? Double ?? 0
    }

    var dictionary: [String: Any] {
        [
            "title": title,
            "isCompleted": isCompleted,
            "createdAt": createdAt
        ]
    }

    // The default items every new user receives the first time they log in.
    // Fixed ids mean the defaults can never be duplicated.
    static let defaultItems: [ChecklistItem] = [
        ChecklistItem(id: "default-first-aid-kit", title: "First Aid Kit", createdAt: 1),
        ChecklistItem(id: "default-drinking-water", title: "Drinking Water", createdAt: 2),
        ChecklistItem(id: "default-flashlight", title: "Flashlight", createdAt: 3),
        ChecklistItem(id: "default-batteries", title: "Batteries", createdAt: 4),
        ChecklistItem(id: "default-emergency-food", title: "Emergency Food", createdAt: 5),
        ChecklistItem(id: "default-documents", title: "Important Documents", createdAt: 6),
        ChecklistItem(id: "default-power-bank", title: "Power Bank", createdAt: 7),
        ChecklistItem(id: "default-medicines", title: "Essential Medicines", createdAt: 8)
    ]
}
