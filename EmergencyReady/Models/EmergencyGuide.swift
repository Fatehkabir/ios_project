import Foundation

// One safety guide inside a category (for example "Drop, Cover and Hold On").
struct EmergencyGuide: Codable, Identifiable {
    let id: String
    let categoryId: String        // links the guide to an EmergencyCategory.id
    let title: String
    let description: String
    let iconName: String          // SF Symbol fallback
    let imageName: String         // optional illustration in Assets.xcassets
    let steps: [String]           // numbered instructions
    let thingsToDo: [String]
    let thingsToAvoid: [String]
    let keywords: [String]        // extra words used by the search feature
    let sourceName: String        // where the information comes from
    let sourceURL: String         // link to the official page
}
