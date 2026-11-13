import SwiftUI

// All guides the user marked with a heart. The ids come from Firestore,
// the guide content comes from the JSON file.
struct FavoritesView: View {
    @EnvironmentObject var data: EmergencyDataService
    @EnvironmentObject var firestore: FirestoreService

    // Keep only the guides whose id is in the favourites set.
    private var favoriteGuides: [EmergencyGuide] {
        data.guides.filter { firestore.favoriteIds.contains($0.id) }
    }

    var body: some View {
        Group {
            if firestore.isLoading && firestore.favoriteIds.isEmpty {
                LoadingView(text: "Loading favorites...")
            } else if favoriteGuides.isEmpty {
                ScrollView {
                    EmptyStateView(icon: "heart",
                                   title: "No favorites yet",
                                   message: "Open a guide and tap the heart to save it here for quick access.")
                }
            } else {
                List {
                    ForEach(favoriteGuides) { guide in
                        NavigationLink {
                            GuideDetailView(guide: guide)
                        } label: {
                            GuideCard(guide: guide,
                                      color: data.color(forCategory: guide.categoryId),
                                      showChevron: false)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        // Swipe left to remove from favorites.
                        .swipeActions {
                            Button(role: .destructive) {
                                firestore.setFavorite(guideId: guide.id, isFavorite: false)
                            } label: {
                                Label("Remove", systemImage: "heart.slash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .animation(.default, value: favoriteGuides.map { $0.id })
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Favorites")
    }
}
