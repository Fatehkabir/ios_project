import Foundation

struct ChecklistItem: Codable, Identifiable, Equatable {
    let id: String
    var title: String
    var isCompleted: Bool
    var createdAt: Date

    static let defaultItems: [ChecklistItem] = [
        ChecklistItem(id: "1", title: "Clean drinking water (3-day supply per person)", isCompleted: false, createdAt: Date()),
        ChecklistItem(id: "2", title: "Non-perishable food (biscuits, flattened rice, canned items)", isCompleted: false, createdAt: Date()),
        ChecklistItem(id: "3", title: "Battery-powered flashlight & spare batteries", isCompleted: false, createdAt: Date()),
        ChecklistItem(id: "4", title: "Portable power bank (fully charged)", isCompleted: false, createdAt: Date()),
        ChecklistItem(id: "5", title: "First aid kit with antiseptics & bandaging", isCompleted: false, createdAt: Date()),
        ChecklistItem(id: "6", title: "Personal prescription medications (7-day supply)", isCompleted: false, createdAt: Date()),
        ChecklistItem(id: "7", title: "Waterproof pouch for NID, passport & property deeds", isCompleted: false, createdAt: Date()),
        ChecklistItem(id: "8", title: "Whistle to signal rescue teams", isCompleted: false, createdAt: Date()),
        ChecklistItem(id: "9", title: "Matches or lighter sealed in plastic", isCompleted: false, createdAt: Date()),
        ChecklistItem(id: "10", title: "Cash in small notes (ATMs will not work in blackouts)", isCompleted: false, createdAt: Date())
    ]
}
