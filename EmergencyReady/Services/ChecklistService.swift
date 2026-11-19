import Foundation
import SwiftUI
import Combine

// Manages the Preparedness Checklist locally in UserDefaults so it is 100% functional offline.
class ChecklistService: ObservableObject {
    @Published var items: [ChecklistItem] = []

    private let storageKey = "EmergencyReady_Checklist_Items_V1"

    init() {
        loadItems()
    }

    func loadItems() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ChecklistItem].self, from: data) {
            self.items = decoded
        } else {
            // Seed default emergency survival kit items
            self.items = ChecklistItem.defaultItems
            saveItems()
        }
    }

    func toggleItem(_ item: ChecklistItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isCompleted.toggle()
            saveItems()
        }
    }

    func addItem(title: String) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let newItem = ChecklistItem(id: UUID().uuidString, title: clean, isCompleted: false, createdAt: Date())
        items.insert(newItem, at: 0)
        saveItems()
    }

    func deleteItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveItems()
    }

    func resetToDefaults() {
        items = ChecklistItem.defaultItems
        saveItems()
    }

    var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }

    var progressFraction: Double {
        items.isEmpty ? 0 : Double(completedCount) / Double(items.count)
    }

    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}
