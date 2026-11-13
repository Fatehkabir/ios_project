import SwiftUI

// Search categories, guide titles and keywords.
struct SearchView: View {
    @EnvironmentObject var data: EmergencyDataService

    // The text typed in the search box. Every keystroke changes it and the results update.
    @State private var query = ""
    @FocusState private var isSearchFocused: Bool

    private let suggestions = ["fire", "flood", "earthquake", "burn", "cpr", "bleeding", "electric", "crash"]

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        // Run the search once per redraw.
        let results = data.search(trimmedQuery)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                searchField

                if trimmedQuery.isEmpty {
                    suggestionsSection
                } else if results.categories.isEmpty && results.guides.isEmpty {
                    EmptyStateView(icon: "magnifyingglass",
                                   title: "No results found",
                                   message: "Nothing matched \"\(trimmedQuery)\". Try another word such as fire, flood or burn.")
                } else {
                    if !results.categories.isEmpty {
                        Text("Categories")
                            .font(.title3.bold())
                            .foregroundColor(Theme.navy)

                        ForEach(results.categories) { category in
                            NavigationLink {
                                GuideListView(category: category)
                            } label: {
                                CategoryCard(category: category)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !results.guides.isEmpty {
                        Text("Guides")
                            .font(.title3.bold())
                            .foregroundColor(Theme.navy)

                        ForEach(results.guides) { guide in
                            NavigationLink {
                                GuideDetailView(guide: guide)
                            } label: {
                                GuideCard(guide: guide,
                                          color: data.color(forCategory: guide.categoryId))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
            .animation(.easeInOut(duration: 0.2), value: trimmedQuery)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { isSearchFocused = true }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.textSecondary)

            TextField("Search fire, flood, burns, CPR...", text: $query)
                .focused($isSearchFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.textSecondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(12)
        .background(Theme.card)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Try searching for")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)

            // Tap a suggestion to fill the search box.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(suggestions, id: \.self) { word in
                    Button {
                        query = word
                    } label: {
                        Text(word)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundColor(Theme.navy)
                            .background(Theme.card)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}
