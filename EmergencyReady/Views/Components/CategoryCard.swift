import SwiftUI

// Rounded card for one emergency category (icon, title, short description).
struct CategoryCard: View {
    let category: EmergencyCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            IconBadge(imageName: category.imageName,
                      symbolName: category.iconName,
                      color: Color(hex: category.colorHex),
                      size: 52)

            Text(category.title)
                .font(.headline)
                .foregroundColor(Theme.navy)
                .multilineTextAlignment(.leading)

            Text(category.description)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}
