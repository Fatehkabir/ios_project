import SwiftUI

// A heart button that bounces when pressed.
//
// @Binding means this view does NOT own the true/false value. It borrows it from the
// parent (GuideDetailView), so when the button flips it, the parent's data changes too.
struct FavoriteButton: View {
    @Binding var isFavorite: Bool

    var body: some View {
        Button {
            isFavorite.toggle()
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.title3)
                .foregroundColor(isFavorite ? Theme.red : Theme.navy)
                // Animation: the heart grows when it becomes a favorite and springs back.
                .scaleEffect(isFavorite ? 1.25 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isFavorite)
        }
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
    }
}
