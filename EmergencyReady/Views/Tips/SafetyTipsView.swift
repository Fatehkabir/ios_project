import SwiftUI

// All safety tips, grouped by category, with a random-tip button and a category filter.
struct SafetyTipsView: View {
    @EnvironmentObject var data: EmergencyDataService

    @State private var randomTip: SafetyTip? = nil
    // nil means "All categories".
    @State private var selectedCategoryId: String? = nil

    // Which categories to show, based on the selected filter chip.
    private var visibleCategories: [EmergencyCategory] {
        if let selectedId = selectedCategoryId {
            return data.categories.filter { $0.id == selectedId }
        }
        return data.categories
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                randomTipSection
                filterChips

                if data.tips.isEmpty {
                    EmptyStateView(icon: "lightbulb",
                                   title: "No tips available",
                                   message: "Safety tips could not be loaded.")
                } else {
                    // Loop 1: categories. Loop 2: the tips of each category.
                    ForEach(visibleCategories) { category in
                        let tips = data.tips(inCategory: category.id)
                        if !tips.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(category.title)
                                    .font(.title3.bold())
                                    .foregroundColor(Theme.navy)

                                ForEach(tips) { tip in
                                    TipCard(tip: tip,
                                            categoryTitle: category.title,
                                            color: Color(hex: category.colorHex))
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .animation(.easeInOut(duration: 0.25), value: selectedCategoryId)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Safety Tips")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var randomTipSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let tip = randomTip {
                TipCard(tip: tip,
                        categoryTitle: data.category(withId: tip.categoryId)?.title ?? "Safety",
                        color: data.color(forCategory: tip.categoryId))
                    .id(tip.id)
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity),
                                            removal: .opacity))
            }

            Button {
                if data.tips.isEmpty { return }
                withAnimation(.easeInOut(duration: 0.35)) {
                    randomTip = data.tips.randomElement()
                }
            } label: {
                Label("Random safety tip", systemImage: "shuffle")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", isSelected: selectedCategoryId == nil) {
                    selectedCategoryId = nil
                }
                ForEach(data.categories) { category in
                    chip(title: category.title, isSelected: selectedCategoryId == category.id) {
                        selectedCategoryId = category.id
                    }
                }
            }
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? .white : Theme.navy)
                .background(isSelected ? Theme.navy : Theme.card)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}
