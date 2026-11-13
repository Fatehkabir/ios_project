import SwiftUI

// Card showing one safety tip.
struct TipCard: View {
    let tip: SafetyTip
    let categoryTitle: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(imageName: nil, symbolName: tip.iconName, color: color, size: 44)

            VStack(alignment: .leading, spacing: 6) {
                Text(categoryTitle.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundColor(color)
                Text(tip.text)
                    .font(.subheadline)
                    .foregroundColor(Theme.navy)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}
