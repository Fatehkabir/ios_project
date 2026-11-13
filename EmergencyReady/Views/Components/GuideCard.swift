import SwiftUI

// One row in a list of guides: icon, title, short description.
struct GuideCard: View {
    let guide: EmergencyGuide
    let color: Color
    var isFavorite: Bool = false
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(imageName: guide.imageName,
                      symbolName: guide.iconName,
                      color: color,
                      size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(guide.title)
                    .font(.headline)
                    .foregroundColor(Theme.navy)
                    .multilineTextAlignment(.leading)
                Text(guide.description)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            if isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundColor(Theme.red)
                    .accessibilityLabel("Favorite")
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
