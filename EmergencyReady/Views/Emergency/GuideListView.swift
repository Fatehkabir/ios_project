import SwiftUI

// All guides that belong to ONE category.
struct GuideListView: View {
    @EnvironmentObject var data: EmergencyDataService
    @EnvironmentObject var firestore: FirestoreService

    // Data passed in from the previous screen (the category the user tapped).
    let category: EmergencyCategory

    private var guides: [EmergencyGuide] {
        data.guides(inCategory: category.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(category.description)
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)

                if guides.isEmpty {
                    EmptyStateView(icon: "doc.text.magnifyingglass",
                                   title: "No guides yet",
                                   message: "There are no guides in this category.")
                } else {
                    ForEach(guides) { guide in
                        NavigationLink {
                            GuideDetailView(guide: guide)
                        } label: {
                            GuideCard(guide: guide,
                                      color: Color(hex: category.colorHex),
                                      isFavorite: firestore.isFavorite(guide.id))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
