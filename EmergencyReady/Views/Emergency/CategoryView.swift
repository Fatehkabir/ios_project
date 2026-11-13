import SwiftUI

// "Guides" tab: all emergency categories as cards.
struct CategoryView: View {
    @EnvironmentObject var data: EmergencyDataService

    // @State: used to start the "cards slide in" animation.
    @State private var hasAppeared = false

    // Two equal columns.
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            if data.isLoading {
                LoadingView(text: "Loading guides...")
            } else if let message = data.errorMessage {
                ErrorStateView(message: message) { data.loadData() }
            } else if data.categories.isEmpty {
                EmptyStateView(icon: "tray",
                               title: "No categories",
                               message: "No emergency categories were found.")
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    // enumerated() gives us the position (index) as well as the category.
                    ForEach(Array(data.categories.enumerated()), id: \.element.id) { index, category in
                        NavigationLink {
                            GuideListView(category: category)
                        } label: {
                            CategoryCard(category: category)
                        }
                        .buttonStyle(.plain)
                        // Animation: each card fades in and slides up a little later than the previous.
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 24)
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.07), value: hasAppeared)
                    }
                }
                .padding()
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Emergency Guides")
        .onAppear { hasAppeared = true }
    }
}
