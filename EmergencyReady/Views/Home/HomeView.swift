import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: FirebaseAuthService
    @EnvironmentObject var data: EmergencyDataService

    // Binding to MainTabView's selectedTab, so the "See all" button can switch tabs.
    @Binding var selectedTab: Int

    @State private var randomTip: SafetyTip? = nil
    @State private var showLogoutConfirmation = false

    // "kabir@mail.com" -> "kabir"
    private var displayName: String {
        if let name = auth.userEmail.split(separator: "@").first, !name.isEmpty {
            return String(name)
        }
        return "there"
    }

    // The "tip of the day": a different tip each calendar day, same all day.
    private var dailyTip: SafetyTip? {
        if data.tips.isEmpty { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return data.tips[day % data.tips.count]
    }

    // The tip on screen: the random one if the user pressed the button, else the daily one.
    private var shownTip: SafetyTip? {
        randomTip ?? dailyTip
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerView

                VStack(alignment: .leading, spacing: 22) {
                    searchBar
                    emergencyNotice

                    if data.isLoading {
                        LoadingView(text: "Loading safety information...")
                    } else if let message = data.errorMessage {
                        ErrorStateView(message: message) { data.loadData() }
                    } else {
                        tipSection
                        categorySection
                    }
                }
                .padding()
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("Log out of EmergencyReady?",
                            isPresented: $showLogoutConfirmation,
                            titleVisibility: .visible) {
            Button("Log Out", role: .destructive) { auth.logout() }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: - Pieces of the screen

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello,")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Text(displayName)
                    .font(.title.bold())
                    .foregroundColor(.white)
                Text("Be prepared. Stay safe.")
                    .font(.subheadline)
                    .foregroundColor(Theme.orange)
            }
            Spacer()

            Menu {
                Text(auth.userEmail)
                Button(role: .destructive) {
                    showLogoutConfirmation = true
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
            }
            .accessibilityLabel("Account menu")
        }
        .padding(.horizontal)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.navy.ignoresSafeArea(edges: .top))
    }

    // Looks like a search box but is a NavigationLink to the Search screen.
    private var searchBar: some View {
        NavigationLink {
            SearchView()
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("Search emergencies, guides, keywords")
                Spacer()
            }
            .font(.subheadline)
            .foregroundColor(Theme.textSecondary)
            .padding(14)
            .background(Theme.card)
            .cornerRadius(Theme.cornerRadius)
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var emergencyNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "phone.arrow.up.right.fill")
                .foregroundColor(Theme.orange)
            Text("In immediate danger, call your local emergency number first (for example 999 in Bangladesh, 911 in the USA, 112 in the EU).")
                .font(.footnote)
                .foregroundColor(Theme.navy)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.orange.opacity(0.12))
        .cornerRadius(Theme.cornerRadius)
    }

    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Safety Tip")
                    .font(.title3.bold())
                    .foregroundColor(Theme.navy)
                Spacer()
                // NavigationLink to the full tips screen.
                NavigationLink {
                    SafetyTipsView()
                } label: {
                    Text("View more tips")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.orange)
                }
            }

            if let tip = shownTip {
                TipCard(tip: tip,
                        categoryTitle: data.category(withId: tip.categoryId)?.title ?? "Safety",
                        color: data.color(forCategory: tip.categoryId))
                    .id(tip.id)   // a new id makes SwiftUI play the transition below
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity),
                                            removal: .opacity))
            }

            Button {
                showRandomTip()
            } label: {
                Label("Show a random tip", systemImage: "shuffle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.navy)
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Emergency Categories")
                    .font(.title3.bold())
                    .foregroundColor(Theme.navy)
                Spacer()
                Button {
                    selectedTab = 1   // writes through the Binding: switches to the Guides tab
                } label: {
                    Text("See all")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.orange)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    // ForEach loops over the categories array and builds one card per item.
                    ForEach(data.categories) { category in
                        NavigationLink {
                            GuideListView(category: category)
                        } label: {
                            CategoryCard(category: category)
                                .frame(width: 170)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func showRandomTip() {
        if data.tips.isEmpty { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            randomTip = data.tips.randomElement()
        }
    }
}
