import Foundation
import SwiftUI

// Loads EmergencyData.json from the app bundle and keeps the parsed arrays.
// ObservableObject + @Published -> any SwiftUI view using this object refreshes
// automatically when these values change.
class EmergencyDataService: ObservableObject {
    @Published var categories: [EmergencyCategory] = []
    @Published var guides: [EmergencyGuide] = []
    @Published var tips: [SafetyTip] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    // Reads and decodes the JSON file. Called once from onAppear.
    func loadData() {
        // Don't load twice.
        if !categories.isEmpty { return }
        isLoading = true
        errorMessage = nil

        // 1. Find the file inside the app bundle.
        guard let url = Bundle.main.url(forResource: "EmergencyData", withExtension: "json") else {
            errorMessage = "EmergencyData.json was not found in the app. Check that the file is added to the target."
            isLoading = false
            return
        }

        // 2. Read the bytes and decode them with JSONDecoder.
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(EmergencyData.self, from: data)
            categories = decoded.categories
            guides = decoded.guides
            tips = decoded.tips
        } catch let DecodingError.keyNotFound(key, context) {
            errorMessage = "JSON error: missing key '\(key.stringValue)' (\(context.codingPath.map { $0.stringValue }.joined(separator: ".")))"
        } catch let DecodingError.typeMismatch(_, context) {
            errorMessage = "JSON error: wrong type at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        } catch {
            errorMessage = "Could not read emergency data: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Helper lookups used by several screens

    func category(withId id: String) -> EmergencyCategory? {
        categories.first { $0.id == id }
    }

    func guide(withId id: String) -> EmergencyGuide? {
        guides.first { $0.id == id }
    }

    // Accent colour of a category (used by guide and tip cards).
    func color(forCategory categoryId: String) -> Color {
        if let category = category(withId: categoryId) {
            return Color(hex: category.colorHex)
        }
        return Theme.orange
    }

    func guides(inCategory categoryId: String) -> [EmergencyGuide] {
        guides.filter { $0.categoryId == categoryId }
    }

    func tips(inCategory categoryId: String) -> [SafetyTip] {
        tips.filter { $0.categoryId == categoryId }
    }

    // Search categories, guide titles, descriptions and keywords.
    // Returns matching categories and matching guides.
    func search(_ text: String) -> (categories: [EmergencyCategory], guides: [EmergencyGuide]) {
        let query = text.trimmingCharacters(in: .whitespaces).lowercased()
        if query.isEmpty { return ([], []) }

        let matchedCategories = categories.filter {
            $0.title.lowercased().contains(query) || $0.description.lowercased().contains(query)
        }
        let matchedGuides = guides.filter { guide in
            guide.title.lowercased().contains(query)
            || guide.description.lowercased().contains(query)
            || guide.keywords.contains { $0.lowercased().contains(query) }
        }
        return (matchedCategories, matchedGuides)
    }
}
