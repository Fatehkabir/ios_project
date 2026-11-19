import SwiftUI

struct RegionalAlertBanner: View {
    let alert: DisasterAlert
    let onNavigateToGuides: (String) -> Void

    var severityColor: Color {
        switch alert.severity.lowercased() {
        case "extreme": return Color(hex: "#7F1D1D") ?? Theme.red
        case "severe": return Theme.red
        case "moderate": return Theme.orange
        default: return Color(hex: "#D97706") ?? Theme.orange
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(severityColor)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(alert.region.uppercased())
                            .font(.caption2.bold())
                            .foregroundColor(severityColor)
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                        Text(alert.severity.uppercased())
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(severityColor.opacity(0.15))
                            .cornerRadius(4)
                            .foregroundColor(severityColor)
                        Spacer()
                    }

                    Text(alert.title)
                        .font(.headline)
                        .foregroundColor(Theme.navy)
                }
            }

            if !alert.description.isEmpty {
                Text(alert.description)
                    .font(.footnote)
                    .foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Text("Valid until: \(alert.expiresAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)

                Spacer()

                Button {
                    onNavigateToGuides(alert.categoryId)
                } label: {
                    HStack(spacing: 4) {
                        Text("View Safety Guide")
                        Image(systemName: "arrow.right")
                    }
                    .font(.caption.bold())
                    .foregroundColor(severityColor)
                }
            }
        }
        .padding(14)
        .background(severityColor.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(severityColor.opacity(0.3), lineWidth: 1.5)
        )
    }
}
