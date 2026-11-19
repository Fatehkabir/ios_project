import SwiftUI
import UIKit

// Full instructions for one guide: illustration, numbered steps, do / avoid lists, source.
struct GuideDetailView: View {
    @EnvironmentObject var data: EmergencyDataService

    let guide: EmergencyGuide

    private var accentColor: Color {
        data.color(forCategory: guide.categoryId)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                illustration

                VStack(alignment: .leading, spacing: 6) {
                    Text(guide.title)
                        .font(.title2.bold())
                        .foregroundColor(Theme.navy)
                    Text(guide.description)
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }

                stepsSection

                bulletSection(title: "Things to Do",
                              icon: "checkmark.circle.fill",
                              color: Theme.green,
                              items: guide.thingsToDo)

                bulletSection(title: "Things to Avoid",
                              icon: "xmark.circle.fill",
                              color: Theme.red,
                              items: guide.thingsToAvoid)

                sourceSection
            }
            .padding()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Emergency Guide")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pieces

    private var illustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(accentColor.opacity(0.15))

            if !guide.imageName.isEmpty, UIImage(named: guide.imageName) != nil {
                Image(guide.imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: guide.iconName)
                    .font(.system(size: 64))
                    .foregroundColor(accentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityHidden(true)
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step-by-Step Instructions")
                .font(.title3.bold())
                .foregroundColor(Theme.navy)

            // Array + ForEach: one numbered row for each step string.
            ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Theme.navy)
                        .clipShape(Circle())

                    Text(step)
                        .font(.body)
                        .foregroundColor(Theme.navy)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func bulletSection(title: String, icon: String, color: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.bold())
                .foregroundColor(color)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(item)
                        .font(.subheadline)
                        .foregroundColor(Theme.navy)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .cornerRadius(Theme.cornerRadius)
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Official Source")
                .font(.subheadline.bold())
                .foregroundColor(Theme.navy)

            if let url = URL(string: guide.sourceURL) {
                Link(destination: url) {
                    Label(guide.sourceName, systemImage: "link")
                        .font(.subheadline)
                        .foregroundColor(Theme.orange)
                }
            } else {
                Text(guide.sourceName)
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }

            Text("This guide is general information for emergency response. Call your local emergency number (999) if life is in danger.")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
