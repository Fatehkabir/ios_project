import Foundation

// Small helper functions for checking what the user typed.
enum Validation {

    // Very common "name@domain.ext" check.
    static func isValidEmail(_ text: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: text)
    }

    // Allows digits, spaces, dashes, brackets and a "+" sign, with 3-15 digits in total.
    static func isValidPhone(_ text: String) -> Bool {
        let allowed = CharacterSet(charactersIn: "+0123456789 -()")
        if text.rangeOfCharacter(from: allowed.inverted) != nil { return false }
        let digitCount = text.filter { $0.isASCII && $0.isNumber }.count
        return digitCount >= 3 && digitCount <= 15
    }

    // "+880 1711-000000" -> "+8801711000000" (what the phone URL needs).
    static func cleanedPhone(_ text: String) -> String {
        text.filter { ($0.isASCII && $0.isNumber) || $0 == "+" }
    }
}
