import Foundation

// The "root" of EmergencyData.json. The JSON file looks like:
// { "categories": [...], "guides": [...], "tips": [...] }
// JSONDecoder fills this struct, which in turn fills the three arrays.
struct EmergencyData: Codable {
    let categories: [EmergencyCategory]
    let guides: [EmergencyGuide]
    let tips: [SafetyTip]
}
